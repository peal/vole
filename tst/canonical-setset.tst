#@local
gap> START_TEST("canonical-setset.tst");
gap> ReadPackage("vole", "tst/test_functions.g");
true

#
gap> QC_Check([IsPermGroup, QC_SetOf(QC_SetOf(IsPosInt))],
> {g, s} -> VoleTestCanonical(g, s, x -> Constraint.Stabilize(x, OnSetsSets), OnSetsSets));
true

#
gap> STOP_TEST("canonical-setset.tst");
