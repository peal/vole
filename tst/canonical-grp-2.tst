#@local
gap> START_TEST("canonical-grp-2.tst");
gap> ReadPackage("vole", "tst/test_functions.g");
true

#
gap> QC_Check([IsPermGroup, IsPermGroup, IsPermGroup],
> function(g, s1, s2)
>   return VoleTestCanonical(g, [s1, s2],
>     {x} -> [GB_Con.NormaliserSimple(x[1]), GB_Con.NormaliserSimple(x[2])],
>     OnPairs);
> end);
true

#
gap> STOP_TEST("canonical-grp-2.tst");
