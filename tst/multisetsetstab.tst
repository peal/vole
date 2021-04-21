#@local
gap> START_TEST("multisetsetstab.tst");
gap> ReadPackage("vole", "tst/test_functions.g");
true

#
gap> QC_Check([ QC_SetOf(QC_SetOf(IsPosInt)),QC_SetOf(QC_SetOf(IsPosInt)),QC_SetOf(QC_SetOf(IsPosInt)) ],
>  {a,b,c} -> QuickChecker(Maximum(Flat([a,b,c,2])), [VoleCon.SetSetStab(a),VoleCon.SetSetStab(b),VoleCon.SetSetStab(c)]));
true

#
gap> STOP_TEST("multisetsetstab.tst");
