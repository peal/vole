#@local
gap> START_TEST("canonical-set.tst");
gap> ReadPackage("vole", "tst/test_functions.g");
true

#
gap> QC_Check([IsPermGroup, QC_SetOf(IsPosInt)],
> {g, s} -> VoleTestCanonical(g, s, s -> Constraint.Stabilize(s, OnSets), OnSets));
true

#
gap> STOP_TEST("canonical-set.tst");
