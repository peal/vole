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
    # (none yet — populate as bugs surface)
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
