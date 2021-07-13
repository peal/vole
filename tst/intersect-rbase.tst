#@local
gap> START_TEST("intersect-rbase.tst");
gap> ReadPackage("vole", "tst/test_functions.g");
true

#
gap> QC_CheckEqual([ IsPermGroup, IsPermGroup ],
> function(s,t)
>  local lmp;
>  lmp := Maximum(LargestMovedPoint(s), LargestMovedPoint(t), 2);
>  return VoleFind.Group( [GB_Con.InGroup(lmp, s), GB_Con.InGroup(lmp, t)]);
>  end,
> {s,t} -> Intersection(s,t) );
true

#
gap> STOP_TEST("intersect-rbase.tst");
