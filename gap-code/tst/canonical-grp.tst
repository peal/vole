gap> Read("gap-code/vole-base.g");
gap> Read("gap-code/tst/test_functions.g");
gap> LoadPackage("quickcheck", false);;
gap> QC_Check([IsPermGroup, IsPermGroup],
> function(g,s)
> local lmp;
> lmp := Maximum([LargestMovedPoint(g), LargestMovedPoint(s),2]);
> return VoleTestCanonical(lmp, g, s, x -> GB_Con.NormaliserSimple(lmp,x), \^);
> end);
true
