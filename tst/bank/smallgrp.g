# SmallGroups sweep: for each abstract group of small order, build a
# faithful permutation representation via IsomorphismPermGroup and check
# normalisers against GAP.
#
# Note: most small groups appear in their regular action via
# IsomorphismPermGroup, so coverage overlaps heavily with transgrp.
# Where this bank source is uniquely useful is the (relatively few)
# groups whose smallest faithful action has a smaller degree than the
# group order. We therefore skip any group whose perm degree exceeds
# the bank's overall degree cap — they would either be redundant with
# transgrp or simply too big for current Vole.

if not IsBoundGlobal("BankCompareNormaliser") then
    Read("tst/bank/helpers.g");
fi;

# Cap on abstract group order; perm degree is separately bounded by
# BankDegreeCap(mode).
BankSmallGrpOrderCap := function(mode)
    if mode = "quick" then
        return 24;
    elif mode = "nightly" then
        return 64;
    elif mode = "full" then
        return 128;
    else
        Error("BankSmallGrpOrderCap: unknown mode ", mode);
    fi;
end;

# Orders where SmallGroups has a huge number of groups; skip in
# quick/nightly to stay within budget.
_BankSmallGrpHeavyOrders := [64, 96, 128, 192, 256, 384, 512, 576, 640, 729,
                              768, 864, 972, 1024, 1152, 1280, 1296, 1536,
                              1728, 1792, 1944];

RunBank_smallgrp := function(mode)
    local order_cap, degree_cap, ord, k, n_grps, G, P, deg, considered;
    order_cap := BankSmallGrpOrderCap(mode);
    degree_cap := BankDegreeCap(mode);
    BankResetStats();
    considered := 0;
    Print(StringFormatted(
        "[smallgrp] mode={}, order cap={}, perm degree cap={}\n",
        mode, order_cap, degree_cap));
    for ord in [2 .. order_cap] do
        if mode <> "full" and ord in _BankSmallGrpHeavyOrders then
            _BankStats.skipped := _BankStats.skipped + NumberSmallGroups(ord);
            continue;
        fi;
        n_grps := NumberSmallGroups(ord);
        for k in [1 .. n_grps] do
            considered := considered + 1;
            G := SmallGroup(ord, k);
            P := Image(IsomorphismPermGroup(G));
            deg := LargestMovedPoint(P);
            if deg = 0 then
                # Trivial group; skip.
                _BankStats.skipped := _BankStats.skipped + 1;
            elif deg > degree_cap then
                _BankStats.skipped := _BankStats.skipped + 1;
            else
                BankCompareNormaliser(deg, P);
            fi;
        od;
    od;
    Print(StringFormatted("[smallgrp] considered={}, ", considered));
    BankReportStats("smallgrp");
    return _BankStats.fail = 0;
end;
