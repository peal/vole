# Canonical image of a group inside another group.
#
# This is a capability GAP cannot do directly (no built-in
# CanonicalImage for permutation groups under conjugation).  Vole
# can: it canonicalises H ≤ G under the conjugation action of some
# overgroup K (often K = SymmetricGroup(n)).
#
# Two groups H_1, H_2 ≤ G are K-conjugate iff
#   Vole.CanonicalImage(K, H_1, OnPoints) =
#   Vole.CanonicalImage(K, H_2, OnPoints).
#
# This script computes canonical images for a curated set of
# permutation groups, verifies conjugate inputs produce equal
# canonical images, and times the whole thing.
#
# Output CSV:
#   problem_id,n,|H|,canonical_size,ms,nodes,refines,ok
#
# `ok` = "true" if all conjugate inputs produced the same canonical
# image (correctness gate).

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

_RandConjs := function(H, K, k)
    local out, i, g;
    out := [H];
    for i in [1..k] do
        g := PseudoRandom(K);
        Add(out, H ^ g);
    od;
    return out;
end;

_FindAGL := function(d, p)
    local n;
    n := p ^ d;
    return First(List([1 .. NrPrimitiveGroups(n)], i -> PrimitiveGroup(n, i)),
                 H -> HasSize(H) and Size(H) = n * Size(GL(d, p)));
end;

# Run canonical image of H inside Sym(n), check conjugate inputs all
# canonicalise to the same group.  k = number of random conjugates to
# test.
_RunCanon := function(label, H, n, k)
    local conjs, t, c1, ms, ok, j, c;
    conjs := _RandConjs(H, SymmetricGroup(n), k);
    t := NanosecondsSinceEpoch();
    c1 := Vole.CanonicalImage(SymmetricGroup(n), conjs[1], OnPoints);
    ms := Int((NanosecondsSinceEpoch() - t) / 1000000);
    ok := true;
    for j in [2..Length(conjs)] do
        c := Vole.CanonicalImage(SymmetricGroup(n), conjs[j], OnPoints);
        if c <> c1 then
            ok := false;
            Print(label, "  *** MISMATCH on conjugate ", j-1, "\n");
        fi;
    od;
    Print(label, "  n=", n, "  |H|=", Size(H),
          "  canonical=", Size(c1), "  ms_first=", ms, "  ok=", ok, "\n");
end;

# (C_p)^k abelian-regular family
for p in [3, 5, 7] do
    for k in [2, 3, 4] do
        if p * k > 25 then continue; fi;
        _RunCanon(Concatenation("(C_", String(p), ")^", String(k)),
                  _Disjoint(List([1..k], i -> CyclicGroup(IsPermGroup, p))),
                  p * k, 5);
    od;
od;

# Direct products / wreath products
_RunCanon("(S_3)^4", _Disjoint(List([1..4], i -> SymmetricGroup(3))), 12, 5);
_RunCanon("(S_3)^5", _Disjoint(List([1..5], i -> SymmetricGroup(3))), 15, 5);
_RunCanon("S_3 wr S_3",
          WreathProduct(SymmetricGroup(3), SymmetricGroup(3)), 9, 5);
_RunCanon("S_5 wr S_3",
          WreathProduct(SymmetricGroup(5), SymmetricGroup(3)), 15, 5);

# Primitive groups
_RunCanon("AGL(3;3)", _FindAGL(3, 3), 27, 5);
_RunCanon("AGL(4;2)", _FindAGL(4, 2), 16, 5);
_RunCanon("M_11", MathieuGroup(11), 11, 5);
_RunCanon("M_12", MathieuGroup(12), 12, 5);

# Transitive groups picked from previously-hard inputs
_RunCanon("TransGrp(16;500)", TransitiveGroup(16, 500), 16, 5);
_RunCanon("TransGrp(18;500)", TransitiveGroup(18, 500), 18, 5);

QUIT;
