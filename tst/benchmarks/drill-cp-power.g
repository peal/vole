# Drill into (C_p)^k scaling. For each (p, k), measure Vole's search
# stats (node count, refiner-call count from the raw inner-solver
# return) alongside wall time, and GAP's PartitionBacktrack stats
# from GAPNormTrace.
#
# Hypothesis: Vole branches inside each C_p orbit because Phase A's
# orbital-graph push gives no within-orbit refinement after one point
# is fixed (stab(C_p, pt) is trivial → empty orbital graphs). Without
# anything pruning the within-orbit candidates, Vole tries all p of
# them per orbit, giving p^k branches.

LoadPackage("vole", false);
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

_Drill := function(p, k)
    local H, n, t, gms, vms, raw, stats;
    H := _Disjoint(List([1..k], i -> CyclicGroup(IsPermGroup, p)));
    n := LargestMovedPoint(H);
    t := NanosecondsSinceEpoch();
    Size(Normalizer(SymmetricGroup(n), H));;
    gms := Int((NanosecondsSinceEpoch() - t) / 1000000);
    t := NanosecondsSinceEpoch();
    raw := Vole.Normalizer(SymmetricGroup(n), H : raw := true);
    vms := Int((NanosecondsSinceEpoch() - t) / 1000000);
    stats := raw.raw.stats;
    Print("C_", p, "^", k, "  deg=", n, "  |H|=", Size(H),
          "  GAP=", gms, "ms  Vole=", vms, "ms",
          "  nodes=", stats.search_nodes,
          "  refines=", stats.refiner_calls,
          "  fixed_events=", stats.gap_callbacks.fixed,
          "  refine_time=", stats.gap_callbacks.refiner_time, "ms",
          "  vole_time=", stats.vole_time, "ms\n");
end;

# Sweep (C_7)^k for k = 2..7. Look for super-polynomial node growth.
for k in [2, 3, 4, 5, 6, 7] do
    _Drill(7, k);
od;
Print("\n");
# Compare with (C_3)^k.
for k in [2, 3, 4, 5, 6, 7] do
    _Drill(3, k);
od;

QUIT;
