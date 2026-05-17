# TransitiveGroups sweep: for each (n, k), Vole.Normalizer == GAP Normalizer.
# Source of truth: Normalizer(SymmetricGroup(n), TransitiveGroup(n, k)).
#
# Degree caps come from helpers.g and are tight initially. Raise per phase
# as Vole improves; the cap should be the largest degree where the bank
# completes in the mode's budget.

if not IsBoundGlobal("BankCompareNormaliser") then
    Read("tst/bank/helpers.g");
fi;

RunBank_transgrp := function(mode)
    local cap, n, k, G, num;
    cap := BankDegreeCap(mode);
    BankResetStats();
    Print(StringFormatted("[transgrp] mode={}, degree cap={}\n", mode, cap));
    for n in [2 .. cap] do
        num := NrTransitiveGroups(n);
        Print(StringFormatted("[transgrp] n={}, NrTransitiveGroups={}\n", n, num));
        for k in [1 .. num] do
            if BankShouldRun("transgrp", [n, k]) then
                G := TransitiveGroup(n, k);
                BankCompareNormaliser(n, G);
            fi;
        od;
    od;
    BankReportStats("transgrp");
    return _BankStats.fail = 0;
end;
