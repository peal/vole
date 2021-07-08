#@local
gap> START_TEST("intersect.tst");
gap> ReadPackage("vole", "tst/test_functions.g");
true

#
gap> QC_CheckEqual([ IsPermGroup, IsPermGroup ],
> function(s,t)
>  local lmp;
>  lmp := Maximum(LargestMovedPoint(s), LargestMovedPoint(t), 2);
>  return Vole.FindGroup([GB_Con.InGroupSimple(lmp, s), GB_Con.InGroupSimple(lmp, t)]);
>  end,
> {s,t} -> Intersection(s,t) );
true

#
gap> STOP_TEST("intersect.tst");
