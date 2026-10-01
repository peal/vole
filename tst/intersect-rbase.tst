#@local
gap> START_TEST("intersect-rbase.tst");
gap> ReadPackage("vole", "tst/test_functions.g");
true

#
#@if LoadPackage("quickcheck", false) <> fail
gap> QC_CheckEqual([IsPermGroup, IsPermGroup],
>     {s, t} -> VoleFind.Group(GB_Con.InGroup(s), GB_Con.InGroup(t)),
>     Intersection);
true
#@fi

#
gap> STOP_TEST("intersect-rbase.tst");
