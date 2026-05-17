# PrimitiveGroups sweep. Smaller in count than transgrp but contains the
# algorithmically harder normaliser inputs (primitive non-2-transitive
# groups, primitive affine groups, etc.).

if not IsBoundGlobal("BankCompareNormaliser") then
    Read("tst/bank/helpers.g");
fi;

RunBank_primgrp := function(mode)
    local cap, n, k, G, num;
    cap := BankDegreeCap(mode);
    BankResetStats();
    Print(StringFormatted("[primgrp] mode={}, degree cap={}\n", mode, cap));
    for n in [2 .. cap] do
        num := NrPrimitiveGroups(n);
        if num > 0 then
            Print(StringFormatted("[primgrp] n={}, NrPrimitiveGroups={}\n", n, num));
            for k in [1 .. num] do
                G := PrimitiveGroup(n, k);
                BankCompareNormaliser(n, G);
            od;
        fi;
    od;
    BankReportStats("primgrp");
    return _BankStats.fail = 0;
end;
