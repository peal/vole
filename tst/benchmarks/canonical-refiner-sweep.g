# Canonical-image-of-group benchmark across refiner variants.
#
# For each (G, H) test case and each NormaliserX refiner, we run
#   ret := VoleFind.Canonical(G, refiner(H));
#   canon := H ^ ret.canonical;
# and check consistency: every G-conjugate of H must produce the same
# canonical group.  The refiners marked "canonical-unsafe" in
# normaliser.g (OrbitalRegOrbit, OrbitalRegOrbitChar) are EXPECTED to
# fail this check — running them here documents the failure mode.
#
# Output per row: name, refiner, ms_first, ms_total, nodes_first,
# consistent (bool over 4 random conjugates), |canonical|.

LoadPackage("vole", false);
LoadPackage("primgrp", false);
LoadPackage("transgrp", false);

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

_FindAGL := function(d, p)
    local n;
    n := p ^ d;
    return First(List([1 .. NrPrimitiveGroups(n)], i -> PrimitiveGroup(n, i)),
                 H -> HasSize(H) and Size(H) = n * Size(GL(d, p)));
end;

# Marked unsafe variants for documentation purposes; expected to
# produce conjugate-inconsistent canonical images on inputs where the
# regular-orbit / characteristic-subgroup data depends on labelling.
refiners := [
    rec(name := "Simple",                safe := true),
    rec(name := "Simple2",               safe := true),
    rec(name := "Orbital",               safe := true),
    rec(name := "OrbitalSmall",          safe := true),
    rec(name := "OrbitalDeep",           safe := true),
    rec(name := "OrbitalRegOrbit",       safe := false),
    rec(name := "OrbitalRegOrbitChar",   safe := false)
];

cases := [
    rec(name := "(C_3)^2",  G := SymmetricGroup(6),  H := Group([(1,2,3),(4,5,6)])),
    rec(name := "(C_3)^3",  G := SymmetricGroup(9),  H := Group([(1,2,3),(4,5,6),(7,8,9)])),
    rec(name := "(C_3)^4",  G := SymmetricGroup(12), H := _Disjoint(List([1..4], i -> CyclicGroup(IsPermGroup, 3)))),
    rec(name := "(C_5)^3",  G := SymmetricGroup(15), H := _Disjoint(List([1..3], i -> CyclicGroup(IsPermGroup, 5)))),
    rec(name := "(C_5)^4",  G := SymmetricGroup(20), H := _Disjoint(List([1..4], i -> CyclicGroup(IsPermGroup, 5)))),
    rec(name := "(C_7)^3",  G := SymmetricGroup(21), H := _Disjoint(List([1..3], i -> CyclicGroup(IsPermGroup, 7)))),
    rec(name := "(S_3)^3",  G := SymmetricGroup(9),  H := _Disjoint(List([1..3], i -> SymmetricGroup(3)))),
    rec(name := "(S_3)^4",  G := SymmetricGroup(12), H := _Disjoint(List([1..4], i -> SymmetricGroup(3)))),
    rec(name := "S_3wrS_3", G := SymmetricGroup(9),  H := WreathProduct(SymmetricGroup(3), SymmetricGroup(3))),
    rec(name := "S_4wrS_3", G := SymmetricGroup(12), H := WreathProduct(SymmetricGroup(4), SymmetricGroup(3))),
    rec(name := "AGL(1;7)", G := SymmetricGroup(7),  H := Group([(1,2,3,4,5,6,7),(2,3,5)(4,7,6)])),
    rec(name := "AGL(3;2)", G := SymmetricGroup(8),  H := _FindAGL(3, 2)),
    rec(name := "AGL(4;2)", G := SymmetricGroup(16), H := _FindAGL(4, 2)),
    rec(name := "AGL(3;3)", G := SymmetricGroup(27), H := _FindAGL(3, 3)),
    rec(name := "M_11",     G := SymmetricGroup(11), H := MathieuGroup(11)),
    rec(name := "M_12",     G := SymmetricGroup(12), H := MathieuGroup(12)),
    rec(name := "TG(16;500)",  G := SymmetricGroup(16), H := TransitiveGroup(16, 500)),
    rec(name := "TG(18;500)",  G := SymmetricGroup(18), H := TransitiveGroup(18, 500)),
    rec(name := "TG(20;1000)", G := SymmetricGroup(20), H := TransitiveGroup(20, 1000))
];

_RunCanonical := function(G, H, refinerName)
    local refiner, t, ret, ms;
    refiner := GB_Con.(Concatenation("Normaliser", refinerName))(H);
    t := NanosecondsSinceEpoch();
    ret := VoleFind.Canonical(G, refiner : raw := true);
    ms := Int((NanosecondsSinceEpoch() - t) / 1000000);
    return rec(ms := ms, canonical := H ^ ret.canonical,
               nodes := ret.raw.stats.search_nodes);
end;

# Per (case, refiner): time the first call, then test 4 random
# conjugates and verify the canonical image stays the same.  Also
# measure the total ms across all 5 calls for "average" timing.
_SweepCase := function(c)
    local r, first, j, gen, H_conj, conj_result, consistent, total_ms;
    Print(c.name, " (n=", LargestMovedPoint(c.H), ", |H|=", Size(c.H), "):\n");
    for r in refiners do
        first := _RunCanonical(c.G, c.H, r.name);
        consistent := true;
        total_ms := first.ms;
        for j in [1..4] do
            gen := PseudoRandom(c.G);
            H_conj := c.H ^ gen;
            conj_result := _RunCanonical(c.G, H_conj, r.name);
            total_ms := total_ms + conj_result.ms;
            if conj_result.canonical <> first.canonical then
                consistent := false;
            fi;
        od;
        Print("  ", r.name, ": ms_first=", first.ms,
              " ms_total5=", total_ms,
              " nodes=", first.nodes,
              " consistent=", consistent,
              " safe=", r.safe, "\n");
    od;
end;

for c in cases do _SweepCase(c); od;

QUIT;
