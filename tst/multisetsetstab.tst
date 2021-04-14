#@local
gap> START_TEST("multisetsetstab.tst");
gap> LoadPackage("vole", false);
true
gap> LoadPackage("quickcheck", false);
true

#
gap> QC_Check([ QC_SetOf(QC_SetOf(IsPosInt)),QC_SetOf(QC_SetOf(IsPosInt)),QC_SetOf(QC_SetOf(IsPosInt)) ],
>  {a,b,c} -> QuickChecker(Maximum(Flat([a,b,c,2])), [con.SetSetStab(a),con.SetSetStab(b),con.SetSetStab(c)]));
true

#
gap> STOP_TEST("multisetsetstab.tst");
