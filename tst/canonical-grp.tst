#@local
gap> START_TEST("canonical-grp.tst");
gap> ReadPackage("vole", "tst/test_functions.g");
true

#
gap> QC_Check([IsPermGroup, IsPermGroup],
> function(g,s)
>   local lmp;
>   lmp := Maximum([LargestMovedPoint(g), LargestMovedPoint(s),2]);
>   return VoleTestCanonical(lmp, g, s, x -> GB_Con.NormaliserSimple(lmp,x), OnPoints);
> end, rec(limit := 7));
true

#
gap> STOP_TEST("canonical-grp.tst");
