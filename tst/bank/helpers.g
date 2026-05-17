# Bank helpers — correctness comparison against GAP as source of truth.

if not IsBoundGlobal("_BankStats") then
    BindGlobal("_BankStats", rec(pass := 0, fail := 0, skipped := 0,
                                 known_hangs := 0, failures := []));
fi;

# Known-hang skip list. See known_hangs.g for the entries.
Read("tst/bank/known_hangs.g");

# Compare Vole.Normalizer(SymmetricGroup(n), G) with Normalizer(SymmetricGroup(n), G).
# n must be at least LargestMovedPoint(G).
BankCompareNormaliser := function(n, G)
    local vresult, gresult, info;
    Assert(0, LargestMovedPoint(G) <= n);
    vresult := Vole.Normalizer(SymmetricGroup(n), G);
    gresult := Normalizer(SymmetricGroup(n), G);
    if vresult = gresult then
        _BankStats.pass := _BankStats.pass + 1;
        return true;
    fi;
    _BankStats.fail := _BankStats.fail + 1;
    info := rec(
        degree := n,
        input_gens := GeneratorsOfGroup(G),
        gap_size := Size(gresult),
        vole_size := Size(vresult),
        gap_gens := GeneratorsOfGroup(gresult),
        vole_gens := GeneratorsOfGroup(vresult));
    Add(_BankStats.failures, info);
    Print(StringFormatted(
        "FAIL (bank): n={}, |G|={}, |Vole N|={}, |GAP N|={}, gens={}\n",
        n, Size(G), info.vole_size, info.gap_size, info.input_gens));
    return false;
end;

# Same idea but for Normalizer(G_outer, G_inner). Used for non-S_n outer groups.
BankCompareNormaliserInGroup := function(G_outer, G_inner)
    local vresult, gresult, info, n;
    n := LargestMovedPoint(G_outer);
    vresult := Vole.Normalizer(G_outer, G_inner);
    gresult := Normalizer(G_outer, G_inner);
    if vresult = gresult then
        _BankStats.pass := _BankStats.pass + 1;
        return true;
    fi;
    _BankStats.fail := _BankStats.fail + 1;
    info := rec(
        outer_gens := GeneratorsOfGroup(G_outer),
        inner_gens := GeneratorsOfGroup(G_inner),
        gap_size := Size(gresult),
        vole_size := Size(vresult));
    Add(_BankStats.failures, info);
    Print(StringFormatted(
        "FAIL (bank): outer |G|={}, inner |H|={}, |Vole N|={}, |GAP N|={}\n",
        Size(G_outer), Size(G_inner), info.vole_size, info.gap_size));
    return false;
end;

BankResetStats := function()
    _BankStats.pass := 0;
    _BankStats.fail := 0;
    _BankStats.skipped := 0;
    _BankStats.known_hangs := 0;
    _BankStats.failures := [];
end;

BankReportStats := function(label)
    Print(StringFormatted(
        "[{}] pass={}, fail={}, skipped={}, known_hangs={}\n",
        label, _BankStats.pass, _BankStats.fail,
        _BankStats.skipped, _BankStats.known_hangs));
    if _BankStats.fail > 0 then
        Print(StringFormatted("[{}] FIRST FAILURE: {}\n",
                              label, _BankStats.failures[1]));
    fi;
end;

# Check before testing an input: if it's on the known-hang list, count it
# and skip. Returns true iff caller should proceed with the actual test.
BankShouldRun := function(source, key)
    local entry;
    entry := BankIsKnownHang(source, key);
    if entry <> fail then
        _BankStats.known_hangs := _BankStats.known_hangs + 1;
        return false;
    fi;
    return true;
end;

# Degree caps per mode. Initial values are tight because today's
# Vole.Normalizer is much weaker than GAP; each phase that improves
# Vole raises these.
BankDegreeCap := function(mode)
    # Caps bumped over time as Vole improves. Phase A (orbital-graph set
    # widget) unblocked C_p for prime p in regular action, which was the
    # binding constraint at degrees 11/13.
    if mode = "quick" then
        return 12;
    elif mode = "nightly" then
        return 16;
    elif mode = "full" then
        return 22;
    else
        Error("BankDegreeCap: unknown mode ", mode);
    fi;
end;

# Per-input wall-time cap (ms). Stops a degenerate group from hanging
# the whole bank. Quick mode is strict; nightly/full are relaxed.
BankTimeCapMs := function(mode)
    if mode = "quick" then
        return 2000;     # 2 s per group
    elif mode = "nightly" then
        return 30000;    # 30 s
    elif mode = "full" then
        return 600000;   # 10 min
    else
        Error("BankTimeCapMs: unknown mode ", mode);
    fi;
end;
