#@local
gap> START_TEST("settuplestab.tst");
gap> ReadPackage("vole", "tst/test_functions.g");
true

#
#@if LoadPackage("quickcheck", false) <> fail and LoadPackage("ferret", false) <> fail
gap> QC_Check([QC_SetOf(QC_ListOf(IsPosInt))],
> {s} -> QuickChecker(Maximum(Flat([0, s])), [Constraint.Stabilize(s, OnSetsTuples)])
> );
true
#@fi

# Issue #40
gap> Vole.Stabiliser(SymmetricGroup(3), [], OnSetsTuples) = SymmetricGroup(3);
true
gap> Vole.Stabiliser(SymmetricGroup(3), [[]], OnSetsTuples) = SymmetricGroup(3);
true

#
gap> STOP_TEST("settuplestab.tst");
