#@local
gap> START_TEST("canonical-set.tst");
gap> ReadPackage("vole", "tst/test_functions.g");
true

#
gap> QC_Check([IsPermGroup, QC_SetOf(IsPosInt)],
>    {g, s} -> VoleTestCanonical(Maximum(Flat([LargestMovedPoint(g), s, 2])), g, s, s -> VoleCon.Stabilize(s, OnSets), OnSets));
true

#
gap> STOP_TEST("canonical-set.tst");
