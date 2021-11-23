#@local
gap> START_TEST("settuplestab.tst");
gap> ReadPackage("vole", "tst/test_functions.g");
true

#
gap> QC_Check([ QC_SetOf(QC_ListOf(IsPosInt)) ], {s} -> QuickChecker(Maximum(Flat([1,s])), [VoleCon.Stabilize(s, OnSetsTuples)]));
true

#
gap> Vole.Stabiliser(SymmetricGroup(3), [], OnSetsTuples) = SymmetricGroup(3);
true
gap> Vole.Stabiliser(SymmetricGroup(3), [[]], OnSetsTuples) = SymmetricGroup(3);
true

#
gap> STOP_TEST("settuplestab.tst");
