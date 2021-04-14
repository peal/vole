#@local
gap> START_TEST("setsetstab.tst");
gap> LoadPackage("vole", false);
true
gap> LoadPackage("ferret", false);
true
gap> LoadPackage("quickcheck", false);
true

#
gap> QC_Check([ QC_SetOf(QC_SetOf(IsPosInt)) ], {s} -> QuickChecker(Maximum(Flat(s)), [con.SetSetStab(s)]));
true

#
gap> STOP_TEST("setsetstab.tst");
