# Scaling sweep over direct/semidirect product families. Looking for
# instances where Vole/GAP ratio grows super-polynomially with k.
#
# Six families:
#   1. (C_p)^k        — abelian regular, k copies, n = pk
#   2. D_n^k          — dihedral on n points, k disjoint copies, deg = nk
#   3. S_n^k          — symmetric on n points, k disjoint copies, deg = nk
#   4. A_n^k          — alternating, similar
#   5. D_n wreath S_k — full wreath product, deg = nk (with permutation
#                      of blocks — actually a *semidirect product*)
#   6. S_n wreath S_k — full wreath product
#
# For each (family, parameter), time both GAP Normalizer(S_deg, H) and
# Vole.Normalizer(SymmetricGroup(deg), H). 30 s timeout per call.

LoadPackage("vole", false);
LoadPackage("io", false);

# Helper: shift a perm by `shift` (move its support up).
_Shift := function(p, shift)
    local lmp, sigma;
    lmp := LargestMovedPoint(p);
    if lmp = 0 then return (); fi;
    sigma := MappingPermListList([1 .. lmp], [shift + 1 .. shift + lmp]);
    return p ^ sigma;
end;

# Disjoint direct product on points (sequential supports).
_Disjoint := function(groups)
    local gens, shift, G, g;
    gens := []; shift := 0;
    for G in groups do
        for g in GeneratorsOfGroup(G) do Add(gens, _Shift(g, shift)); od;
        shift := shift + LargestMovedPoint(G);
    od;
    if IsEmpty(gens) then return Group(()); fi;
    return Group(gens);
end;

# Time one input under both backends. Per-call timeout via IO.
_TimeBoth := function(label, H)
    local n, t, raw_g, raw_v, gms, vms, gN, vN;
    n := LargestMovedPoint(H);
    raw_g := IO_CallWithTimeout(rec(seconds := 30),
        function(g, m)
            local t0;
            t0 := NanosecondsSinceEpoch();
            return [Size(Normalizer(SymmetricGroup(m), g)),
                    Int((NanosecondsSinceEpoch() - t0) / 1000000)];
        end, H, n);
    if Length(raw_g) >= 2 and raw_g[1] = true then
        gN := raw_g[2][1];  gms := raw_g[2][2];
    else
        gN := fail;  gms := -1;
    fi;
    raw_v := IO_CallWithTimeout(rec(seconds := 30),
        function(g, m)
            local t0;
            t0 := NanosecondsSinceEpoch();
            return [Size(Vole.Normalizer(SymmetricGroup(m), g)),
                    Int((NanosecondsSinceEpoch() - t0) / 1000000)];
        end, H, n);
    if Length(raw_v) >= 2 and raw_v[1] = true then
        vN := raw_v[2][1];  vms := raw_v[2][2];
    else
        vN := fail;  vms := -1;
    fi;
    Print(label, "  deg=", n, "  |H|=", Size(H),
          "  GAP=", gms, "ms  Vole=", vms, "ms  match=", gN = vN, "\n");
end;

# Family 1: (C_p)^k for p ∈ {3, 5, 7}, k = 2..7.
Print("=== Family 1: (C_p)^k ===\n");
for p in [3, 5, 7] do
    for k in [2, 3, 4, 5, 6, 7] do
        if p * k > 60 then continue; fi;
        H := _Disjoint(List([1..k], i -> CyclicGroup(IsPermGroup, p)));
        _TimeBoth(Concatenation("C_", String(p), "^", String(k)), H);
    od;
od;

# Family 2: D_n^k for D_n = DihedralGroup(IsPermGroup, n).
# n_pts = n/2; total deg = (n/2)*k. Use n ∈ {6, 8, 10, 12} (so 3, 4, 5, 6 pts).
Print("\n=== Family 2: D_n^k ===\n");
for nh in [6, 8, 10, 12] do
    for k in [2, 3, 4, 5, 6] do
        if QuoInt(nh, 2) * k > 60 then continue; fi;
        H := _Disjoint(List([1..k], i -> DihedralGroup(IsPermGroup, nh)));
        _TimeBoth(Concatenation("D_", String(nh), "^", String(k)), H);
    od;
od;

# Family 3: S_n^k.
Print("\n=== Family 3: S_n^k ===\n");
for n in [3, 4, 5, 6] do
    for k in [2, 3, 4, 5] do
        if n * k > 60 then continue; fi;
        H := _Disjoint(List([1..k], i -> SymmetricGroup(n)));
        _TimeBoth(Concatenation("S_", String(n), "^", String(k)), H);
    od;
od;

# Family 4: A_n^k.
Print("\n=== Family 4: A_n^k ===\n");
for n in [4, 5, 6] do
    for k in [2, 3, 4] do
        if n * k > 60 then continue; fi;
        H := _Disjoint(List([1..k], i -> AlternatingGroup(n)));
        _TimeBoth(Concatenation("A_", String(n), "^", String(k)), H);
    od;
od;

# Family 5: D_n wreath S_k (full wreath, semidirect).
Print("\n=== Family 5: D_n wr S_k ===\n");
for nh in [6, 8, 10] do
    for k in [2, 3, 4, 5] do
        if QuoInt(nh, 2) * k > 60 then continue; fi;
        H := WreathProduct(DihedralGroup(IsPermGroup, nh), SymmetricGroup(k));
        _TimeBoth(Concatenation("D_", String(nh), " wr S_", String(k)), H);
    od;
od;

# Family 6: S_n wreath S_k.
Print("\n=== Family 6: S_n wr S_k ===\n");
for n in [3, 4, 5] do
    for k in [2, 3, 4] do
        if n * k > 60 then continue; fi;
        H := WreathProduct(SymmetricGroup(n), SymmetricGroup(k));
        _TimeBoth(Concatenation("S_", String(n), " wr S_", String(k)), H);
    od;
od;

QUIT;
