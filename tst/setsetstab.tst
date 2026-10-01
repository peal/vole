#@local
gap> START_TEST("setsetstab.tst");
gap> ReadPackage("vole", "tst/test_functions.g");
true

#
#@if LoadPackage("quickcheck", false) <> fail and LoadPackage("ferret", false) <> fail
gap> QC_Check([QC_SetOf(QC_SetOf(IsPosInt))],
> {s} -> QuickChecker(Maximum(Flat([0, s])), [Constraint.Stabilize(s, OnSetsSets)])
> );
true
#@fi

# Issue #45
gap> Vole.Stabiliser(SymmetricGroup(3), [], OnSetsSets) = SymmetricGroup(3);
true
gap> Vole.Stabiliser(SymmetricGroup(3), [[]], OnSetsSets) = SymmetricGroup(3);
true
gap> VoleFind.Rep(4, VoleRefiner.SetSetTransporter([[]], []));
fail
gap> VoleFind.Rep(4, VoleRefiner.SetSetTransporter([], [[]]));
fail

# Issue #49
gap> IsTrivial(VoleFind.Group(Constraint.Stabilise([[]], OnSetsSets) : points := 1));
true

#
gap> STOP_TEST("setsetstab.tst");
