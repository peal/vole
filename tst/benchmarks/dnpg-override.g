# DoNormalizerPermGroup override benchmark.
#
# Runs the same `Normalizer(G, E)` problems through GAP's wrappers
# twice: once with GAP's own DoNormalizerPermGroup at the bottom,
# once with Vole.Normalizer overriding it.  The OUTER pre-backtrack
# reductions (NormalizerPermGroup orbit-by-orbit, DoNormalizerSA
# parent finding, NormalizerViaRadical, ...) run on both sides
# unchanged, so the diff is "Vole's search vs GAP's search" on the
# cases that actually reach partition backtrack.
#
# Cases where DoNormalizerSA short-circuits before reaching
# DoNormalizerPermGroup (most large-AGL / Mathieu primitives) won't
# differ — the override isn't called on those.  That's intentional:
# Vole's job is "do better backtrack", not "match GAP's
# pre-backtrack maths".  If GAP doesn't need backtrack, neither do
# we.

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

cases := [
    # Hit DoNormalizerPermGroup because the orbit-by-orbit reduction
    # routes through it for intransitive E:
    rec(name := "(C_3)^6_int",
        E := _Disjoint(List([1..6], i -> CyclicGroup(IsPermGroup, 3))), n := 18),
    rec(name := "(C_3)^8_int",
        E := _Disjoint(List([1..8], i -> CyclicGroup(IsPermGroup, 3))), n := 24),
    rec(name := "(C_3)^10_int",
        E := _Disjoint(List([1..10], i -> CyclicGroup(IsPermGroup, 3))), n := 30),
    rec(name := "(S_3)^5_int",
        E := _Disjoint(List([1..5], i -> SymmetricGroup(3))), n := 15),
    rec(name := "(S_3)^6_int",
        E := _Disjoint(List([1..6], i -> SymmetricGroup(3))), n := 18),
    # Transitive primitive — DoNormalizerSA tries NormalizerParentSA,
    # if no improvement falls back to NormalizerPermGroup ->
    # DoNormalizerPermGroup.
    rec(name := "M_11",  E := MathieuGroup(11), n := 11),
    rec(name := "M_12",  E := MathieuGroup(12), n := 12),
    rec(name := "M_22",  E := MathieuGroup(22), n := 22),
    rec(name := "TransGrp(16;500)", E := TransitiveGroup(16, 500), n := 16),
    rec(name := "TransGrp(18;500)", E := TransitiveGroup(18, 500), n := 18),
    rec(name := "AGL(3;3)", E := _FindAGL(3, 3), n := 27),
    rec(name := "AGL(4;2)", E := _FindAGL(4, 2), n := 16),
    rec(name := "PGL(2;17)", E := PGL(2, 17), n := 18),
    rec(name := "PGL(2;19)", E := PGL(2, 19), n := 20)
];

_Run := function(c, label)
    local t, N, ms;
    t := NanosecondsSinceEpoch();
    N := Normalizer(SymmetricGroup(c.n), c.E);
    ms := Int((NanosecondsSinceEpoch() - t) / 1000000);
    Print("  ", label, " ", ms, "ms  |N|=", Size(N), "\n");
    return Size(N);
end;

for c in cases do
    Print(c.name, " (n=", c.n, "):\n");
    _Vole.OverrideGAP.NormalizerOff();
    a := _Run(c, "GAP   ");
    _Vole.OverrideGAP.NormalizerOn();
    b := _Run(c, "Vole  ");
    _Vole.OverrideGAP.NormalizerOff();
    if a <> b then Print("  *** MISMATCH ", a, " vs ", b, "\n"); fi;
od;

QUIT;
