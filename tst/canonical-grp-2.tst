#@local
gap> START_TEST("canonical-grp-2.tst");
gap> ReadPackage("vole", "tst/test_functions.g");
true

#
gap> QC_Check([IsPermGroup, IsPermGroup, IsPermGroup],
> function(g,s1,s2)
>   local lmp;
>   lmp := Maximum([LargestMovedPoint(g), LargestMovedPoint(s1), LargestMovedPoint(s2),2]);
>   return VoleTestCanonical(lmp, g, [s1,s2],
>     {x} -> [GB_Con.NormaliserSimple(lmp,x[1]), GB_Con.NormaliserSimple(lmp,x[2])],
>     {x,p} -> [x[1]^p, x[2]^p]);
> end);
true

#
gap> STOP_TEST("canonical-grp-2.tst");
