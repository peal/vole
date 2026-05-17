# Loss-hunt benchmark: where do we lose to GAP by a *lot*, and why?
#
# Each instance is run under both GAP and Vole (multiple variants), with
# IO_CallWithTimeout enforcing a per-call wall-clock budget. The forked
# child measures its own wall time and IO_Pickles a small result record;
# the parent emits one CSV row per (instance, backend) and flushes after
# each. This way a hang times out and the run continues.
#
# CSV columns:
#   category, name, n, size, backend, ms, nodes, refiner_calls,
#   eq_gap, status
#
# status: "ok" | "timeout" | "crash" | "wrong"
# `size` is filled from GAP on the gap row; for vole rows it is the
# size of the returned subgroup (cross-check). nodes/refiner_calls
# are -1 for the gap backend.

if not IsBoundGlobal("IO_CallWithTimeout") then
    LoadPackage("io", false);
fi;

# ─── Child entry points ─────────────────────────────────────────────
# These run inside the forked child. They take perm generators (a list)
# and the degree n, build the group locally, do the timed work, and
# return rec(ms, size, [nodes], [refiner_calls]).

_HuntChildGap := function(gens, n)
    local G, t, N, ms;
    G := Group(gens);
    t := NanosecondsSinceEpoch();
    N := Normalizer(SymmetricGroup(n), G);
    ms := Int((NanosecondsSinceEpoch() - t) / 1000000);
    return rec(ms := ms, size := Size(N));
end;

_HuntChildVole := function(gens, n, variant)
    local G, refiner, t, ret, ms;
    G := Group(gens);
    refiner := GB_Con.(Concatenation("Normaliser", variant))(G);
    t := NanosecondsSinceEpoch();
    ret := VoleFind.Group(SymmetricGroup(n), refiner : raw := true);
    ms := Int((NanosecondsSinceEpoch() - t) / 1000000);
    return rec(
        ms := ms,
        size := Size(ret.group),
        nodes := ret.raw.stats.search_nodes,
        refiner_calls := ret.raw.stats.refiner_calls);
end;

# ─── Family builders ────────────────────────────────────────────────
# Each builder is parent-side: build G, return a list of records
# rec(category, name, n, G).

_HuntBuildCyclicRegular := function()
    local out, primes, p;
    out := [];
    primes := [29, 31, 37, 41, 43, 47, 53, 59, 61];
    for p in primes do
        Add(out, rec(
            category := "cyclic_regular",
            # Names use semicolon (not comma) so they don't collide
            # with CSV field separators.
            name := Concatenation("C_", String(p)),
            n := p,
            G := Group([CycleFromList([1 .. p])])));
    od;
    return out;
end;

# Cayley (right-regular) action of an abstract group.
_HuntCayley := function(absG)
    local elts;
    elts := AsList(absG);
    return Action(absG, elts, OnRight);
end;

_HuntBuildElemAbelianRegular := function()
    local out, spec, name, dims, p, k, absG, regG;
    out := [];
    # (Z_p)^k acting regularly on p^k points. Excludes p^k > 64 so the
    # construction doesn't take all day.
    for spec in [[2, 3], [2, 4], [2, 5], [2, 6], [3, 2], [3, 3], [3, 4],
                 [5, 2], [7, 2]] do
        p := spec[1]; k := spec[2];
        absG := AbelianGroup(IsPcGroup, ListWithIdenticalEntries(k, p));
        regG := _HuntCayley(absG);
        name := Concatenation("Z_", String(p), "^", String(k), "_reg");
        Add(out, rec(
            category := "elem_ab_regular",
            name := name,
            n := p ^ k,
            G := regG));
    od;
    return out;
end;

_HuntShiftPerm := function(p, shift)
    local lmp, sigma;
    lmp := LargestMovedPoint(p);
    if lmp = 0 then return (); fi;
    sigma := MappingPermListList([1 .. lmp], [shift + 1 .. shift + lmp]);
    return p ^ sigma;
end;

_HuntDirectProduct := function(groups)
    local gens, shift, G, g;
    gens := [];
    shift := 0;
    for G in groups do
        for g in GeneratorsOfGroup(G) do
            Add(gens, _HuntShiftPerm(g, shift));
        od;
        shift := shift + LargestMovedPoint(G);
    od;
    return Group(gens);
end;

_HuntBuildIntransitive := function()
    local out, k, copies;
    out := [];
    # (C_3)^k as a direct product of regular C_3s — k disjoint orbits
    # of length 3. Tests the per-orbit reduction that Phase E will add.
    for k in [3, 4, 5, 6, 8, 10] do
        copies := ListWithIdenticalEntries(k, CyclicGroup(IsPermGroup, 3));
        Add(out, rec(
            category := "intransitive_C3",
            name := Concatenation("(C_3)^", String(k), "_int"),
            n := 3 * k,
            G := _HuntDirectProduct(copies)));
    od;
    # k disjoint copies of S_3.
    for k in [3, 4, 5, 6] do
        copies := ListWithIdenticalEntries(k, SymmetricGroup(3));
        Add(out, rec(
            category := "intransitive_S3",
            name := Concatenation("(S_3)^", String(k), "_int"),
            n := 3 * k,
            G := _HuntDirectProduct(copies)));
    od;
    return out;
end;

_HuntBuildAGL1 := function()
    local out, primes, p, G;
    out := [];
    primes := [17, 19, 23, 29, 31, 37, 41, 43, 47];
    for p in primes do
        # Built as PrimitiveGroup(p, k) where k indexes AGL(1, p); for
        # prime p the AGL(1, p) is typically the largest solvable
        # primitive — use the last index whose order is p*(p-1).
        G := PrimitiveGroup(p, NrPrimitiveGroups(p));
        # On prime degree, NrPrimitiveGroups(p) tends to be S_p; step
        # back to find AGL(1, p) by checking order.
        if Size(G) <> p * (p - 1) then
            G := First(List([1 .. NrPrimitiveGroups(p)], i -> PrimitiveGroup(p, i)),
                       H -> Size(H) = p * (p - 1));
        fi;
        if G = fail then continue; fi;
        Add(out, rec(
            category := "AGL_1_p",
            name := Concatenation("AGL(1;", String(p), ")"),
            n := p,
            G := G));
    od;
    return out;
end;

_HuntBuildAGLmd := function()
    local out, specs, spec, d, p, n, G;
    out := [];
    # AGL(d, p) primitive on p^d points. Indices vary by degree; pick by
    # order = p^d * |GL(d, p)|.
    for spec in [[2, 3], [3, 2], [2, 5], [4, 2], [3, 3]] do
        d := spec[1]; p := spec[2]; n := p ^ d;
        G := First(List([1 .. NrPrimitiveGroups(n)], i -> PrimitiveGroup(n, i)),
                   H -> HasSize(H) and Size(H) = n * Size(GL(d, p)));
        if G = fail then
            # Some degrees expose AGL via a different name; skip if not
            # found rather than fabricate.
            continue;
        fi;
        Add(out, rec(
            category := "AGL_d_p",
            name := Concatenation("AGL(", String(d), ";", String(p), ")"),
            n := n,
            G := G));
    od;
    return out;
end;

_HuntBuildPSL := function()
    local out, specs, spec, q, G, n;
    out := [];
    for spec in [[2, 11], [2, 13], [2, 17], [2, 19], [2, 23], [2, 25]] do
        q := spec[2];
        G := PSL(2, q);
        n := q + 1;
        Add(out, rec(
            category := "PSL_2_q",
            name := Concatenation("PSL(2;", String(q), ")"),
            n := n,
            G := G));
    od;
    return out;
end;

_HuntBuildWreath := function()
    local out, specs, spec, inner, outer, G, n;
    out := [];
    for spec in [[SymmetricGroup(2), SymmetricGroup(3), "S_2wrS_3", 6],
                 [SymmetricGroup(2), SymmetricGroup(4), "S_2wrS_4", 8],
                 [SymmetricGroup(3), SymmetricGroup(2), "S_3wrS_2", 6],
                 [SymmetricGroup(3), SymmetricGroup(3), "S_3wrS_3", 9],
                 [SymmetricGroup(3), SymmetricGroup(4), "S_3wrS_4", 12],
                 [CyclicGroup(IsPermGroup, 5), SymmetricGroup(3),
                      "C_5wrS_3", 15]] do
        inner := spec[1]; outer := spec[2];
        # Imprimitive wreath product: blocks act by `inner`, outer
        # permutes the blocks.
        G := WreathProduct(inner, outer);
        Add(out, rec(
            category := "wreath",
            name := spec[3],
            n := spec[4],
            G := G));
    od;
    return out;
end;

# ─── Driver ─────────────────────────────────────────────────────────

# PrintTo(filename, ...) truncates; AppendTo(filename, ...) opens-write-
# closes each call, so the CSV is durable after every row.

_HuntCsvHeader := function(path)
    PrintTo(path,
        "category,name,n,size,backend,ms,nodes,refiner_calls,",
        "eq_gap,status\n");
end;

_HuntCsvRow := function(path, category, name, n, size, backend, ms,
                        nodes, refiner_calls, eq_gap, status)
    AppendTo(path, StringFormatted(
        "{},{},{},{},{},{},{},{},{},{}\n",
        category, name, n, size, backend, ms, nodes, refiner_calls,
        eq_gap, status));
end;

# Run one instance across all backends.
RunHuntInstance := function(spec, backends, budget, path)
    local gens, n, name, category, timeoutRec, raw, b,
          eq, sz, status, refSize;
    gens := GeneratorsOfGroup(spec.G);
    n := spec.n;
    name := spec.name;
    category := spec.category;
    timeoutRec := rec(seconds := budget);
    Print("# ", category, "/", name, " (n=", n, ")\n");

    # Always run GAP first so we have a reference size.
    refSize := -1;
    if "gap" in backends then
        raw := IO_CallWithTimeout(timeoutRec, _HuntChildGap, gens, n);
        if Length(raw) >= 2 and raw[1] = true then
            refSize := raw[2].size;
            _HuntCsvRow(path, category, name, n, raw[2].size,
                "gap", raw[2].ms, -1, -1, "true", "ok");
            Print("    gap     ", raw[2].ms, "ms |N|=", raw[2].size, "\n");
        elif Length(raw) >= 1 and raw[1] = false then
            _HuntCsvRow(path, category, name, n, -1,
                "gap", -1, -1, -1, "false", "timeout");
            Print("    gap     TIMEOUT\n");
        else
            _HuntCsvRow(path, category, name, n, -1,
                "gap", -1, -1, -1, "false", "crash");
            Print("    gap     CRASH\n");
        fi;
    fi;

    for b in backends do
        if b = "gap" then continue; fi;
        raw := IO_CallWithTimeout(timeoutRec, _HuntChildVole, gens, n, b);
        if Length(raw) >= 2 and raw[1] = true then
            sz := raw[2].size;
            eq := refSize = -1 or sz = refSize;
            if eq then status := "ok"; else status := "wrong"; fi;
            _HuntCsvRow(path, category, name, n, sz, b,
                raw[2].ms, raw[2].nodes, raw[2].refiner_calls,
                String(eq), status);
            Print("    ", b, "  ", raw[2].ms, "ms nodes=",
                  raw[2].nodes, " calls=", raw[2].refiner_calls,
                  " |N|=", sz, "\n");
        elif Length(raw) >= 1 and raw[1] = false then
            _HuntCsvRow(path, category, name, n, -1, b,
                -1, -1, -1, "false", "timeout");
            Print("    ", b, "  TIMEOUT\n");
        else
            _HuntCsvRow(path, category, name, n, -1, b,
                -1, -1, -1, "false", "crash");
            Print("    ", b, "  CRASH\n");
        fi;
    od;
end;

RunHunt := function(budget_per_call_secs)
    local path, t0, allSpecs, backends, spec, total_ms;
    path := "tst/benchmarks/hunt.csv";
    _HuntCsvHeader(path);

    backends := ["gap", "Orbital", "OrbitalRegOrbit", "OrbitalSmall",
                 "OrbitalDeep"];

    allSpecs := [];
    Append(allSpecs, _HuntBuildCyclicRegular());
    Append(allSpecs, _HuntBuildElemAbelianRegular());
    Append(allSpecs, _HuntBuildIntransitive());
    Append(allSpecs, _HuntBuildAGL1());
    Append(allSpecs, _HuntBuildAGLmd());
    Append(allSpecs, _HuntBuildPSL());
    Append(allSpecs, _HuntBuildWreath());

    Print("# ", Length(allSpecs), " instances; budget=",
          budget_per_call_secs, "s/call; backends=", backends, "\n");
    t0 := NanosecondsSinceEpoch();
    for spec in allSpecs do
        RunHuntInstance(spec, backends, budget_per_call_secs, path);
    od;
    total_ms := Int((NanosecondsSinceEpoch() - t0) / 1000000);
    Print("# Total wall: ", total_ms, "ms\n");
    Print("# CSV: ", path, "\n");
end;
