#@local
gap> START_TEST("intersect-coset.tst");
gap> ReadPackage("vole", "tst/test_functions.g");
true

#
gap> QC_CheckEqual([ IsPermGroup, IsPermGroup, IsPerm ],
> function(s,t,p)
>  local lmp;
>  lmp := Maximum(LargestMovedPoint(s), LargestMovedPoint(t), LargestMovedPoint(p), 2);
>  return VoleFind.Coset([GB_Con.InCosetSimple(s,p), GB_Con.InCosetSimple(t,p)]);
>  end,
> {s,t,p} -> RightCoset(Intersection(s,t),p) );
true

#
gap> STOP_TEST("intersect.tst");
