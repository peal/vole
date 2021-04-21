#@local
gap> START_TEST("canonical-setset.tst");
gap> ReadPackage("vole", "tst/test_functions.g");
true

#
gap> QC_Check([IsPermGroup, QC_SetOf(QC_SetOf(IsPosInt))],
>    {g, s} -> VoleTestCanonical(Maximum([LargestMovedPoint(g), Maximum(Flat(s)),2]), g, s, VoleCon.SetSetStab, OnSetsSets));
true

#
gap> STOP_TEST("canonical-setset.tst");
