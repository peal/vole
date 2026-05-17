# JnP / inhomogeneous-orbit bank. Targets the ByOrbits (Chang
# L-overgroup) wrapper specifically — these are the input families
# where the wrapper is supposed to win. Every test must succeed under
# every registered wrapper, but the failure mode of interest is when
# only one wrapper happens to be correct on a particular family.
#
# Five families, in order of complexity:
#
#   (1) full-direct (C_p)^k. Phase E should compute L = N here (no
#       inner refinement). N = S_p \wr S_k.
#   (2) Chang random subdirect [CJR22, §8]. Random k/2 × k matrix
#       over F_p, rank k/2. Each row defines a generator of H via
#       σ_1^{r_1} … σ_k^{r_k}, where σ_i is the canonical p-cycle on
#       orbit i. H ≤ (C_p)^k strictly; the inner search refines L.
#   (3) inhomogeneous direct C_3^a × S_3^b. Each orbit acts as C_3
#       or S_3; ByOrbits must separate them into two perm-iso
#       classes; N permutes orbits only within a class.
#   (4) subdirect of C_3^a × S_3^b. Strict subgroup of the direct
#       product. Inner search refines L within the class structure.
#   (5) mixed-degree (C_3)^a × (C_5)^b. Orbits of different sizes
#       are automatically in different perm-iso classes (since they
#       can't be swapped by any permutation). The class-by-size
#       split is the cheapest source of separation in ByOrbits.
#
# The reference for (1) and (2) is Chang–Jefferson–Roney-Dougal
# arXiv:2112.00388 §8.

if not IsBoundGlobal("BankCompareNormaliser") then
    Read("tst/bank/helpers.g");
fi;

# Build (C_p)^k on [1..pk]: the i-th p-cycle is (p(i-1)+1, …, pi).
_BankJnPFullDirect := function(p, k)
    local gens, i;
    gens := [];
    for i in [1 .. k] do
        Add(gens, CycleFromList([p*(i-1) + 1 .. p*i]));
    od;
    return Group(gens);
end;

# Compose σ_1^{r_1} … σ_k^{r_k} on [1..pk]. σ_i is the canonical
# p-cycle on the i-th orbit; σ_i^{r_i} just shifts that orbit by r_i.
_BankJnPElementFromRow := function(p, k, row)
    local g, i, j;
    g := ();
    for i in [1 .. k] do
        if row[i] <> 0 then
            g := g * CycleFromList(List([1 .. p],
                j -> p*(i-1) + ((j - 1 + row[i]) mod p) + 1));
        fi;
    od;
    return g;
end;

# Chang's random subdirect [CJR22 §8]: pick a random k/2 × k matrix
# over F_p with full row rank and no zero column, return its row
# group. Caller supplies the RandomSource so failures are reproducible.
_BankJnPRandomSubdirect := function(p, k, rs)
    local M, half, row_field, attempts, hasZeroCol;
    Assert(0, k mod 2 = 0);
    half := QuoInt(k, 2);
    attempts := 0;
    repeat
        attempts := attempts + 1;
        if attempts > 50 then
            Error("_BankJnPRandomSubdirect: failed to sample after 50 tries");
        fi;
        M := List([1 .. half],
                  r -> List([1 .. k], j -> Random(rs, [0 .. p - 1])));
        row_field := List(M, row -> row * Z(p)^0);
        hasZeroCol := ForAny([1 .. k],
            j -> ForAll([1 .. half], r -> M[r][j] = 0));
    until RankMat(row_field) = half and not hasZeroCol;
    return Group(List(M, row -> _BankJnPElementFromRow(p, k, row)));
end;

# Direct product of a copies of C_3 then b copies of S_3, on
# [1..3(a+b)]. C_3 blocks first, S_3 blocks after.
_BankJnPC3S3Direct := function(a, b)
    local gens, i, base;
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
    return Group(gens);
end;

# Subdirect of (C_3)^a × (S_3)^b. Take the full direct product, then
# pick (a+b)/2 random subset relations among the orbits' generators
# and replace one generator with a product of two — yields a
# subgroup of strictly smaller order. We keep at least one full
# generator per orbit so the orbit support stays [1..3(a+b)].
_BankJnPC3S3Subdirect := function(a, b, rs)
    local full, k, base_gens, i, src, dst, gens, attempts, base;
    k := a + b;
    Assert(0, k >= 2);
    # Per-orbit "C_3 part" generator list — these are the order-3
    # parts we can subdirect via row-vector relations.
    base_gens := List([1 .. k], i -> CycleFromList(
        [3*(i-1)+1, 3*(i-1)+2, 3*(i-1)+3]));
    gens := [];
    # Throw in a random tying between orbits 1 and 2 (and 3 if present).
    Add(gens, base_gens[1] * base_gens[2] ^ Random(rs, [1, 2]));
    if k >= 3 then
        Add(gens, base_gens[3] * base_gens[1] ^ Random(rs, [1, 2]));
    fi;
    # Include the rest as full free generators so the orbits don't
    # collapse.
    for i in [3 .. k] do
        Add(gens, base_gens[i]);
    od;
    # Add the S_3 transpositions for the S_3-typed orbits.
    for i in [1 .. b] do
        base := 3*(a + i - 1);
        Add(gens, (base+1, base+2));
    od;
    return Group(gens);
end;

# (C_3)^a × (C_5)^b on disjoint supports. First a copies are C_3 on
# 3 points; remaining b are C_5 on 5 points.
_BankJnPMixedSizes := function(a, b)
    local gens, i, base;
    gens := [];
    for i in [1 .. a] do
        base := 3*(i-1);
        Add(gens, CycleFromList([base+1, base+2, base+3]));
    od;
    for i in [1 .. b] do
        base := 3*a + 5*(i-1);
        Add(gens, CycleFromList([base+1 .. base+5]));
    od;
    return Group(gens);
end;

# Per-wrapper comparison: each registered wrapper must agree with GAP.
# Records ONE pass/fail per (input, all-wrappers) — a single wrapper
# discrepancy fails the whole input.
_BankJnPCheckAllWrappers := function(n, H, label)
    local Ngap, wrapperName, Nvole, failed;
    Ngap := Normalizer(SymmetricGroup(n), H);
    failed := false;
    for wrapperName in RecNames(_Vole.NormalizerWrappers) do
        Nvole := Vole.Normalizer(SymmetricGroup(n), H
                                 : wrapper := wrapperName);
        if Nvole <> Ngap then
            failed := true;
            _BankStats.fail := _BankStats.fail + 1;
            Print(StringFormatted(
                "FAIL (bank/jnp): {} wrapper={} n={} |H|={} ",
                label, wrapperName, n, Size(H)));
            Print(StringFormatted(
                "|gap N|={} |vole N|={}\n",
                Size(Ngap), Size(Nvole)));
            Add(_BankStats.failures, rec(
                label := label, wrapper := wrapperName,
                degree := n,
                input_gens := GeneratorsOfGroup(H),
                gap_size := Size(Ngap),
                vole_size := Size(Nvole)));
        fi;
    od;
    if not failed then
        _BankStats.pass := _BankStats.pass + 1;
    fi;
    return not failed;
end;

# Caps per mode.
_BankJnPDegreeCap := function(mode)
    if mode = "quick" then
        return 18;
    elif mode = "nightly" then
        return 30;
    elif mode = "full" then
        return 60;
    else
        Error("_BankJnPDegreeCap: unknown mode ", mode);
    fi;
end;

RunBank_jnp := function(mode)
    local cap, p, k, a, b, H, rs, t;
    cap := _BankJnPDegreeCap(mode);
    BankResetStats();
    rs := RandomSource(IsMersenneTwister, 20260517);
    Print(StringFormatted("[jnp] mode={}, degree cap={}\n", mode, cap));

    # (1) Full direct (C_p)^k. p ∈ {2, 3, 5}, k as big as cap allows.
    for p in [2, 3, 5] do
        for k in [2 .. QuoInt(cap, p)] do
            H := _BankJnPFullDirect(p, k);
            _BankJnPCheckAllWrappers(p*k, H,
                StringFormatted("(C_{})^{}", p, k));
        od;
    od;

    # (2) Chang random subdirect, k even. Two random samples per (p, k)
    # so we exercise different matrices.
    for p in [2, 3, 5] do
        for k in [4, 6, 8] do
            if p*k > cap then continue; fi;
            for t in [1, 2] do
                H := _BankJnPRandomSubdirect(p, k, rs);
                _BankJnPCheckAllWrappers(p*k, H,
                    StringFormatted("subdirect(C_{}, k={}, t={})", p, k, t));
            od;
        od;
    od;

    # (3) Inhomogeneous C_3^a × S_3^b direct.
    for a in [1, 2, 3] do
        for b in [1, 2, 3] do
            if 3*(a + b) > cap then continue; fi;
            H := _BankJnPC3S3Direct(a, b);
            _BankJnPCheckAllWrappers(3*(a + b), H,
                StringFormatted("C_3^{} x S_3^{}", a, b));
        od;
    od;

    # (4) Subdirect of C_3^a × S_3^b.
    for a in [1, 2] do
        for b in [1, 2] do
            if 3*(a + b) > cap then continue; fi;
            if a + b < 2 then continue; fi;
            H := _BankJnPC3S3Subdirect(a, b, rs);
            _BankJnPCheckAllWrappers(3*(a + b), H,
                StringFormatted("subdirect(C_3^{} x S_3^{})", a, b));
        od;
    od;

    # (5) Mixed-size (C_3)^a × (C_5)^b. Orbits of different sizes are
    # automatically in different perm-iso classes.
    for a in [1, 2, 3] do
        for b in [1, 2] do
            if 3*a + 5*b > cap then continue; fi;
            H := _BankJnPMixedSizes(a, b);
            _BankJnPCheckAllWrappers(3*a + 5*b, H,
                StringFormatted("(C_3)^{} x (C_5)^{}", a, b));
        od;
    od;

    BankReportStats("jnp");
    return _BankStats.fail = 0;
end;
