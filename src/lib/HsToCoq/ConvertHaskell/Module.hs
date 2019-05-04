{-# LANGUAGE TupleSections, LambdaCase, RecordWildCards, TypeApplications, FlexibleContexts, DeriveDataTypeable, OverloadedLists, OverloadedStrings, ScopedTypeVariables, MultiWayIf, RankNTypes  #-}

module HsToCoq.ConvertHaskell.Module (
  -- * Convert whole module graphs and modules
  ConvertedModule(..),
  convertModules,
  -- ** Extract all the declarations from a module
  ModuleDeclarations(..), moduleDeclarations,
  -- * Convert declaration groups
  ConvertedModuleDeclarations(..), convertHsGroup,
) where

import Control.Lens

import Data.Foldable
import Data.Maybe
import Data.List.NonEmpty (NonEmpty(..))
import HsToCoq.Util.Containers

import Data.Generics

import Control.Exception (SomeException)
import qualified Data.Set as S
import qualified Data.Map as M

import qualified Data.Text as T

import HsToCoq.Util.FVs
import HsToCoq.Coq.FreeVars
import HsToCoq.Coq.Gallina
import HsToCoq.Coq.Gallina.Util

import GHC hiding (Name)
import HsToCoq.Util.GHC.Module
import Bag

import Data.Data (Data(..))

import HsToCoq.ConvertHaskell.Parameters.Edits
import HsToCoq.ConvertHaskell.Monad
import HsToCoq.ConvertHaskell.InfixNames
import HsToCoq.ConvertHaskell.Variables
import HsToCoq.ConvertHaskell.Definitions
import HsToCoq.ConvertHaskell.Expr
import HsToCoq.ConvertHaskell.Sigs
import HsToCoq.ConvertHaskell.Declarations.TyCl
import HsToCoq.ConvertHaskell.Declarations.Instances
import HsToCoq.ConvertHaskell.Declarations.Notations
import HsToCoq.ConvertHaskell.Axiomatize
import HsToCoq.Coq.Preamble

--------------------------------------------------------------------------------

data ConvertedModuleDeclarations =
  ConvertedModuleDeclarations { convertedTyClDecls    :: ![Sentence]
                              , convertedValDecls     :: ![Sentence]
                              , convertedClsInstDecls :: ![Sentence]
                              , convertedAddedDecls   :: ![Sentence]
                              }
  deriving (Eq, Ord, Show, Data)

convertHsGroup :: ConversionMonad r m => HsGroup GhcRn -> m ConvertedModuleDeclarations
convertHsGroup HsGroup{..} = do
  mod                 <- view currentModule
  isModuleAxiomatized <- view $ edits.axiomatizedModules.contains mod
  let catchIfAxiomatizing | isModuleAxiomatized = const
                          | otherwise           = undefined --gcatch
  handler             <- undefined -- whenPermissive axiomatizeBinding
  
  convertedTyClDecls <- convertModuleTyClDecls
                     .  map unLoc
                     $  concatMap group_tyclds hs_tyclds
                         -- Ignore roles
  convertedValDecls  <- -- TODO RENAMER merge with convertLocalBinds / convertModuleValDecls
    case hs_valds of
      ValBinds{} ->
        convUnsupported' "pre-renaming `ValBindsIn' construct post renaming"
        {-
      ValBindsOut binds lsigs -> do
        sigs  <- convertLSigs lsigs `catchIfAxiomatizing` const @_ @SomeException (pure M.empty)
        defns <- (convertTypedModuleBindings
                   (map unLoc $ concatMap (bagToList . snd) binds)
                   sigs
                   ??
                   handler)
              $  withConvertedBinding
                   (\cdef@ConvertedDefinition{_convDefName = name} -> ((Just name,) <$>) $ withCurrentDefinition name $ do
                       t  <- view (edits.termination.at name)
                       obl <- view (edits.obligations.at name)
                       useProgram <- useProgramHere
                       if | Just (WellFounded order) <- t  -- turn into Program Fixpoint
                          ->  pure <$> toProgramFixpointSentence cdef order obl
                          | otherwise                   -- no edit
                          -> let def = DefinitionDef Global (cdef^.convDefName)
                                                            (cdef^.convDefArgs)
                                                            (cdef^.convDefType)
                                                            (cdef^.convDefBody)
                             in pure $
                                [ if useProgram
                                  then ProgramSentence (DefinitionSentence def) obl
                                  else DefinitionSentence def ] ++
                                [ NotationSentence n | n <- buildInfixNotations sigs (cdef^.convDefName) ]
                   )
                   (\_ _ -> convUnsupported' "top-level pattern bindings")
                   (\ax   ty  -> pure (Just ax, [typedAxiom ax ty]))
                   (\name def -> (Just name, [definitionSentence def]) <$ case def of
                      CoqInductiveDef        _   -> editFailure   "cannot redefine a value definition into an Inductive"
                      CoqDefinitionDef       _   -> pure ()
                      CoqFixpointDef         _   -> pure ()
                      CoqInstanceDef         _   -> editFailure   "cannot redefine a value definition into an Instance"
                      CoqAxiomDef            _   -> pure ()
                      CoqAssertionDef        apf -> editFailure $ "cannot redefine a value definition into " ++ anAssertionVariety apf)
        let unnamedSentences = concat [ sentences | (Nothing, sentences) <- defns ]
        let namedSentences   = [ (name, sentences) | (Just name, sentences) <- defns ]

        let defnsMap = M.fromList namedSentences
        let ordered = foldMap (foldMap (defnsMap M.!)) . topoSortEnvironment $ fmap NoBinding <$> defnsMap

        pure $ unnamedSentences ++ ordered
                      -}

  convertedClsInstDecls <- convertClsInstDecls [cid | grp <- hs_tyclds, L _ (ClsInstD _ cid) <- group_instds grp]

  convertedAddedDecls <- view (edits.additions.at mod.non [])

  pure ConvertedModuleDeclarations{..}
  where
    -- TODO: factor this out?
    axiomatizeBinding :: ConversionMonad r m => HsBind GhcRn -> GhcException -> m (Maybe Qualid, [Sentence])
    axiomatizeBinding FunBind{..} exn = do
      name <- var ExprNS (unLoc fun_id)
      pure (Just name, [translationFailedComment (qualidBase name) exn, axiom name])
    axiomatizeBinding _ exn =
      pure (Nothing, [CommentSentence $ Comment $
        "While translating non-function binding: " <> T.pack (show exn)])

--------------------------------------------------------------------------------

data ConvertedModule =
  ConvertedModule { convModName         :: !ModuleName
                  , convModImports      :: ![Sentence]
                  , convModTyClDecls    :: ![Sentence]
                  , convModValDecls     :: ![Sentence]
                  , convModClsInstDecls :: ![Sentence]
                  , convModAddedDecls   :: ![Sentence]
                  }
  deriving (Eq, Ord, Show, Data)

convertModule :: GlobalMonad r m => ModuleName -> HsGroup GhcRn -> m (ConvertedModule, [ModuleName])
convertModule convModNameOrig group = do
  convModName <- view $ edits.renamedModules.at convModNameOrig . non convModNameOrig
  withCurrentModule convModName $ do
    ConvertedModuleDeclarations { convertedTyClDecls    = convModTyClDecls
                                , convertedValDecls     = convModValDecls
                                , convertedClsInstDecls = convModClsInstDecls
                                , convertedAddedDecls   = convModAddedDecls
                                }
      <- convertHsGroup group

    let allSentences = convModTyClDecls ++ convModValDecls ++ convModClsInstDecls ++ convModAddedDecls
    let freeVars = toList $ foldMap getFreeVars' allSentences
    let modules = filter (/= convModName)
                     . map (mkModuleName . T.unpack)
                     . mapMaybe qualidModule $ freeVars
    let needsNotation qualid
            = qualidIsOp qualid || qualid == "GHC.Num.fromInteger"

    let notationModules
                     = filter (/= convModName)
                     . map (mkModuleName . T.unpack)
                     . mapMaybe qualidModule
                     . filter needsNotation $ freeVars

    modules         <- skipModules $ S.toList $ S.fromList modules
    notationModules <- skipModules $ S.toList $ S.fromList notationModules
    imported_modules <- view $ edits.importedModules

    let convModImports =
            [ ModuleSentence (Require Nothing imp [moduleNameText mn])
            | mn <- modules
            , let imp | mn `S.member` imported_modules = Just Import
                      | otherwise                      = Nothing
            ] ++
            [ ModuleSentence (ModuleImport Import [moduleNameText mn <> ".Notations"])
            | mn <- notationModules
            , mn `S.notMember` imported_modules
            ]
    pure (ConvertedModule{..}, modules)

-- NOT THE SAME as `traverse $ uncurry convertModule`!  Handles module
-- renaming/merging and produces connected components.
convertModules :: GlobalMonad r m => [(ModuleName, HsGroup GhcRn)] -> m [NonEmpty ConvertedModule]
convertModules sources = do
  sources' <- sources & each._1 %%~ \mod_orig ->
                view (edits.renamedModules.at mod_orig.non mod_orig)
  let merged = M.toList $ M.fromListWith appendGroups sources'

  mods <- traverse (uncurry convertModule) merged
  pure $ stronglyConnCompNE [(cmod, convModName cmod, imps) | (cmod, imps) <- mods]

data ModuleDeclarations = ModuleDeclarations { moduleTypeDeclarations  :: ![Sentence]
                                             , moduleValueDeclarations :: ![Sentence] }
                        deriving (Eq, Ord, Show, Read, Data)

moduleDeclarations :: GlobalMonad r m => ConvertedModule -> m ModuleDeclarations
moduleDeclarations ConvertedModule{..} = do
  let thisModule = moduleNameText convModName
      localInfixNames qid | maybe True (== thisModule) $ qualidModule qid
                          , Just op <- identToOp $ qualidBase qid
                            = S.fromList $ Bare <$> [op, infixToPrefix op]
                          | otherwise
                            = S.empty
      addLocalInfixNamesExcept del (BVs bvs fvs) =
        BVs bvs $ fvs <> (foldMap localInfixNames fvs S.\\ del)
      
      unused = S.singleton . Bare
      
      unusedNotations (NotationSentence (NotationBinding (NotationIdentBinding op _))) =
        unused op <> foldMap unused (prefixOpToInfix op)
      unusedNotations (NotationSentence (InfixDefinition op _ _ _)) =
        unused op
      unusedNotations _ =
        mempty

      bvWithInfix = addLocalInfixNamesExcept <$> unusedNotations <*> bvOf
  -- Make sure that @f = … op_zpzp__ …@ depends on @++@ and @_++_@ as well
  -- as @op_zpzp__@.  But don't produce cycles by depending on yourself.
  -- This feels like a hack, and like we could use the 'RawQualid'
  -- constructor, but we don't have the right module information in 'bvOf'
  -- to do this properly.
      
  orders <- view $ edits.orders
  let sorted = topoSortByVariablesBy bvWithInfix orders $
        convModValDecls ++ convModClsInstDecls ++ convModAddedDecls
  let ax_decls = usedAxioms sorted
  not_decls <- qualifiedNotations convModName (convModTyClDecls ++ sorted)
  imported_modules <- view $ edits.importedModules
  pure . deQualifyLocalNames (convModName `S.insert` imported_modules)
       $ ModuleDeclarations { moduleTypeDeclarations  = convModTyClDecls ++ ax_decls
                            , moduleValueDeclarations = sorted           ++ not_decls }

-- | This un-qualifies all variable names in the current module.
-- It should be called very late, just before pretty-printing.
deQualifyLocalNames :: Data a => S.Set ModuleName -> a -> a
deQualifyLocalNames modNames = everywhere (mkT localize)
  where
    modNameTexts = S.map moduleNameText modNames

    localize :: Qualid -> Qualid
    localize (Qualified m b) | m `S.member` modNameTexts = Bare b
    localize qid = qid

usedAxioms :: [Sentence] -> [Sentence]
usedAxioms decls = comment ++ ax_decls
  where
    ax_decls =
      [ AssumptionSentence (Assumption Axiom (Assums [i] t))
      | i <- toList (foldMap getFreeVars' decls)
      , Just t <- return $ M.lookup i builtInAxioms
      ]

    comment =
      [ CommentSentence (Comment "The Haskell code containes partial or \
         \untranslateable code, which needs the following")
      | not (null ax_decls)
      ]

qualifiedNotations :: GlobalMonad r m => ModuleName -> [Sentence] -> m [Sentence]
qualifiedNotations mod decls = do
    hmn <- view (edits . hasManualNotation . contains mod)
    return $ wrap $
        extra hmn ++
        [ NotationSentence qn
        | NotationSentence n <- decls, Just qn <- pure $ qualifyNotation mod n ]
  where
    wrap :: [Sentence] -> [Sentence]
    wrap []        = []
    wrap sentences = [ LocalModuleSentence (LocalModule "Notations" sentences) ]

    extra :: Bool -> [Sentence]
    extra True  = [ ModuleSentence (ModuleImport Export ["ManualNotations"]) ]
    extra False = []
