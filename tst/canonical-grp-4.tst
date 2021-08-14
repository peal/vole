#@local
gap> START_TEST("canonical-grp-4.tst");
gap> ReadPackage("vole", "tst/test_functions.g");
true

#
gap> QC_Check([IsPermGroup],
> function(s)
>   local lmp;
>   lmp := Maximum( LargestMovedPoint(s), 2);
>   return VoleTestCanonical(lmp, SymmetricGroup(lmp), s,
>     {x} -> [VoleCon.Stabilize(x)],
>     {x,p} -> x^p);
> end);
true

#
gap> STOP_TEST("canonical-grp-4.tst");
