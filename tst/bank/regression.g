# Permanent regression bank.
#
# Every entry corresponds to an input that exposed a bug. Once a bug is
# fixed, the input lives here forever so the bug can never silently
# regress.
#
# Adding an entry:
#   1. Add a record to RegressionEntries below with: degree n, group
#      generators, and a one-line description naming the bug or PR.
#   2. Reference the bug in a comment with a date.
#
# Entries are run on EVERY mode (quick/nightly/full).

if not IsBoundGlobal("BankCompareNormaliser") then
    Read("tst/bank/helpers.g");
fi;

RegressionEntries := [
    # 2026-05-17: PSL(2,25) on 26 points crashed the orbital refiner
    # because _BTKit.orbitalEquivalenceKey serialised the canonical
    # form to a multi-kB string and exceeded GAP's 1023-char record-
    # name limit inside _BTKit.partitionByKey. Fix: HashMap with
    # structured (immutable list-of-sorted-lists) keys.
    rec(n := 26,
        gens := GeneratorsOfGroup(PSL(2, 25)),
        note := "partitionByKey record-name overflow on 26-vertex canonical form"),

    # 2026-05: the default refiner OrbitalRegOrbitChar ran FittingSubgroup
    # unconditionally in findRegularCharacteristicSubgroup; on this group
    # (|H|~6e21, not solvable, no regular char subgroup) that cost 7.6 s for
    # a guaranteed-fail. Fix: gate FittingSubgroup behind IsSolvableGroup.
    # Entry guards that the gate keeps the answer correct.
    rec(n := 56,
        gens := GeneratorsOfGroup(WreathProduct(
            WreathProduct(SymmetricGroup(2), SymmetricGroup(4)),
            SymmetricGroup(7))),
        note := "FittingSubgroup gate (S_2 wr S_4 wr S_7)"),

    # 2026-06: dropped the wrapper's IsNormal(G,U) pre-check (matching GAP,
    # which only checks U=G); normal U must now be confirmed N=G by the
    # backtrack itself. A_n is normal in S_n — guards that path.
    rec(n := 7,
        gens := GeneratorsOfGroup(AlternatingGroup(7)),
        note := "IsNormal pre-check removal: A_7 normal in S_7"),

    # 2026-06: graph compression (clique / complete-multipartite gadgets)
    # is applied to the pushed orbital and block-system graphs. These
    # wreaths exercise both gadget kinds (within-block cliques, between-
    # block multipartite); the C_10 example is the symmetry-safety
    # counterexample — regular, so its orbital graphs are matchings that
    # MUST be left uncompressed (compressing them would be wrong).
    rec(n := 25,
        gens := GeneratorsOfGroup(WreathProduct(
            SymmetricGroup(5), SymmetricGroup(5))),
        note := "graph compression on S_5 wr S_5 (clique + multipartite)"),
    rec(n := 10,
        gens := [(1,2,3,4,5)(6,7,8,9,10), (1,6)(2,7)(3,8)(4,9)(5,10)],
        note := "compression must leave C_10's matching orbital graphs alone")
];

RunBank_regression := function(mode)
    local entry, G;
    BankResetStats();
    Print(StringFormatted("[regression] {} entries\n", Length(RegressionEntries)));
    for entry in RegressionEntries do
        G := Group(entry.gens);
        BankCompareNormaliser(entry.n, G);
    od;
    BankReportStats("regression");
    return _BankStats.fail = 0;
end;
