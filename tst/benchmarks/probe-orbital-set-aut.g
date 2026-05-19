# Test: at the root, the set-wise stabiliser of H's orbital graphs is
# N(H^{(2)}). For 2-closed H, that equals N(H) — so a single
# AutomorphismGroup-of-widget computation gives the normaliser.
#
# Hypothesis we want to check: is (C_p)^k two-closed? If yes, then
# Aut(orbital graph set) = N((C_p)^k) and the user's proposed
# shortcut would close the whole (C_p)^k gap in one step.

LoadPackage("vole", false);
LoadPackage("orbitalgraphs", false);
LoadPackage("io", false);

_Shift := function(p, shift)
    local lmp, sigma;
    lmp := LargestMovedPoint(p);
    if lmp = 0 then return (); fi;
    sigma := MappingPermListList([1 .. lmp], [shift + 1 .. shift + lmp]);
    return p ^ sigma;
end;

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

# For a perm group H, compute:
#   N := Normalizer(SymmetricGroup(n), H)   (the ground truth)
#   T := Vole.TwoClosure(H)                 (element-wise stab; = H^{(2)})
#   S := setwise stabiliser of orbital graphs
#         = Aut(widget) at root
#         = N_{S_n}(H^{(2)})
#   Check: does S equal N? If yes, shortcut works for H.

_Probe := function(label, H)
    local n, t, N, ogs, T_con, T, S_con, S, ok, N_eq_S, T_eq_H;
    n := LargestMovedPoint(H);
    if n = 0 then return; fi;
    Print(label, "  |H|=", Size(H), " n=", n);

    t := NanosecondsSinceEpoch();
    N := Normalizer(SymmetricGroup(n), H);
    Print("  N(H)=", Size(N),
          " (", Int((NanosecondsSinceEpoch()-t)/1000000), "ms)");

    ogs := OrbitalGraphs(H);
    t := NanosecondsSinceEpoch();
    if Length(ogs) = 1 then
        T := SymmetricGroup([1..n]);
    else
        T_con := Constraint.Stabilise(ogs, OnTuplesDigraphs);
        T := VoleFind.Group(Constraint.MovedPoints([1..n]), T_con);
    fi;
    Print("  H^(2)=", Size(T),
          " (", Int((NanosecondsSinceEpoch()-t)/1000000), "ms)");
    T_eq_H := (T = H);
    Print("  H 2-closed=", T_eq_H);

    t := NanosecondsSinceEpoch();
    if Length(ogs) = 1 then
        S := SymmetricGroup([1..n]);
    else
        S_con := Constraint.Stabilise(ogs, OnSetsDigraphs);
        S := VoleFind.Group(Constraint.MovedPoints([1..n]), S_con);
    fi;
    Print("  Aut(set OGs)=", Size(S),
          " (", Int((NanosecondsSinceEpoch()-t)/1000000), "ms)");
    N_eq_S := (S = N);
    Print("  Aut=N(H)? ", N_eq_S, "\n");
end;

# (C_p)^k abelian-regular family — our worst-scaling family.
for p in [3, 5, 7] do
    for k in [2, 3, 4, 5] do
        if p * k > 30 then continue; fi;
        _Probe(Concatenation("(C_", String(p), ")^", String(k)),
               _Disjoint(List([1..k], i -> CyclicGroup(IsPermGroup, p))));
    od;
od;

# D_n^k for comparison (non-abelian).
Print("\n");
for nh in [6, 8, 10] do
    for k in [2, 3] do
        if QuoInt(nh, 2) * k > 30 then continue; fi;
        _Probe(Concatenation("D_", String(nh), "^", String(k)),
               _Disjoint(List([1..k], i -> DihedralGroup(IsPermGroup, nh))));
    od;
od;

# S_n^k (likely not 2-closed because Sym is not very rigid).
Print("\n");
for n in [3, 4] do
    for k in [2, 3] do
        if n * k > 18 then continue; fi;
        _Probe(Concatenation("S_", String(n), "^", String(k)),
               _Disjoint(List([1..k], i -> SymmetricGroup(n))));
    od;
od;

QUIT;
