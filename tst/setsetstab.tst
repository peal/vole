#@local
gap> START_TEST("setsetstab.tst");
gap> ReadPackage("vole", "tst/test_functions.g");
true

#
gap> QC_Check([ QC_SetOf(QC_SetOf(IsPosInt)) ], {s} -> QuickChecker(Maximum(Flat([1,s])), [VoleCon.Stabilize(s, OnSetsSets)]));
true

#
gap> STOP_TEST("setsetstab.tst");
