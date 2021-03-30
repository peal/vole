gap> Read("gap-code/vole-base.g");
gap> LoadPackage("quickcheck", false);;
gap> QC_Check([ QC_SetOf(QC_SetOf(IsPosInt)),QC_SetOf(QC_SetOf(IsPosInt)),QC_SetOf(QC_SetOf(IsPosInt)) ],
>  {a,b,c} -> QuickChecker(Maximum(Flat([a,b,c,2])), [con.SetSetStab(a),con.SetSetStab(b),con.SetSetStab(c)]));
true
