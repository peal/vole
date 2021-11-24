#@local
gap> START_TEST("setsetstab.tst");
gap> ReadPackage("vole", "tst/test_functions.g");
true

#
gap> QC_Check([ QC_SetOf(QC_SetOf(IsPosInt)) ], {s} -> QuickChecker(Maximum(Flat([1,s])), [VoleCon.Stabilize(s, OnSetsSets)]));
true

#
gap> Vole.Stabiliser(SymmetricGroup(3), [], OnSetsSets) = SymmetricGroup(3);
true
gap> Vole.Stabiliser(SymmetricGroup(3), [[]], OnSetsSets) = SymmetricGroup(3);
true

#
gap> VoleFind.Rep(4, VoleRefiner.SetSetTransporter([[]], []));
fail
gap> VoleFind.Rep(4, VoleRefiner.SetSetTransporter([], [[]]));
fail

#
gap> STOP_TEST("setsetstab.tst");
