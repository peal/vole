#@local
gap> START_TEST("settuplestab.tst");
gap> ReadPackage("vole", "tst/test_functions.g");
true

#
gap> QC_Check([ QC_SetOf(QC_ListOf(IsPosInt)) ], {s} -> QuickChecker(Maximum(Flat(s)), [VoleCon.Stabilize(s, OnSetsTuples)]));
true

#
gap> STOP_TEST("settuplestab.tst");
