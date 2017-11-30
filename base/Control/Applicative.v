(* Default settings (from HsToCoq.Coq.Preamble) *)

Generalizable All Variables.

Unset Implicit Arguments.
Set Maximal Implicit Insertion.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Require Coq.Program.Tactics.
Require Coq.Program.Wf.

(* Converted imports: *)

Require Control.Arrow.
Require Control.Category.
Require Data.Functor.
Require Data.Tuple.
Require GHC.Base.
Require GHC.Prim.
Import Control.Arrow.Notations.
Import Control.Category.Notations.
Import Data.Functor.Notations.
Import GHC.Base.Notations.

(* Converted type declarations: *)

Inductive WrappedMonad (m : Type -> Type) a : Type := Mk_WrapMonad : m
                                                                     a -> WrappedMonad m a.

Inductive WrappedArrow (a : Type -> Type -> Type) b c : Type := Mk_WrapArrow : a
                                                                               b c -> WrappedArrow a b c.

Arguments Mk_WrapMonad {_} {_} _.

Arguments Mk_WrapArrow {_} {_} {_} _.

Definition unwrapMonad {m : Type -> Type} {a} (arg_0__ : WrappedMonad m a) :=
  match arg_0__ with
    | Mk_WrapMonad unwrapMonad => unwrapMonad
  end.

Definition unwrapArrow {a : Type -> Type -> Type} {b} {c} (arg_1__
                         : WrappedArrow a b c) :=
  match arg_1__ with
    | Mk_WrapArrow unwrapArrow => unwrapArrow
  end.
(* Converted value declarations: *)

Instance Unpeel_WrappedMonad {m} {a} : GHC.Prim.Unpeel (WrappedMonad m a) (m
                                                       a) := GHC.Prim.Build_Unpeel _ _ unwrapMonad Mk_WrapMonad.

Instance Unpeel_WrappedArrow {a} {b} {c} : GHC.Prim.Unpeel (WrappedArrow a b c)
                                                           (a b c) := GHC.Prim.Build_Unpeel _ _ unwrapArrow
                                                                                            Mk_WrapArrow.

Local Definition Functor__WrappedMonad_fmap {inst_m} `{GHC.Base.Monad inst_m}
    : forall {a} {b},
        (a -> b) -> (WrappedMonad inst_m) a -> (WrappedMonad inst_m) b :=
  fun {a} {b} =>
    fun arg_53__ arg_54__ =>
      match arg_53__ , arg_54__ with
        | f , Mk_WrapMonad v => Mk_WrapMonad (GHC.Base.liftM f v)
      end.

Local Definition Functor__WrappedMonad_op_zlzd__ {inst_m} `{GHC.Base.Monad
                                                 inst_m} : forall {a} {b},
                                                             a -> (WrappedMonad inst_m) b -> (WrappedMonad inst_m) a :=
  fun {a} {b} => fun x => Functor__WrappedMonad_fmap (GHC.Base.const x).

Program Instance Functor__WrappedMonad {m} `{GHC.Base.Monad m}
  : GHC.Base.Functor (WrappedMonad m) := fun _ k =>
    k {|GHC.Base.op_zlzd____ := fun {a} {b} => Functor__WrappedMonad_op_zlzd__ ;
      GHC.Base.fmap__ := fun {a} {b} => Functor__WrappedMonad_fmap |}.

Local Definition Applicative__WrappedMonad_op_zlztzg__ {inst_m} `{GHC.Base.Monad
                                                       inst_m} : forall {a} {b},
                                                                   (WrappedMonad inst_m) (a -> b) -> (WrappedMonad
                                                                   inst_m) a -> (WrappedMonad inst_m) b :=
  fun {a} {b} =>
    fun arg_49__ arg_50__ =>
      match arg_49__ , arg_50__ with
        | Mk_WrapMonad f , Mk_WrapMonad v => Mk_WrapMonad (GHC.Base.ap f v)
      end.

Local Definition Applicative__WrappedMonad_op_ztzg__ {inst_m} `{GHC.Base.Monad
                                                     inst_m} : forall {a} {b},
                                                                 (WrappedMonad inst_m) a -> (WrappedMonad inst_m)
                                                                 b -> (WrappedMonad inst_m) b :=
  fun {a} {b} =>
    fun x y =>
      Applicative__WrappedMonad_op_zlztzg__ (GHC.Base.fmap (GHC.Base.const
                                                           GHC.Base.id) x) y.

Local Definition Applicative__WrappedMonad_pure {inst_m} `{GHC.Base.Monad
                                                inst_m} : forall {a}, a -> (WrappedMonad inst_m) a :=
  fun {a} => Mk_WrapMonad GHC.Base.∘ GHC.Base.pure.

Program Instance Applicative__WrappedMonad {m} `{GHC.Base.Monad m}
  : GHC.Base.Applicative (WrappedMonad m) := fun _ k =>
    k {|GHC.Base.op_ztzg____ := fun {a} {b} => Applicative__WrappedMonad_op_ztzg__ ;
      GHC.Base.op_zlztzg____ := fun {a} {b} => Applicative__WrappedMonad_op_zlztzg__ ;
      GHC.Base.pure__ := fun {a} => Applicative__WrappedMonad_pure |}.

(* Translating `instance forall {m}, forall `{GHC.Base.MonadPlus m},
   GHC.Base.Alternative (Control.Applicative.WrappedMonad m)' failed: OOPS! Cannot
   find information for class Qualified "GHC.Base" "Alternative" unsupported *)

Local Definition Functor__WrappedArrow_fmap {inst_a} {inst_b}
                                            `{Control.Arrow.Arrow inst_a} : forall {a} {b},
                                                                              (a -> b) -> (WrappedArrow inst_a inst_b)
                                                                              a -> (WrappedArrow inst_a inst_b) b :=
  fun {a} {b} =>
    fun arg_44__ arg_45__ =>
      match arg_44__ , arg_45__ with
        | f , Mk_WrapArrow a => Mk_WrapArrow (a Control.Category.>>> Control.Arrow.arr
                                             f)
      end.

Local Definition Functor__WrappedArrow_op_zlzd__ {inst_a} {inst_b}
                                                 `{Control.Arrow.Arrow inst_a} : forall {a} {b},
                                                                                   a -> (WrappedArrow inst_a inst_b)
                                                                                   b -> (WrappedArrow inst_a inst_b)
                                                                                   a :=
  fun {a} {b} => fun x => Functor__WrappedArrow_fmap (GHC.Base.const x).

Program Instance Functor__WrappedArrow {a} {b} `{Control.Arrow.Arrow a}
  : GHC.Base.Functor (WrappedArrow a b) := fun _ k =>
    k {|GHC.Base.op_zlzd____ := fun {a} {b} => Functor__WrappedArrow_op_zlzd__ ;
      GHC.Base.fmap__ := fun {a} {b} => Functor__WrappedArrow_fmap |}.

Local Definition Applicative__WrappedArrow_op_zlztzg__ {inst_a} {inst_b}
                                                       `{Control.Arrow.Arrow inst_a} : forall {a} {b},
                                                                                         (WrappedArrow inst_a inst_b)
                                                                                         (a -> b) -> (WrappedArrow
                                                                                         inst_a inst_b)
                                                                                         a -> (WrappedArrow inst_a
                                                                                         inst_b) b :=
  fun {a} {b} =>
    fun arg_40__ arg_41__ =>
      match arg_40__ , arg_41__ with
        | Mk_WrapArrow f , Mk_WrapArrow v => Mk_WrapArrow ((f Control.Arrow.&&& v)
                                                          Control.Category.>>> Control.Arrow.arr (Data.Tuple.uncurry
                                                                                                 GHC.Base.id))
      end.

Local Definition Applicative__WrappedArrow_op_ztzg__ {inst_a} {inst_b}
                                                     `{Control.Arrow.Arrow inst_a} : forall {a} {b},
                                                                                       (WrappedArrow inst_a inst_b)
                                                                                       a -> (WrappedArrow inst_a inst_b)
                                                                                       b -> (WrappedArrow inst_a inst_b)
                                                                                       b :=
  fun {a} {b} =>
    fun x y =>
      Applicative__WrappedArrow_op_zlztzg__ (GHC.Base.fmap (GHC.Base.const
                                                           GHC.Base.id) x) y.

Local Definition Applicative__WrappedArrow_pure {inst_a} {inst_b}
                                                `{Control.Arrow.Arrow inst_a} : forall {a},
                                                                                  a -> (WrappedArrow inst_a inst_b) a :=
  fun {a} => fun x => Mk_WrapArrow (Control.Arrow.arr (GHC.Base.const x)).

Program Instance Applicative__WrappedArrow {a} {b} `{Control.Arrow.Arrow a}
  : GHC.Base.Applicative (WrappedArrow a b) := fun _ k =>
    k {|GHC.Base.op_ztzg____ := fun {a} {b} => Applicative__WrappedArrow_op_ztzg__ ;
      GHC.Base.op_zlztzg____ := fun {a} {b} => Applicative__WrappedArrow_op_zlztzg__ ;
      GHC.Base.pure__ := fun {a} => Applicative__WrappedArrow_pure |}.

(* Translating `instance forall {a} {b}, forall `{Control.Arrow.ArrowZero a}
   `{Control.Arrow.ArrowPlus a}, GHC.Base.Alternative
   (Control.Applicative.WrappedArrow a b)' failed: OOPS! Cannot find information
   for class Qualified "GHC.Base" "Alternative" unsupported *)

(* Skipping instance Applicative__ZipList *)

(* Translating `instance GHC.Generics.Generic1 Control.Applicative.ZipList'
   failed: OOPS! Cannot find information for class Qualified "GHC.Generics"
   "Generic1" unsupported *)

(* Translating `instance forall {a}, GHC.Generics.Generic
   (Control.Applicative.ZipList a)' failed: OOPS! Cannot find information for class
   Qualified "GHC.Generics" "Generic" unsupported *)

(* Skipping instance Foldable__ZipList *)

(* Skipping instance Functor__ZipList *)

(* Translating `instance forall {a}, forall `{GHC.Read.Read a}, GHC.Read.Read
   (Control.Applicative.ZipList a)' failed: OOPS! Cannot find information for class
   Qualified "GHC.Read" "Read" unsupported *)

(* Skipping instance Ord__ZipList *)

(* Skipping instance Eq___ZipList *)

(* Translating `instance forall {a}, forall `{GHC.Show.Show a}, GHC.Show.Show
   (Control.Applicative.ZipList a)' failed: OOPS! Cannot find information for class
   Qualified "GHC.Show" "Show" unsupported *)

(* Translating `instance forall {a} {b}, GHC.Generics.Generic1
   (Control.Applicative.WrappedArrow a b)' failed: OOPS! Cannot find information
   for class Qualified "GHC.Generics" "Generic1" unsupported *)

(* Translating `instance forall {a} {b} {c}, GHC.Generics.Generic
   (Control.Applicative.WrappedArrow a b c)' failed: OOPS! Cannot find information
   for class Qualified "GHC.Generics" "Generic" unsupported *)

Local Definition Monad__WrappedMonad_op_zgzg__ {inst_m} `{GHC.Base.Monad inst_m}
    : forall {a} {b},
        WrappedMonad inst_m a -> WrappedMonad inst_m b -> WrappedMonad inst_m b :=
  fun {a} {b} => GHC.Prim.coerce _GHC.Base.>>_.

Local Definition Monad__WrappedMonad_op_zgzgze__ {inst_m} `{GHC.Base.Monad
                                                 inst_m} : forall {a} {b},
                                                             WrappedMonad inst_m a -> (a -> WrappedMonad inst_m
                                                             b) -> WrappedMonad inst_m b :=
  fun {a} {b} => GHC.Prim.coerce _GHC.Base.>>=_.

Local Definition Monad__WrappedMonad_return_ {inst_m} `{GHC.Base.Monad inst_m}
    : forall {a}, a -> WrappedMonad inst_m a :=
  fun {a} => GHC.Prim.coerce GHC.Base.return_.

Program Instance Monad__WrappedMonad {m} `{GHC.Base.Monad m} : GHC.Base.Monad
                                                               (WrappedMonad m) := fun _ k =>
    k {|GHC.Base.op_zgzg____ := fun {a} {b} => Monad__WrappedMonad_op_zgzg__ ;
      GHC.Base.op_zgzgze____ := fun {a} {b} => Monad__WrappedMonad_op_zgzgze__ ;
      GHC.Base.return___ := fun {a} => Monad__WrappedMonad_return_ |}.

(* Translating `instance forall {m}, GHC.Generics.Generic1
   (Control.Applicative.WrappedMonad m)' failed: OOPS! Cannot find information for
   class Qualified "GHC.Generics" "Generic1" unsupported *)

(* Translating `instance forall {m} {a}, GHC.Generics.Generic
   (Control.Applicative.WrappedMonad m a)' failed: OOPS! Cannot find information
   for class Qualified "GHC.Generics" "Generic" unsupported *)

Definition optional {f} {a} `{GHC.Base.Alternative f} : f a -> f (option a) :=
  fun v => (Some Data.Functor.<$> v) GHC.Base.<|> GHC.Base.pure None.

(* Unbound variables:
     None Some Type option Control.Arrow.Arrow Control.Arrow.arr
     Control.Arrow.op_zazaza__ Control.Category.op_zgzgzg__ Data.Functor.op_zlzdzg__
     Data.Tuple.uncurry GHC.Base.Alternative GHC.Base.Applicative GHC.Base.Functor
     GHC.Base.Monad GHC.Base.ap GHC.Base.const GHC.Base.fmap GHC.Base.id
     GHC.Base.liftM GHC.Base.op_z2218U__ GHC.Base.op_zgzg__ GHC.Base.op_zgzgze__
     GHC.Base.op_zlzbzg__ GHC.Base.pure GHC.Base.return_ GHC.Prim.Build_Unpeel
     GHC.Prim.Unpeel GHC.Prim.coerce
*)
