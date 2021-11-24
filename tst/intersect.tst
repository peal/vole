#@local
gap> START_TEST("intersect.tst");
gap> ReadPackage("vole", "tst/test_functions.g");
true

#
gap> QC_CheckEqual([IsPermGroup, IsPermGroup],
>   {s, t} -> VoleFind.Group(GB_Con.InGroupSimple(s), GB_Con.InGroupSimple(t)),
>   Intersection);
true

#
gap> STOP_TEST("intersect.tst");
