#@local
gap> START_TEST("canonical-grp-4.tst");
gap> ReadPackage("vole", "tst/test_functions.g");
true

#
gap> QC_Check([IsPermGroup], {s} ->
>     VoleTestCanonical(
>       SymmetricGroup(LargestMovedPoint(s)), s, VoleCon.Stabilize, OnPoints));
true

#
gap> STOP_TEST("canonical-grp-4.tst");
