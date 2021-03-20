gap> Read("gap-code/vole-base.g");
gap> LoadPackage("quickcheck", false);;
gap> QC_Check([ QC_SetOf(QC_ListOf(IsPosInt)) ], {s} -> QuickChecker(Maximum(Flat(s)), [con.SetTupleStab(s)]));
true
