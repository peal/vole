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

# Canonical-image-of-group consistency. For a group G ≤ S_n and a perm
# pi ∈ S_n, the canonical image must be the same for G and G^pi (since
# they are conjugate in S_n). We do `num_conjugates` random conjugates
# from a seeded RandomSource so failures are reproducible.
#
# Optional `variantName` (default "Orbital"): a named refiner variant
# in GB_Con (e.g. "OrbitalRegOrbit"). When given, both canonicals are
# computed via `GB_Con.Normaliser<variant>(...)` rather than the default
# dispatch from Constraint.Normalise — lets the bank exercise each
# variant independently.
BankCompareCanonicalGroup := function(n, G, rs, num_conjugates, variantName)
    local refinerFn, baseCanon, k, pi, Gp, canon, info, computeCanonical;
    if variantName = fail or variantName = "default" then
        computeCanonical := function(U)
            return Vole.CanonicalImage(SymmetricGroup(n), U, OnPoints);
        end;
    else
        refinerFn := GB_Con.(Concatenation("Normaliser", variantName));
        computeCanonical := function(U)
            local ret;
            ret := VoleFind.Canonical(SymmetricGroup(n), refinerFn(U));
            # ret.canonical is the canonicalising perm; apply it.
            return U ^ ret.canonical;
        end;
    fi;
    baseCanon := computeCanonical(G);
    for k in [1 .. num_conjugates] do
        pi := Random(rs, SymmetricGroup(n));
        Gp := G ^ pi;
        canon := computeCanonical(Gp);
        if canon <> baseCanon then
            _BankStats.fail := _BankStats.fail + 1;
            info := rec(
                degree := n,
                variant := variantName,
                input_gens := GeneratorsOfGroup(G),
                pi := pi,
                base_canon := GeneratorsOfGroup(baseCanon),
                conj_canon := GeneratorsOfGroup(canon));
            Add(_BankStats.failures, info);
            Print(StringFormatted(
                "FAIL (bank/canonical): n={}, variant={}, |G|={}, ",
                n, variantName, Size(G)));
            Print(StringFormatted(
                "pi={}, base={}, conj={}\n",
                pi, info.base_canon, info.conj_canon));
            return false;
        fi;
    od;
    _BankStats.pass := _BankStats.pass + 1;
    return true;
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

# Shift a permutation by a positive integer, so its support moves up
# by that amount. Used to place a transitive group's natural action
# at a non-trivial offset for building disjoint-supports direct
# products.
BankShiftPerm := function(p, shift)
    local lmp, sigma;
    lmp := LargestMovedPoint(p);
    if lmp = 0 then
        return ();
    fi;
    sigma := MappingPermListList([1 .. lmp], [shift + 1 .. shift + lmp]);
    return p ^ sigma;
end;

# Build the on-disjoint-supports direct product of `groups`. Each
# group acts on its standard support [1..LargestMovedPoint(group)];
# the i-th group is shifted to sit after the cumulative supports of
# groups 1..i-1.
BankDisjointDirectProduct := function(groups)
    local gens, shift, G, g;
    gens := [];
    shift := 0;
    for G in groups do
        for g in GeneratorsOfGroup(G) do
            Add(gens, BankShiftPerm(g, shift));
        od;
        shift := shift + LargestMovedPoint(G);
    od;
    if IsEmpty(gens) then
        return Group(());
    fi;
    return Group(gens);
end;
