#@local
gap> START_TEST("intersect-coset.tst");
gap> ReadPackage("vole", "tst/test_functions.g");
true

#
# TODO: Add some tests of coset intersections that might be empty
#@if LoadPackage("quickcheck", false) <> fail
gap> QC_CheckEqual([IsPermGroup, IsPermGroup, IsPerm],
> {s, t, p} -> VoleFind.Coset(GB_Con.InCosetSimple(s, p), GB_Con.InCosetSimple(t, p)),
> {s, t, p} -> RightCoset(Intersection(s, t), p));
true
#@fi

#
gap> STOP_TEST("intersect-coset.tst");
