#@local
gap> START_TEST("intersect-rbase.tst");
gap> ReadPackage("vole", "tst/test_functions.g");
true

#
gap> QC_CheckEqual([IsPermGroup, IsPermGroup],
>     {s, t} -> VoleFind.Group(GB_Con.InGroup(s), GB_Con.InGroup(t)),
>     Intersection);
true

#
gap> STOP_TEST("intersect-rbase.tst");
