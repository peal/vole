#@local
gap> START_TEST("canonical-grp-4.tst");
gap> ReadPackage("vole", "tst/test_functions.g");
true

#
#@if LoadPackage("quickcheck", false) <> fail
gap> QC_Check([IsPermGroup], {s} ->
>     VoleTestCanonical(
>       SymmetricGroup(LargestMovedPoint(s)), s, Constraint.Stabilize, OnPoints));
true
#@fi

#
gap> STOP_TEST("canonical-grp-4.tst");
