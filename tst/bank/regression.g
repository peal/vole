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
        note := "partitionByKey record-name overflow on 26-vertex canonical form")
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
