{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE OverloadedLists #-}
{-# LANGUAGE OverloadedStrings #-}

module HsToCoq.ConvertHaskell.BuiltIn where

import HsToCoq.Coq.Gallina
import HsToCoq.Coq.Gallina.Util
import HsToCoq.Coq.Gallina.Orphans ()
import qualified HsToCoq.Coq.Gallina as Coq

import Data.List.NonEmpty (NonEmpty(..))
import Data.Map (Map)
import qualified Data.Map as M

-- HACK: Hard-code information about some data types here
-- This needs to be solved proper, but for now this makes the test suite
-- more useful
builtInDataCons :: [(Qualid,[(Qualid,Int)])]
builtInDataCons =
    [ "option" =: [ "Some"  =: 1, "None"  =: 0 ]
    , "pair"   =: [ "pair"  =: 2]
    , "list"   =: [ "nil"   =: 1, "cons"  =: 2 ]
    , "bool"   =: [ "true"  =: 0, "false" =: 0 ]
    , "ordering" =: [ "Lt"  =: 1, "Eq" =: 1, "Gt" =: 1 ]
    ]
  where (=:) = (,)

builtInClasses :: [ClassDefinition]
builtInClasses =
    [ ClassDefinition "GHC.Base.Eq_" ["a"] Nothing
        [ "GHC.Base.op_zeze__" =: "a" `Arrow` "a" `Arrow` "bool"
        , "GHC.Base.op_zsze__" =: "a" `Arrow` "a" `Arrow` "bool"
        ]
    , ClassDefinition "GHC.Base.Ord" ["a"] Nothing
        [ "GHC.Base.op_zl__"   =: "a" `Arrow` "a" `Arrow` "bool"
        , "GHC.Base.op_zlze__" =: "a" `Arrow` "a" `Arrow` "bool"
        , "GHC.Base.op_zg__"   =: "a" `Arrow` "a" `Arrow` "bool"
        , "GHC.Base.op_zgze__" =: "a" `Arrow` "a" `Arrow` "bool"
        , "GHC.Base.compare"   =: "a" `Arrow` "a" `Arrow` "comparison"
        , "GHC.Base.max"       =: "a" `Arrow` "a" `Arrow` "a"
        , "GHC.Base.min"       =: "a" `Arrow` "a" `Arrow` "a"
        ]
    , ClassDefinition "GHC.Base.Monoid" ["a"] Nothing
        [ "GHC.Base.mappend" =: "a" `Arrow` "a" `Arrow` "a"
        , "GHC.Base.mconcat" =: ("list" `App1` "a") `Arrow` "a"
        , "GHC.Base.mempty"  =: "a"
        ]
    , ClassDefinition "GHC.Base.Semigroup" ["a"] Nothing
        [ "GHC.Base.<<>>" =: "a" `Arrow` "a" `Arrow` "a"
--        , "Data.Semigroup.sconcat__"   =: ("Data.List.NonEmpty.NonEmpty" `App1` "a") `Arrow` "a"
        ]
    , ClassDefinition "GHC.Base.Functor" ["f"] Nothing
        [ "GHC.Base.op_zlzd__" =: (Forall [ Inferred Implicit (Ident "a")
                            , Inferred Implicit (Ident "b")] $
                     "a" `Arrow`
                     App1 "f" "b" `Arrow`
                     App1 "f" "a")
        , "GHC.Base.fmap" =: (Forall [ Inferred Implicit (Ident "a")
                            , Inferred Implicit (Ident "b")] $
                     ("a" `Arrow` "b") `Arrow`
                     App1 "f" "a" `Arrow`
                     App1 "f" "b")
        ]
    , ClassDefinition "GHC.Base.Applicative"
        [ "f"
        , Generalized Implicit (App1 "GHC.Base.Functor" "f")
        ]
        Nothing
        [ "GHC.Base.op_ztzg__" =:
            (Forall [ Inferred Implicit (Ident "a")
                    , Inferred Implicit (Ident "b")] $
                     App1 "f" "a" `Arrow`
                     App1 "f" "b" `Arrow`
                     App1 "f" "b")
        , "GHC.Base.op_zlztzg__" =:
            (Forall [ Inferred Implicit (Ident "a")
                    , Inferred Implicit (Ident "b")] $
                     App1 "f" ("a" `Arrow` "b") `Arrow`
                     App1 "f" "a" `Arrow`
                     App1 "f" "b")
        , "GHC.Base.liftA2" =:
            (Forall [ Inferred Implicit (Ident "a")
                    , Inferred Implicit (Ident "b")
                    , Inferred Implicit (Ident "c")] $
                     ("a" `Arrow` "b" `Arrow` "c") `Arrow`
                     App1 "f" "a" `Arrow`
                     App1 "f" "b" `Arrow`
                     App1 "f" "c")
        , "GHC.Base.pure"  =: (Forall [Inferred Implicit (Ident "a")]  $
                      "a" `Arrow` App1 "f" "a")
        {- skipped
        , "op_zlzt__" =:
            (Forall [ Inferred Implicit (Ident "a")
                    , Inferred Implicit (Ident "b")] $
                     App1 "f" "a" `Arrow`
                     App1 "f" "b" `Arrow`
                     App1 "f" "a")
        -}
        ]
    , ClassDefinition "GHC.Base.Monad"
        [ "f"
        , Generalized Implicit (App1 "GHC.Base.Applicative" "f")
        ]
        Nothing
        [ "GHC.Base.op_zgzg__" =:
           (Forall [ Inferred Implicit (Ident "a")
                   , Inferred Implicit (Ident "b")] $
                    App1 "f" "a" `Arrow`
                    App1 "f" "b" `Arrow`
                    App1 "f" "b")
        , "GHC.Base.op_zgzgze__" =:
            (Forall [ Inferred Implicit (Ident "a")
                    , Inferred Implicit (Ident "b")] $
                     App1 "f" "a" `Arrow`
                     ("a" `Arrow` App1 "f" "b") `Arrow`
                     App1 "f" "b")
        , "GHC.Base.return_"  =: (Forall [Inferred Implicit (Ident "a")]  $
                      "a" `Arrow` App1 "f" "a")
        {-
        , "fail" =:
           (Forall [ Inferred Implicit (Ident "a")] $
                    "GHC.Prim.String" `Arrow`
                    App1 "f" "a")
        -}
        ]
    {-
    -- This is essentially a class for co-inductive types. 
    , ClassDefinition "GHC.Base.Alternative" 
        [ "f"
        , Generalized Implicit (App1 "GHC.Base.Applicative" "f")
        ]
        Nothing
        [ "GHC.Base.empty" =:
          (Forall [ Inferred Implicit (Ident "a") ] $
           App1 "f" "a")
        , "GHC.Base.op_zgzbzl__" =:
          (Forall [ Inferred Implicit (Ident "a") ] $
           App1 "f" "a" `Arrow` App1 "f" "a" `Arrow` App1 "f" "a")
        ]
    -}
    , ClassDefinition "Data.Foldable.Foldable" ["t"] Nothing
      [("Data.Foldable.elem",Forall (Inferred Implicit (Ident "a") :| []) (Forall (Generalized Implicit (App "GHC.Base.Eq_" (PosArg "a" :| [])) :| []) (Arrow "a" (Arrow (App "t" (PosArg "a" :| [])) "bool")))),
        ("Data.Foldable.fold",Forall (Inferred Implicit (Ident "m") :| []) (Forall (Generalized Implicit (App "GHC.Base.Monoid" (PosArg "m" :| [])) :| []) (Arrow (App "t" (PosArg "m" :| [])) "m"))),
        ("Data.Foldable.foldMap",Forall (Inferred Implicit (Ident "m") :| [Inferred Implicit (Ident "a")]) (Forall (Generalized Implicit (App "GHC.Base.Monoid" (PosArg "m" :| [])) :| []) (Arrow (Parens (Arrow "a" "m")) (Arrow (App "t" (PosArg "a" :| [])) "m")))),
        ("Data.Foldable.foldl",Forall (Inferred Implicit (Ident "b") :| [Inferred Implicit (Ident "a")]) (Arrow (Parens (Arrow "b" (Arrow "a" "b"))) (Arrow "b" (Arrow (App "t" (PosArg "a" :| [])) "b")))),
        ("Data.Foldable.foldl'",Forall (Inferred Implicit (Ident "b") :| [Inferred Implicit (Ident "a")]) (Arrow (Parens (Arrow "b" (Arrow "a" "b"))) (Arrow "b" (Arrow (App "t" (PosArg "a" :| [])) "b")))),
        ("Data.Foldable.foldr",Forall (Inferred Implicit (Ident "a") :| [Inferred Implicit (Ident "b")]) (Arrow (Parens (Arrow "a" (Arrow "b" "b"))) (Arrow "b" (Arrow (App "t" (PosArg "a" :| [])) "b")))),
        ("Data.Foldable.foldr'",Forall (Inferred Implicit (Ident "a") :| [Inferred Implicit (Ident "b")]) (Arrow (Parens (Arrow "a" (Arrow "b" "b"))) (Arrow "b" (Arrow (App "t" (PosArg "a" :| [])) "b")))),
        ("Data.Foldable.length",Forall (Inferred Implicit (Ident "a") :| []) (Arrow (App "t" (PosArg "a" :| [])) "GHC.Num.Int")),
        ("Data.Foldable.null",Forall (Inferred Implicit (Ident "a") :| []) (Arrow (App "t" (PosArg "a" :| [])) "bool")),
        ("Data.Foldable.product",Forall (Inferred Implicit (Ident "a") :| []) (Forall (Generalized Implicit (App "GHC.Num.Num" (PosArg "a" :| [])) :| []) (Arrow (App "t" (PosArg "a" :| [])) "a"))),
        ("Data.Foldable.sum",Forall (Inferred Implicit (Ident "a") :| []) (Forall (Generalized Implicit (App "GHC.Num.Num" (PosArg "a" :| [])) :| []) (Arrow (App "t" (PosArg "a" :| [])) "a"))),
        ("Data.Foldable.toList",Forall (Inferred Implicit (Ident "a") :| []) (Arrow (App "t" (PosArg "a" :| [])) (App "list" (PosArg "a" :| []))))]



    , ClassDefinition "Data.Traversable.Traversable"
      ["t",
       Generalized Implicit (App "GHC.Base.Functor"
                              (PosArg "t" :| [])),
       Generalized Implicit (App "Data.Foldable.Foldable"
                              (PosArg "t" :| []))
      ]
      Nothing
      [("Data.Traversable.mapM",
         Forall (Inferred Implicit (Ident "m") :| [Inferred Implicit (Ident "a"),Inferred Implicit (Ident "b")]) (Forall (Generalized Implicit (App "GHC.Base.Monad" (PosArg "m" :| [])) :| []) (Arrow (Parens (Arrow "a" (App "m" (PosArg "b" :| [])))) (Arrow (App "t" (PosArg "a" :| [])) (App "m" (PosArg (Parens (App "t" (PosArg "b" :| []))) :| [])))))),
        ("Data.Traversable.sequence",Forall (Inferred Implicit (Ident "m") :| [Inferred Implicit (Ident "a")]) (Forall (Generalized Implicit (App "GHC.Base.Monad" (PosArg "m" :| [])) :| []) (Arrow (App "t" (PosArg (Parens (App "m" (PosArg "a" :| []))) :| [])) (App "m" (PosArg (Parens (App "t" (PosArg "a" :| []))) :| []))))),
        ("Data.Traversable.sequenceA",Forall (Inferred Implicit (Ident "f") :| [Inferred Implicit (Ident "a")]) (Forall (Generalized Implicit (App "GHC.Base.Applicative" (PosArg "f" :| [])) :| []) (Arrow (App "t" (PosArg (Parens (App "f" (PosArg "a" :| []))) :| [])) (App "f" (PosArg (Parens (App "t" (PosArg "a" :| []))) :| []))))),
        ("Data.Traversable.traverse",Forall (Inferred Implicit (Ident "f") :| [Inferred Implicit (Ident "a"),Inferred Implicit (Ident "b")]) (Forall (Generalized Implicit (App "GHC.Base.Applicative" (PosArg "f" :| [])) :| []) (Arrow (Parens (Arrow "a" (App "f" (PosArg "b" :| [])))) (Arrow (App "t" (PosArg "a" :| [])) (App "f" (PosArg (Parens (App "t" (PosArg "b" :| []))) :| []))))))]

    , ClassDefinition "Control.Arrow.Arrow"
       [Typed Ungeneralizable Explicit (Ident "a" :| []) (Arrow "Type" (Arrow "Type" "Type")),Generalized Implicit (App "Control.Category.Category" (PosArg "a" :| []))]
       Nothing
       [("Control.Arrow.op_zazaza__",Forall (Inferred Implicit (Ident "b") :| [Inferred Implicit (Ident "c"),Inferred Implicit (Ident "c'")]) (Arrow (App (App "a" (PosArg "b" :| [])) (PosArg "c" :| [])) (Arrow (App (App "a" (PosArg "b" :| [])) (PosArg "c'" :| [])) (App (App "a" (PosArg "b" :| [])) (PosArg (mkInfix "c" "*" "c'") :| [])))))
       ,("Control.Arrow.op_ztztzt__",Forall (Inferred Implicit (Ident "b") :| [Inferred Implicit (Ident "c"),Inferred Implicit (Ident "b'"),Inferred Implicit (Ident "c'")]) (Arrow (App (App "a" (PosArg "b" :| [])) (PosArg "c" :| [])) (Arrow (App (App "a" (PosArg "b'" :| [])) (PosArg "c'" :| [])) (App (App "a" (PosArg (mkInfix "b" "*" "b'") :| [])) (PosArg (mkInfix "c" "*" "c'") :| [])))))
       ,("Conrol.Arrow.arr",Forall (Inferred Implicit (Ident "b") :| [Inferred Implicit (Ident "c")]) (Arrow (Parens (Arrow "b" "c")) (App (App "a" (PosArg "b" :| [])) (PosArg "c" :| []))))
       ,("Control.Arrow.first",Forall (Inferred Implicit (Ident "b") :| [Inferred Implicit (Ident "c"),Inferred Implicit (Ident "d")]) (Arrow (App (App "a" (PosArg "b" :| [])) (PosArg "c" :| [])) (App (App "a" (PosArg (mkInfix "b" "*" "d") :| [])) (PosArg (mkInfix "c" "*" "d") :| []))))
       ,("Control.Arrowsecond",Forall (Inferred Implicit (Ident "b") :| [Inferred Implicit (Ident "c"),Inferred Implicit (Ident "d")]) (Arrow (App (App "a" (PosArg "b" :| [])) (PosArg "c" :| [])) (App (App "a" (PosArg (mkInfix "d" "*" "b") :| [])) (PosArg (mkInfix "d" "*" "c") :| []))))]

    , ClassDefinition "Control.Arrow.ArrowZero"
      [Typed Ungeneralizable Explicit (Ident "a" :| []) (Arrow "Type" (Arrow "Type" "Type")),Generalized Implicit (App "Arrow" (PosArg "a" :| []))]
      Nothing
      [("Control.Arrow.zeroArrow",Forall (Inferred Implicit (Ident "b") :| [Inferred Implicit (Ident "c")]) (App (App "a" (PosArg "b" :| [])) (PosArg "c" :| [])))]

    , ClassDefinition "Control.Arrow.ArrowPlus"
     [Typed Ungeneralizable Explicit (Ident "a" :| []) (Arrow "Type" (Arrow "Type" "Type")),Generalized Implicit (App "ArrowZero" (PosArg "a" :| []))]
     Nothing
     [("Control.Arrow.op_zlzpzg__",Forall (Inferred Implicit (Ident "b") :| [Inferred Implicit (Ident "c")]) (Arrow (App (App "a" (PosArg "b" :| [])) (PosArg "c" :| [])) (Arrow (App (App "a" (PosArg "b" :| [])) (PosArg "c" :| [])) (App (App "a" (PosArg "b" :| [])) (PosArg "c" :| [])))))]

    ,ClassDefinition "Control.Arrow.ArrowChoice"
     ["a",Generalized Implicit (App "Arrow" (PosArg "a" :| []))]
     Nothing
     [("Control.Arrow.op_zpzpzp__",Forall (Inferred Implicit (Ident "b") :| [Inferred Implicit (Ident "c"),Inferred Implicit (Ident "b'"),Inferred Implicit (Ident "c'")]) (Arrow (App (App "a" (PosArg "b" :| [])) (PosArg "c" :| [])) (Arrow (App (App "a" (PosArg "b'" :| [])) (PosArg "c'" :| [])) (App (App "a" (PosArg (Parens (App (App "sum" (PosArg "b" :| [])) (PosArg "b'" :| []))) :| [])) (PosArg (Parens (App (App "sum" (PosArg "c" :| [])) (PosArg "c'" :| []))) :| [])))))
     ,("Control.Arrow.left",Forall (Inferred Implicit (Ident "b") :| [Inferred Implicit (Ident "c"),Inferred Implicit (Ident "d")]) (Arrow (App (App "a" (PosArg "b" :| [])) (PosArg "c" :| [])) (App (App "a" (PosArg (Parens (App (App "sum" (PosArg "b" :| [])) (PosArg "d" :| []))) :| [])) (PosArg (Parens (App (App "sum" (PosArg "c" :| [])) (PosArg "d" :| []))) :| []))))
     ,("Control.Arrow.right",Forall (Inferred Implicit (Ident "b") :| [Inferred Implicit (Ident "c"),Inferred Implicit (Ident "d")]) (Arrow (App (App "a" (PosArg "b" :| [])) (PosArg "c" :| [])) (App (App "a" (PosArg (Parens (App (App "sum" (PosArg "d" :| [])) (PosArg "b" :| []))) :| [])) (PosArg (Parens (App (App "sum" (PosArg "d" :| [])) (PosArg "c" :| []))) :| []))))
     ,("Control.Arrow.op_zbzbzb__",Forall (Inferred Implicit (Ident "b") :| [Inferred Implicit (Ident "d"),Inferred Implicit (Ident "c")]) (Arrow (App (App "a" (PosArg "b" :| [])) (PosArg "d" :| [])) (Arrow (App (App "a" (PosArg "c" :| [])) (PosArg "d" :| [])) (App (App "a" (PosArg (Parens (App (App "sum" (PosArg "b" :| [])) (PosArg "c" :| []))) :| [])) (PosArg "d" :| [])))))]

    , ClassDefinition "Control.Arrow.ArrowApply" [Typed Ungeneralizable Explicit (Ident "a" :| []) (Arrow "Type" (Arrow "Type" "Type")),Generalized Implicit (App "Arrow" (PosArg "a" :| []))] Nothing [("app",Forall (Inferred Implicit (Ident "b") :| [Inferred Implicit (Ident "c")]) (App (App "a" (PosArg (mkInfix (App (App "a" (PosArg "b" :| [])) (PosArg "c" :| [])) "*" "b") :| [])) (PosArg "c" :| [])))]

    , ClassDefinition "Control.Arrow.ArrowLoop"
      ["a",Generalized Implicit (App "Arrow" (PosArg "a" :| []))]
      Nothing
      [("Control.Arrow.loop",Forall (Inferred Implicit (Ident "b") :| [Inferred Implicit (Ident "d"),Inferred Implicit (Ident "c")]) (Arrow (App (App "a" (PosArg (mkInfix "b" "*" "d") :| [])) (PosArg (mkInfix "c" "*" "d") :| [])) (App (App "a" (PosArg "b" :| [])) (PosArg "c" :| []))))]

    , ClassDefinition "Data.Functor.Eq1" ["f"] Nothing
      [("Data.Functor.liftEq",Forall (Inferred Implicit (Ident "a") :| [Inferred Implicit (Ident "b")]) (Arrow (Parens (Arrow "a" (Arrow "b" "bool"))) (Arrow (App "f" (PosArg "a" :| [])) (Arrow (App "f" (PosArg "b" :| [])) "bool"))))]
    , ClassDefinition "Data.Functor.Ord1" ["f",Generalized Implicit (Parens (App "Eq1" (PosArg "f" :| [])))] Nothing
      [("Data.Functor.liftCompare",Forall (Inferred Implicit (Ident "a") :| [Inferred Implicit (Ident "b")]) (Arrow (Parens (Arrow "a" (Arrow "b" "comparison"))) (Arrow (App "f" (PosArg "a" :| [])) (Arrow (App "f" (PosArg "b" :| [])) "comparison"))))]
    , ClassDefinition "Data.Functor.Eq2" ["f"] Nothing
      [("Data.Functor.liftEq2",Forall (Inferred Implicit (Ident "a") :| [Inferred Implicit (Ident "b"),Inferred Implicit (Ident "c"),Inferred Implicit (Ident "d")]) (Arrow (Parens (Arrow "a" (Arrow "b" "bool"))) (Arrow (Parens (Arrow "c" (Arrow "d" "bool"))) (Arrow (App (App "f" (PosArg "a" :| [])) (PosArg "c" :| [])) (Arrow (App (App "f" (PosArg "b" :| [])) (PosArg "d" :| [])) "bool")))))]
    , ClassDefinition "Data.Functor.Ord2" ["f",Generalized Implicit (Parens (App "Eq2" (PosArg "f" :| [])))] Nothing
      [("Data.Functor.liftCompare2",Forall (Inferred Implicit (Ident "a") :| [Inferred Implicit (Ident "b"),Inferred Implicit (Ident "c"),Inferred Implicit (Ident "d")]) (Arrow (Parens (Arrow "a" (Arrow "b" "comparison"))) (Arrow (Parens (Arrow "c" (Arrow "d" "comparison"))) (Arrow (App (App "f" (PosArg "a" :| [])) (PosArg "c" :| [])) (Arrow (App (App "f" (PosArg "b" :| [])) (PosArg "d" :| [])) "comparison")))))]

     , ClassDefinition "Control.Category.Category" [Typed Ungeneralizable Explicit (Ident "cat" :| []) (Arrow "Type" (Arrow "Type" "Type"))] Nothing
      [("Control.Category.id",Forall (Inferred Implicit (Ident "a") :| []) (App (App "cat" (PosArg "a" :| [])) (PosArg "a" :| [])))
     ,("Control.Category.op_z2218U__",Forall (Inferred Implicit (Ident "b") :| [Inferred Implicit (Ident "c"),Inferred Implicit (Ident "a")]) (Arrow (App (App "cat" (PosArg "b" :| [])) (PosArg "c" :| [])) (Arrow (App (App "cat" (PosArg "a" :| [])) (PosArg "b" :| [])) (App (App "cat" (PosArg "a" :| [])) (PosArg "c" :| [])))))]

     , ClassDefinition "Data.Bifunctor.Bifunctor" ["p"] Nothing
       [("Data.Bifunctor.bimap",Forall (Inferred Implicit (Ident "a") :| [Inferred Implicit (Ident "b"),Inferred Implicit (Ident "c"),Inferred Implicit (Ident "d")]) (Arrow (Parens (Arrow "a" "b")) (Arrow (Parens (Arrow "c" "d")) (Arrow (App (App "p" (PosArg "a" :| [])) (PosArg "c" :| [])) (App (App "p" (PosArg "b" :| [])) (PosArg "d" :| []))))))
       ,("Data.Bifunctor.first",Forall (Inferred Implicit (Ident "a") :| [Inferred Implicit (Ident "b"),Inferred Implicit (Ident "c")]) (Arrow (Parens (Arrow "a" "b")) (Arrow (App (App "p" (PosArg "a" :| [])) (PosArg "c" :| [])) (App (App "p" (PosArg "b" :| [])) (PosArg "c" :| [])))))
       ,("Data.Bifunctor.second",Forall (Inferred Implicit (Ident "b") :| [Inferred Implicit (Ident "c"),Inferred Implicit (Ident "a")]) (Arrow (Parens (Arrow "b" "c")) (Arrow (App (App "p" (PosArg "a" :| [])) (PosArg "b" :| [])) (App (App "p" (PosArg "a" :| [])) (PosArg "c" :| [])))))]

    , ClassDefinition "Data.Functor.Classes.Eq1" ["f"] Nothing
        [ "Data.Functor.Classes.liftEq" =:
          (Forall [ Inferred Implicit (Ident "a")
                  , Inferred Implicit (Ident "b")] $
            ("a" `Arrow` "b" `Arrow` "bool") `Arrow`
            App1 "f" "a" `Arrow`  App1 "f" "b" `Arrow` "bool")
        ]
    , ClassDefinition "Data.Functor.Classes.Ord1" ["f"] Nothing
        [ "Data.Functor.Classes.liftCompare" =:
          (Forall [ Inferred Implicit (Ident "a")
                  , Inferred Implicit (Ident "b")] $
            ("a" `Arrow` "b" `Arrow` "comparison") `Arrow`
            App1 "f" "a" `Arrow`  App1 "f" "b" `Arrow` "comparison")
        ]
    , ClassDefinition "Control.Monad.Trans.Class.MonadTrans" ["t"] Nothing
        [ "Control.Monad.Trans.Class.lift" =:
          (Forall [ Inferred Implicit (Ident "m")
                  , Inferred Implicit (Ident "a")
                  , Generalized Implicit (App1 "GHC.Base.Monad" "m")
                  ] $
            (App1 "m" "a" `Arrow` App2 "t" "m" "a"))
          ]
    ]
  where
   (=:) = (,)
   infix 0 =:

builtInDefaultMethods :: Map Qualid (Map Qualid Term)
builtInDefaultMethods = fmap M.fromList $ M.fromList $
    [ "GHC.Base.Eq_" =:
        [ "GHC.Base.==" ~> Fun ["x", "y"] (App1 "negb" $ App2 "GHC.Base./=" "x" "y")
        , "GHC.Base./=" ~> Fun ["x", "y"] (App1 "negb" $ App2 "GHC.Base.==" "x" "y")
        ]
    , "GHC.Base.Ord" =:
        [ "GHC.Base.max" ~> Fun ["x", "y"] (IfBool SymmetricIf (App2 "GHC.Base.op_zlze__" "x" "y") "y" "x")
        , "GHC.Base.min" ~> Fun ["x", "y"] (IfBool SymmetricIf (App2 "GHC.Base.op_zlze__" "x" "y") "x" "y")

{-  x <= y  = compare x y /= GT
    x <  y  = compare x y == LT
    x >= y  = compare x y /= LT
    x >  y  = compare x y == GT   -}

        , "GHC.Base.op_zlze__" ~> Fun  ["x", "y"] (App2 "GHC.Base.op_zsze__" (App2 "GHC.Base.compare" "x" "y") "Gt")
        , "GHC.Base.op_zl__"   ~> Fun  ["x", "y"] (App2 "GHC.Base.op_zeze__" (App2 "GHC.Base.compare" "x" "y") "Lt")
        , "GHC.Base.op_zgze__" ~> Fun  ["x", "y"] (App2 "GHC.Base.op_zsze__" (App2 "GHC.Base.compare" "x" "y") "Lt")
        , "GHC.Base.op_zg__"   ~> Fun  ["x", "y"] (App2 "GHC.Base.op_zeze__" (App2 "GHC.Base.compare" "x" "y") "Gt")
        ]
    , "GHC.Base.Functor" =:
        [ "GHC.Base.op_zlzd__" ~> Fun ["x"] (App1 "GHC.Base.fmap" (App1 "GHC.Base.const" "x"))
        ]
    , "GHC.Base.Applicative" =:
        [ "GHC.Base.op_ztzg__" ~> Fun ["x", "y"]
            (let const_id = App1 "GHC.Base.const" "GHC.Base.id" in
            App2 "GHC.Base.op_zlztzg__" (App2 "GHC.Base.fmap" const_id "x") "y")
        , "GHC.Base.liftA2" ~> Fun ["f", "x"]
            (App1 "GHC.Base.op_zlztzg__" (App2 "GHC.Base.fmap" "f" "x"))
        {-
        , "op_zlzt__" ~> Fun ["x", "y"]
            (let const    = "GHC.Base.const" in
            App2 "op_zlztzg__" (App2 "GHC.Base.fmap" const    "x") "y")
        -}
        ]
    , "GHC.Base.Semigroup"  =:
        [ "Data.Semigroup.stimes" ~> App "Data.List.NonEmpty.NonEmpty_foldr1" (PosArg "Data.Semigroup.op_zlzg__" :| [])
        ]
    , "GHC.Base.Monoid" =:
        [ "GHC.Base.mappend" ~> "GHC.Base.<<>>"
        , "GHC.Base.mconcat" ~> App2 "GHC.Base.foldr" "GHC.Base.mappend" "GHC.Base.mempty"
        ]
    , "GHC.Base.Monad" =:
        [ "GHC.Base.return_" ~> "GHC.Base.pure"
        , "GHC.Base.op_zgzg__" ~> "GHC.Base.op_ztzg__"
        , "GHC.Base.fail" ~> Fun ["x"] "missingValue"
        ]

    , "Data.Traversable.Traversable" =:
      ["Data.Traversable.mapM" ~> "Data.Traversable.traverse",
       "Data.Traversable.sequence" ~> "Data.Traversable.sequenceA",
       "Data.Traversable.sequenceA" ~> App "Data.Traversable.traverse" (PosArg "GHC.Base.id" :| []),
       "Data.Traversable.traverse" ~> Fun ("arg_0__" :| [])
                         (Coq.Match (MatchItem "arg_0__" Nothing Nothing :| []) Nothing
                         [Equation (MultPattern (QualidPat (Bare "f") :| []) :| [])
                              (App "Coq.Program.Basics.compose" (PosArg "Data.Traversable.sequenceA"
                              :| [PosArg (App "GHC.Base.fmap" (PosArg "f" :| []))]))])]


    , "Data.Foldable.Foldable" =:
      -- inline the default definition of elem. Need an edit to modify this default....
      ["Data.Foldable.elem" ~> App "Coq.Program.Basics.compose" (PosArg (Parens (Fun ("arg_69__" :| []) (Coq.Match (MatchItem "arg_69__" Nothing Nothing :| []) Nothing [Equation (MultPattern (QualidPat (Bare "p") :| []) :| []) (App "Coq.Program.Basics.compose" (PosArg "Data.SemigroupInternal.getAny" :| [PosArg (App "Data.Foldable.foldMap" (PosArg (Parens (App "Coq.Program.Basics.compose" (PosArg "Data.SemigroupInternal.Mk_Any" :| [PosArg "p"]))) :| []))]))]))) :| [PosArg "GHC.Base.op_zeze__"]),
       ("Data.Foldable.fold" ~> App "Data.Foldable.foldMap" (PosArg "GHC.Base.id" :| [])),
       ("Data.Foldable.foldMap" ~> Fun ("arg_1__" :| []) (Coq.Match (MatchItem "arg_1__" Nothing Nothing :| []) Nothing [Equation (MultPattern (QualidPat (Bare "f") :| []) :| []) (App (App "Data.Foldable.foldr" (PosArg (Parens (App "Coq.Program.Basics.compose" (PosArg "GHC.Base.mappend" :| [PosArg "f"]))) :| [])) (PosArg "GHC.Base.mempty" :| []))])),
       ("Data.Foldable.foldl" ~> Fun ("arg_19__" :| ["arg_20__","arg_21__"]) (Coq.Match (MatchItem "arg_19__" Nothing Nothing :| [MatchItem "arg_20__" Nothing Nothing,MatchItem "arg_21__" Nothing Nothing]) Nothing [Equation (MultPattern (QualidPat (Bare "f") :| [QualidPat (Bare "z"),QualidPat (Bare "t")]) :| []) (App (App "Data.SemigroupInternal.appEndo" (PosArg (Parens (App "Data.SemigroupInternal.getDual" (PosArg (Parens (App (App "Data.Foldable.foldMap" (PosArg (Parens (App "Coq.Program.Basics.compose" (PosArg "Data.SemigroupInternal.Mk_Dual" :| [PosArg (App "Coq.Program.Basics.compose" (PosArg "Data.SemigroupInternal.Mk_Endo" :| [PosArg (App "GHC.Base.flip" (PosArg "f" :| []))]))]))) :| [])) (PosArg "t" :| []))) :| []))) :| [])) (PosArg "z" :| []))])),
       ("Data.Foldable.foldl'"~>Fun ("arg_24__" :| ["arg_25__","arg_26__"]) (Coq.Match (MatchItem "arg_24__" Nothing Nothing :| [MatchItem "arg_25__" Nothing Nothing,MatchItem "arg_26__" Nothing Nothing]) Nothing [Equation (MultPattern (QualidPat (Bare "f") :| [QualidPat (Bare "z0"),QualidPat (Bare "xs")]) :| []) (Let "f'" [] Nothing (Fun ("arg_27__" :| ["arg_28__","arg_29__"]) (Coq.Match (MatchItem "arg_27__" Nothing Nothing :| [MatchItem "arg_28__" Nothing Nothing,MatchItem "arg_29__" Nothing Nothing]) Nothing [Equation (MultPattern (QualidPat (Bare "x") :| [QualidPat (Bare "k"),QualidPat (Bare "z")]) :| []) (App "GHC.Base.op_zdzn__" (PosArg "k" :| [PosArg (App (App "f" (PosArg "z" :| [])) (PosArg "x" :| []))]))])) (App (App (App (App "Data.Foldable.foldr" (PosArg "f'" :| [])) (PosArg "GHC.Base.id" :| [])) (PosArg "xs" :| [])) (PosArg "z0" :| [])))])),
       ("Data.Foldable.foldr"~>Fun ("arg_4__" :| ["arg_5__","arg_6__"]) (Coq.Match (MatchItem "arg_4__" Nothing Nothing :| [MatchItem "arg_5__" Nothing Nothing,MatchItem "arg_6__" Nothing Nothing]) Nothing [Equation (MultPattern (QualidPat (Bare "f") :| [QualidPat (Bare "z"),QualidPat (Bare "t")]) :| []) (App (App "Data.SemigroupInternal.appEndo" (PosArg (Parens (App (App "Data.Foldable.foldMap" (PosArg (Parens (App "Coq.Program.Basics.compose" (PosArg "Data.SemigroupInternal.Mk_Endo" :| [PosArg "f"]))) :| [])) (PosArg "t" :| []))) :| [])) (PosArg "z" :| []))])),
       ("Data.Foldable.foldr'"~>Fun ("arg_9__" :| ["arg_10__","arg_11__"]) (Coq.Match (MatchItem "arg_9__" Nothing Nothing :| [MatchItem "arg_10__" Nothing Nothing,MatchItem "arg_11__" Nothing Nothing]) Nothing [Equation (MultPattern (QualidPat (Bare "f") :| [QualidPat (Bare "z0"),QualidPat (Bare "xs")]) :| []) (Let "f'" [] Nothing (Fun ("arg_12__" :| ["arg_13__","arg_14__"]) (Coq.Match (MatchItem "arg_12__" Nothing Nothing :| [MatchItem "arg_13__" Nothing Nothing,MatchItem "arg_14__" Nothing Nothing]) Nothing [Equation (MultPattern (QualidPat (Bare "k") :| [QualidPat (Bare "x"),QualidPat (Bare "z")]) :| []) (App "GHC.Base.op_zdzn__" (PosArg "k" :| [PosArg (App (App "f" (PosArg "x" :| [])) (PosArg "z" :| []))]))])) (App (App (App (App "Data.Foldable.foldl" (PosArg "f'" :| [])) (PosArg "GHC.Base.id" :| [])) (PosArg "xs" :| [])) (PosArg "z0" :| [])))])),
       ("Data.Foldable.length"~>App (App "Data.Foldable.foldl'" (PosArg (Parens (Fun ("arg_64__" :| ["arg_65__"]) (Coq.Match (MatchItem "arg_64__" Nothing Nothing :| [MatchItem "arg_65__" Nothing Nothing]) Nothing [Equation (MultPattern (QualidPat (Bare "c") :| [UnderscorePat]) :| []) (App "GHC.Num.op_zp__" (PosArg "c" :| [PosArg (App1 "GHC.Num.fromInteger" (Num 1))]))]))) :| [])) (PosArg (App1 "GHC.Num.fromInteger" (Num 0)) :| [])),
       ("Data.Foldable.null"~>App (App "Data.Foldable.foldr" (PosArg (Parens (Fun ("arg_61__" :| ["arg_62__"]) "false")) :| [])) (PosArg "true" :| [])),
       ("Data.Foldable.product"~>App "Coq.Program.Basics.compose" (PosArg "Data.SemigroupInternal.getProduct" :| [PosArg (App "Data.Foldable.foldMap" (PosArg "Data.SemigroupInternal.Mk_Product" :| []))])),
       ("Data.Foldable.sum"~>App "Coq.Program.Basics.compose" (PosArg "Data.SemigroupInternal.getSum" :| [PosArg (App "Data.Foldable.foldMap" (PosArg "Data.SemigroupInternal.Mk_Sum" :| []))])),
       ("Data.Foldable.toList"~>Fun ("arg_54__" :| []) (Coq.Match (MatchItem "arg_54__" Nothing Nothing :| []) Nothing [Equation (MultPattern (QualidPat (Bare "t") :| []) :| []) (App "GHC.Base.build" (PosArg (Parens (Fun ("_" :| "arg_55__" : ["arg_56__"]) (Coq.Match (MatchItem "arg_55__" Nothing Nothing :| [MatchItem "arg_56__" Nothing Nothing]) Nothing [Equation (MultPattern (QualidPat (Bare "c") :| [QualidPat (Bare "n")]) :| []) (App (App (App "Data.Foldable.foldr" (PosArg "c" :| [])) (PosArg "n" :| [])) (PosArg "t" :| []))]))) :| []))]))]



      , "Control.Arrow.Arrow" =:
        [("Control.Arrow.first",Parens (Fun ("arg_0__" :| []) (App "Control.Arrow.op_ztztzt__" (PosArg "arg_0__" :| [PosArg "Control.Category.id"]))))
        ,("Control.Arrow.op_zazaza__",Fun ("arg_11__" :| ["arg_12__"]) (Coq.Match (MatchItem "arg_11__" Nothing Nothing :| [MatchItem "arg_12__" Nothing Nothing]) Nothing [Equation (MultPattern (QualidPat (Bare "f") :| [QualidPat (Bare "g")]) :| []) (App "Control.Category.op_zgzgzg__" (PosArg (App "arr" (PosArg (Parens (Fun ("arg_13__" :| []) (Coq.Match (MatchItem "arg_13__" Nothing Nothing :| []) Nothing [Equation (MultPattern (QualidPat (Bare "b") :| []) :| []) (App "pair" (PosArg "b" :| [PosArg "b"]))]))) :| [])) :| [PosArg (App "op_ztztzt__" (PosArg "f" :| [PosArg "g"]))]))]))
        ,("Control.Arrow.op_ztztzt__",Fun ("arg_4__" :| ["arg_5__"]) (Coq.Match (MatchItem "arg_4__" Nothing Nothing :| [MatchItem "arg_5__" Nothing Nothing]) Nothing [Equation (MultPattern (QualidPat (Bare "f") :| [QualidPat (Bare "g")]) :| []) (Let "swap" [] Nothing (Fun ("arg_6__" :| []) (Coq.Match (MatchItem "arg_6__" Nothing Nothing :| []) Nothing [Equation (MultPattern (ArgsPat (Bare "pair") (QualidPat (Bare "x") : [QualidPat (Bare "y")]) :| []) :| []) (App "pair" (PosArg "y" :| [PosArg "x"]))])) (App "Control.Category.op_zgzgzg__" (PosArg (App "first" (PosArg "f" :| [])) :| [PosArg (App "Control.Category.op_zgzgzg__" (PosArg (App "arr" (PosArg "swap" :| [])) :| [PosArg (App "Control.Category.op_zgzgzg__" (PosArg (App "first" (PosArg "g" :| [])) :| [PosArg (App "arr" (PosArg "swap" :| []))]))]))])))]))
        ,("Control.Arrow.second",Parens (Fun ("arg_2__" :| []) (App "Control.Arrow.op_ztztzt__" (PosArg "Control.Category.id" :| [PosArg "arg_2__"]))))]
       , "Control.Arrow.ArrowZero" =: []
       , "Control.Arrow.ArrowPlus" =: []
       , "Control.Arrow.ArrowChoice" =:
         [("Control.Arrow.left",Parens (Fun ("arg_18__" :| []) (App "Control.Arrow.op_zpzpzp__" (PosArg "arg_18__" :| [PosArg "Control.Category.id"]))))
         ,("Control.Arrow.op_zbzbzb__",Fun ("arg_30__" :| ["arg_31__"]) (Coq.Match (MatchItem "arg_30__" Nothing Nothing :| [MatchItem "arg_31__" Nothing Nothing]) Nothing [Equation (MultPattern (QualidPat (Bare "f") :| [QualidPat (Bare "g")]) :| []) (Let "untag" [] Nothing (Fun ("arg_32__" :| []) (Coq.Match (MatchItem "arg_32__" Nothing Nothing :| []) Nothing [Equation (MultPattern (ArgsPat (Bare "inl") (QualidPat (Bare "x") : []) :| []) :| []) "x",Equation (MultPattern (ArgsPat (Bare "inr") (QualidPat (Bare "y") : []) :| []) :| []) "y"])) (App "Control.Category.op_zgzgzg__" (PosArg (App "Control.Arrow.op_zpzpzp__" (PosArg "f" :| [PosArg "g"])) :| [PosArg (App "Control.Arrow.arr" (PosArg "untag" :| []))])))]))
         ,("Control.Arrow.op_zpzpzp__",Fun ("arg_22__" :| ["arg_23__"]) (Coq.Match (MatchItem "arg_22__" Nothing Nothing :| [MatchItem "arg_23__" Nothing Nothing]) Nothing [Equation (MultPattern (QualidPat (Bare "f") :| [QualidPat (Bare "g")]) :| []) (Let "mirror" [Inferred Implicit (Ident "x"),Inferred Implicit (Ident "y")] (Just (Arrow (App (App "sum" (PosArg "x" :| [])) (PosArg "y" :| [])) (App (App "sum" (PosArg "y" :| [])) (PosArg "x" :| [])))) (Fun ("arg_24__" :| []) (Coq.Match (MatchItem "arg_24__" Nothing Nothing :| []) Nothing [Equation (MultPattern (ArgsPat (Bare "inl") (QualidPat (Bare "x") : []) :| []) :| []) (App "inr" (PosArg "x" :| [])),Equation (MultPattern (ArgsPat (Bare "inr") (QualidPat (Bare "y") : []) :| []) :| []) (App "inl" (PosArg "y" :| []))])) (App "Control.Category.op_zgzgzg__" (PosArg (App "left" (PosArg "f" :| [])) :| [PosArg (App "Control.Category.op_zgzgzg__" (PosArg (App "arr" (PosArg "mirror" :| [])) :| [PosArg (App "Control.Category.op_zgzgzg__" (PosArg (App "Control.Arrow.left" (PosArg "g" :| [])) :| [PosArg (App "Control.Arrow.arr" (PosArg "mirror" :| []))]))]))])))]))
         ,("Control.Arrow.right",Parens (Fun ("arg_20__" :| []) (App "Control.Arrow.op_zpzpzp__" (PosArg "Control.Category.id" :| [PosArg "arg_20__"]))))]


    ]
  where
   (=:) = (,)
   infix 0 =:
   m ~> d  = (m, d)