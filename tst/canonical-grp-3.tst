#@local
gap> START_TEST("canonical-grp-3.tst");
gap> ReadPackage("vole", "tst/test_functions.g");
true

#
gap> QC_Check([IsPermGroup, IsPermGroup],
>     {g, s} -> VoleTestCanonical(g, s, VoleCon.Stabilize, OnPoints));
true

#
gap> STOP_TEST("canonical-grp-3.tst");
