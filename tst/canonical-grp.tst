#@local
gap> START_TEST("canonical-grp.tst");
gap> LoadPackage("vole", false);
true
gap> LoadPackage("quickcheck", false);
true
gap> ReadPackage("vole", "tst/test_functions.g");
true

#
gap> QC_Check([IsPermGroup, IsPermGroup],
> function(g,s)
>   local lmp;
>   lmp := Maximum([LargestMovedPoint(g), LargestMovedPoint(s),2]);
>   return VoleTestCanonical(lmp, g, s, x -> GB_Con.NormaliserSimple(lmp,x), OnPoints);
> end);
true

#
gap> STOP_TEST("canonical-grp.tst");
