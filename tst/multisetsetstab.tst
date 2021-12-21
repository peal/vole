#@local
gap> START_TEST("multisetsetstab.tst");
gap> ReadPackage("vole", "tst/test_functions.g");
true

#
gap> QC_Check(List([1 .. 3], i -> QC_SetOf(QC_SetOf(IsPosInt))),
> {a,b,c} -> QuickChecker(Maximum(Flat([a, b, c, 0])),
>                         List([a, b, c], x -> Constraint.Stabilize(x, OnSetsSets))
> ));
true

#
gap> STOP_TEST("multisetsetstab.tst");
