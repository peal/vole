#@local
gap> START_TEST("canonical-grp-3.tst");
gap> ReadPackage("vole", "tst/test_functions.g");
true

#
gap> QC_Check([IsPermGroup, IsPermGroup],
> function(g,s)
>   local lmp;
>   lmp := Maximum(LargestMovedPoint(g), LargestMovedPoint(s), 2);
>   return VoleTestCanonical(lmp, g, s,
>     {x} -> [VoleCon.Stabilize(x)],
>     {x,p} -> x^p);
> end);
true

#
gap> STOP_TEST("canonical-grp-3.tst");
