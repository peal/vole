#@local
gap> START_TEST("settuplestab.tst");
gap> LoadPackage("vole", false);
true
gap> LoadPackage("ferret", false);
true
gap> LoadPackage("quickcheck", false);
true

#
gap> QC_Check([ QC_SetOf(QC_ListOf(IsPosInt)) ], {s} -> QuickChecker(Maximum(Flat(s)), [VoleCon.SetTupleStab(s)]));
true

#
gap> STOP_TEST("settuplestab.tst");
