#@local
gap> START_TEST("canonical-set.tst");
gap> LoadPackage("vole", false);
true
gap> LoadPackage("quickcheck", false);
true
gap> ReadPackage("vole", "tst/test_functions.g");
true

#
gap> QC_Check([IsPermGroup, QC_SetOf(IsPosInt)],
>    {g, s} -> VoleTestCanonical(Maximum([LargestMovedPoint(g), Maximum(s),2]), g, s, VoleCon.SetStab, OnSets));
true

#
gap> STOP_TEST("canonical-set.tst");
