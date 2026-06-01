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

# Pull in BankShiftPerm + BankDisjointDirectProduct + the subdirect
# mixer (BankBuildSubdirectMixer) so we can build "messy" intransitive
# inputs the same way the bank tests do.
if not IsBoundGlobal("BankShiftPerm") then
    Read("tst/bank/helpers.g");
fi;
if not IsBoundGlobal("BankBuildSubdirectMixer") then
    Read("tst/bank/subdirect.g");
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
    local G, refiner, t, vgroup, stats, ms;
    G := Group(gens);
    refiner := GB_Con.(Concatenation("Normaliser", variant))(G);
    t := NanosecondsSinceEpoch();
    vgroup := VoleFind.Group(SymmetricGroup(n), refiner);
    stats := _Vole.LastStats;
    ms := Int((NanosecondsSinceEpoch() - t) / 1000000);
    return rec(
        ms := ms,
        size := Size(vgroup),
        nodes := stats.search_nodes,
        refiner_calls := stats.refiner_calls);
end;

# Wrapper-level backend: uses the Vole.Normalizer wrapper machinery so
# the outer reduction is exercised. Refiner inside is the default
# (Orbital). Backend name in CSV: "wrap:<wrapperName>".
_HuntChildWrapper := function(gens, n, wrapperName)
    local G, t, N, ms;
    G := Group(gens);
    t := NanosecondsSinceEpoch();
    N := Vole.Normalizer(SymmetricGroup(n), G : wrapper := wrapperName);
    ms := Int((NanosecondsSinceEpoch() - t) / 1000000);
    return rec(
        ms := ms,
        size := Size(N),
        nodes := -1,
        refiner_calls := -1);
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
    for spec in [[2, 11], [2, 13], [2, 17], [2, 19], [2, 23], [2, 25],
                 [2, 27], [2, 29], [2, 31], [2, 32], [2, 37], [2, 41],
                 [2, 43], [2, 47]] do
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

# Larger AGL families — AGL(1, p) for p up to ~200, AGL(d, p) for
# bigger (d, p). The 1-d AGL family is solvable so GAP can be slow if
# it falls into a fittingfree branch.
_HuntBuildBigAGL := function()
    local out, primes, p, G, n, NrPrim, d, spec;
    out := [];
    primes := [53, 59, 61, 67, 71, 73, 79, 83, 89, 97,
               101, 103, 107, 109, 113, 127];
    for p in primes do
        NrPrim := NrPrimitiveGroups(p);
        G := First(List([1 .. NrPrim], i -> PrimitiveGroup(p, i)),
                   H -> Size(H) = p * (p - 1));
        if G = fail then continue; fi;
        Add(out, rec(
            category := "big_AGL_1_p",
            name := Concatenation("AGL(1;", String(p), ")"),
            n := p,
            G := G));
    od;
    # AGL(d, p) for larger (d, p) — these are bigger primitive groups,
    # 2-transitive, often nontrivial.
    for spec in [[2, 7], [2, 11], [2, 13],
                 [3, 3], [3, 5],
                 [4, 3], [5, 2], [6, 2]] do
        d := spec[1]; p := spec[2]; n := p ^ d;
        G := First(List([1 .. NrPrimitiveGroups(n)], i -> PrimitiveGroup(n, i)),
                   H -> HasSize(H) and Size(H) = n * Size(GL(d, p)));
        if G = fail then continue; fi;
        Add(out, rec(
            category := "big_AGL_d_p",
            name := Concatenation("AGL(", String(d), ";", String(p), ")"),
            n := n,
            G := G));
    od;
    return out;
end;

# Mathieu groups — sporadic almost-simple primitive on larger
# point-sets. M_22 to M_24 in their natural actions.
_HuntBuildBigMathieu := function()
    local out, spec, G, name, n;
    out := [];
    for spec in [[22, "M_22"], [23, "M_23"], [24, "M_24"]] do
        n := spec[1]; name := spec[2];
        G := MathieuGroup(n);
        Add(out, rec(
            category := "big_mathieu",
            name := name,
            n := n,
            G := G));
    od;
    return out;
end;

# Larger primitive groups by degree — sample from the primitive
# library between 21 and 50, every third entry. Skip the huge orders
# (S_n / A_n at top indices) and the trivial cases.
_HuntBuildBigPrimitive := function()
    local out, n, num, k, G, name;
    out := [];
    for n in [21, 22, 24, 25, 27, 28, 32, 36, 45, 49] do
        num := NrPrimitiveGroups(n);
        for k in [1, 1 + QuoInt(num, 5), 1 + QuoInt(2 * num, 5),
                  1 + QuoInt(3 * num, 5), 1 + QuoInt(4 * num, 5), num] do
            if k < 1 or k > num then continue; fi;
            G := PrimitiveGroup(n, k);
            if Size(G) > 10 ^ 9 then continue; fi;
            # Skip A_n and S_n themselves (always normalised trivially).
            if Size(G) >= Factorial(n) / 2 then continue; fi;
            name := Concatenation("PrimGrp(", String(n), ";", String(k), ")");
            Add(out, rec(
                category := "big_primitive",
                name := name,
                n := n,
                G := G));
        od;
    od;
    return out;
end;

# Subdirect mixer: build "messy" intransitive groups by sampling
# random elements from disjoint direct products of larger transitives,
# rejecting candidates that Vole.DDPD says are pure direct products
# (Length(DDPD) = number of base orbits). The user's recipe: 4-5
# orbits, base groups bigger than C_p, and verify non-trivial glueing
# via DDPD.
#
# Dihedral-heavy base list because dihedrals have rich quotient
# structure (Z_2 and Z_d quotients) and reliably give subdirect (not
# direct) mixers — sampled empirically ~100% glue rate.
_HuntBuildSubdirectMixer := function()
    local out, rs, specs, idx, spec, mixer, n_total, name;
    rs := RandomSource(IsMersenneTwister, 20260518);
    specs := [
        # Two orbits
        [[DihedralGroup(IsPermGroup, 10), DihedralGroup(IsPermGroup, 10)],
         3, "D10x2"],
        [[DihedralGroup(IsPermGroup, 14), DihedralGroup(IsPermGroup, 14)],
         3, "D14x2"],
        [[SymmetricGroup(5), SymmetricGroup(5)], 3, "S5x2"],
        # Three orbits
        [[DihedralGroup(IsPermGroup, 8), DihedralGroup(IsPermGroup, 8),
          DihedralGroup(IsPermGroup, 8)], 3, "D8x3"],
        [[DihedralGroup(IsPermGroup, 12), DihedralGroup(IsPermGroup, 12),
          DihedralGroup(IsPermGroup, 12)], 4, "D12x3"],
        [[CyclicGroup(IsPermGroup, 7), CyclicGroup(IsPermGroup, 7),
          CyclicGroup(IsPermGroup, 7)], 2, "C7x3"],
        # Four orbits
        [[DihedralGroup(IsPermGroup, 8), DihedralGroup(IsPermGroup, 8),
          DihedralGroup(IsPermGroup, 8), DihedralGroup(IsPermGroup, 8)],
         4, "D8x4"],
        [[DihedralGroup(IsPermGroup, 12), DihedralGroup(IsPermGroup, 12),
          DihedralGroup(IsPermGroup, 12), DihedralGroup(IsPermGroup, 12)],
         5, "D12x4"],
        [[SymmetricGroup(4), SymmetricGroup(4),
          SymmetricGroup(4), SymmetricGroup(4)], 5, "S4x4"],
        # Five orbits
        [[DihedralGroup(IsPermGroup, 8), DihedralGroup(IsPermGroup, 8),
          DihedralGroup(IsPermGroup, 8), DihedralGroup(IsPermGroup, 8),
          DihedralGroup(IsPermGroup, 8)], 5, "D8x5"],
        [[DihedralGroup(IsPermGroup, 10), DihedralGroup(IsPermGroup, 10),
          DihedralGroup(IsPermGroup, 10), DihedralGroup(IsPermGroup, 10),
          DihedralGroup(IsPermGroup, 10)], 6, "D10x5"]
    ];
    out := [];
    for idx in [1 .. Length(specs)] do
        spec := specs[idx];
        n_total := Sum(spec[1], LargestMovedPoint);
        mixer := BankBuildSubdirectMixer(rs, spec[1], spec[2],
                                         Length(spec[1]) - 1, 40);
        if mixer = fail then continue; fi;
        Add(out, rec(
            category := "subdirect_mixer",
            name := spec[3],
            n := n_total,
            G := mixer.group));
    od;
    return out;
end;

# Deeper wreath products: imprimitive wreath at larger total degree.
_HuntBuildBigWreathDeep := function()
    local out, spec, inner, outer, G, n, name;
    out := [];
    for spec in [[SymmetricGroup(5), SymmetricGroup(5), "S_5wrS_5", 25],
                 [SymmetricGroup(6), SymmetricGroup(4), "S_6wrS_4", 24],
                 [SymmetricGroup(4), SymmetricGroup(6), "S_4wrS_6", 24],
                 [SymmetricGroup(3), SymmetricGroup(8), "S_3wrS_8", 24],
                 [CyclicGroup(IsPermGroup, 5), SymmetricGroup(5),
                      "C_5wrS_5", 25],
                 [CyclicGroup(IsPermGroup, 7), SymmetricGroup(4),
                      "C_7wrS_4", 28],
                 [CyclicGroup(IsPermGroup, 11), SymmetricGroup(3),
                      "C_11wrS_3", 33],
                 [SymmetricGroup(7), SymmetricGroup(3), "S_7wrS_3", 21],
                 [SymmetricGroup(5), SymmetricGroup(6), "S_5wrS_6", 30]] do
        G := WreathProduct(spec[1], spec[2]);
        Add(out, rec(
            category := "big_wreath_deep",
            name := spec[3],
            n := spec[4],
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
        # Backend strings starting with "wrap:" exercise the Vole.Normalizer
        # wrapper machinery. Everything else is a refiner-variant name.
        if StartsWith(b, "wrap:") then
            raw := IO_CallWithTimeout(timeoutRec, _HuntChildWrapper,
                                      gens, n, b{[6 .. Length(b)]});
        else
            raw := IO_CallWithTimeout(timeoutRec, _HuntChildVole, gens, n, b);
        fi;
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

# Mathieu / sporadic almost-simple primitive families.
_HuntBuildMathieu := function()
    local out, specs, spec, G, n, name;
    out := [];
    # MathieuGroup(d) for d ∈ {10, 11, 12, 22, 23, 24} gives the natural
    # action of M_d on d points. M_10 = A_6.2 etc. — interesting "almost
    # simple" cases.
    for spec in [[10, "M_10"], [11, "M_11"], [12, "M_12"]] do
        n := spec[1]; name := spec[2];
        G := MathieuGroup(n);
        Add(out, rec(
            category := "mathieu",
            name := name,
            n := n,
            G := G));
    od;
    return out;
end;

# PGL / PΓL on the projective line. PGL(2, q) acts on q+1 points; ΓL
# adds field automorphisms when q is a prime power.
_HuntBuildPGL := function()
    local out, specs, spec, q, G, n, name;
    out := [];
    for spec in [[2, 8], [2, 9], [2, 11], [2, 16], [2, 17], [2, 19],
                 [2, 23], [2, 25], [2, 27]] do
        q := spec[2];
        n := q + 1;
        G := PGL(2, q);
        name := Concatenation("PGL(2;", String(q), ")");
        Add(out, rec(
            category := "PGL_2_q",
            name := name,
            n := n,
            G := G));
    od;
    return out;
end;

# Wreath products at larger degree — exercises the "many large blocks"
# corner.
_HuntBuildBigWreath := function()
    local out, specs, spec, G, n, name;
    out := [];
    for spec in [[SymmetricGroup(4), SymmetricGroup(3), "S_4wrS_3", 12],
                 [SymmetricGroup(5), SymmetricGroup(2), "S_5wrS_2", 10],
                 [SymmetricGroup(5), SymmetricGroup(3), "S_5wrS_3", 15],
                 [SymmetricGroup(4), SymmetricGroup(4), "S_4wrS_4", 16],
                 [SymmetricGroup(3), SymmetricGroup(5), "S_3wrS_5", 15],
                 [CyclicGroup(IsPermGroup, 4), SymmetricGroup(4),
                      "C_4wrS_4", 16]] do
        G := WreathProduct(spec[1], spec[2]);
        Add(out, rec(
            category := "big_wreath",
            name := spec[3],
            n := spec[4],
            G := G));
    od;
    return out;
end;

# Inhomogeneous direct products targeting the ByOrbits wrapper.
_HuntBuildInhomogeneous := function()
    local out, a, b, gens, base, i, k, name;
    out := [];
    # C_3^a × S_3^b, a + b ∈ {3, 4, 5, 6}.
    for a in [1, 2, 3] do
        for b in [1, 2, 3] do
            if a + b < 3 or a + b > 6 then continue; fi;
            gens := [];
            for i in [1 .. a] do
                base := 3*(i-1);
                Add(gens, CycleFromList([base+1, base+2, base+3]));
            od;
            for i in [1 .. b] do
                base := 3*(a + i - 1);
                Add(gens, CycleFromList([base+1, base+2, base+3]));
                Add(gens, (base+1, base+2));
            od;
            name := Concatenation("C_3^", String(a),
                                  "_x_S_3^", String(b));
            Add(out, rec(
                category := "inhomogeneous",
                name := name,
                n := 3*(a + b),
                G := Group(gens)));
        od;
    od;
    return out;
end;

# Large transitive groups via TransGrp library at degrees where there's
# a non-trivial bottleneck.
_HuntBuildTransGrpHard := function()
    local out, specs, spec, n, k, G, name;
    out := [];
    # Hand-picked "interesting" entries — solvable, primitive, and high-
    # symmetry transitive groups at modest degree.
    for spec in [[12, 1], [12, 50], [12, 100], [12, 200],
                 [14, 1], [14, 5], [14, 10],
                 [15, 50], [15, 100],
                 [16, 100], [16, 500],
                 [18, 100], [18, 500], [18, 800]] do
        n := spec[1]; k := spec[2];
        if NrTransitiveGroups(n) < k then continue; fi;
        G := TransitiveGroup(n, k);
        name := Concatenation("TransGrp(", String(n), ";",
                              String(k), ")");
        Add(out, rec(
            category := "transgrp_hard",
            name := name,
            n := n,
            G := G));
    od;
    return out;
end;

RunHunt := function(budget_per_call_secs)
    local path, t0, allSpecs, backends, spec, total_ms;
    path := "tst/benchmarks/hunt.csv";
    _HuntCsvHeader(path);

    # Refiner variants and wrapper variants in one list. The driver
    # dispatches on the "wrap:" prefix.
    backends := ["gap",
                 "Orbital", "OrbitalRegOrbit", "OrbitalRegOrbitChar",
                 "OrbitalSmall", "OrbitalDeep",
                 "wrap:direct", "wrap:ByOrbits"];

    allSpecs := [];
    Append(allSpecs, _HuntBuildCyclicRegular());
    Append(allSpecs, _HuntBuildElemAbelianRegular());
    Append(allSpecs, _HuntBuildIntransitive());
    Append(allSpecs, _HuntBuildInhomogeneous());
    Append(allSpecs, _HuntBuildAGL1());
    Append(allSpecs, _HuntBuildAGLmd());
    Append(allSpecs, _HuntBuildPSL());
    Append(allSpecs, _HuntBuildPGL());
    Append(allSpecs, _HuntBuildMathieu());
    Append(allSpecs, _HuntBuildWreath());
    Append(allSpecs, _HuntBuildBigWreath());
    Append(allSpecs, _HuntBuildTransGrpHard());
    # Bigger families — built specifically so GAP itself takes 100ms+
    # per instance, so Vole's startup overhead (Rust process + JSON IPC)
    # doesn't dominate the comparison.
    Append(allSpecs, _HuntBuildBigAGL());
    Append(allSpecs, _HuntBuildBigMathieu());
    Append(allSpecs, _HuntBuildBigPrimitive());
    Append(allSpecs, _HuntBuildBigWreathDeep());
    Append(allSpecs, _HuntBuildSubdirectMixer());

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
