#@local
gap> START_TEST("canonical-grp-3.tst");
gap> ReadPackage("vole", "tst/test_functions.g");
true

#
#@if LoadPackage("quickcheck", false) <> fail
gap> QC_Check([IsPermGroup, IsPermGroup],
>     {g, s} -> VoleTestCanonical(g, s, Constraint.Stabilize, OnPoints));
true
#@fi

#
gap> STOP_TEST("canonical-grp-3.tst");
