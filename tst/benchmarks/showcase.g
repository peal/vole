# Showcase benchmarks: a curated set of (input, comparison) entries
# chosen to make the story easy to tell.  Categories:
#
#   1. Normaliser: where Vole wins big — (C_p)^k and similar
#      shortcut-closing inputs at scale.
#   2. Normaliser: where GAP wins big — large AGL / primitive groups
#      that GAP disposes of via NormalizerParentSA without ever
#      reaching partition backtrack.
#   3. Pure search-vs-search: using the DoNormalizerPermGroup
#      override so the OUTER pre-backtrack maths runs identically
#      on both sides and the timing diff is partition-backtrack only.
#   4. Vole-only: canonical image of a permutation group under
#      conjugation (no GAP equivalent).  Includes a refiner sweep
#      so the cost / refiner trade-off is visible.
#   5. Vole vs Bliss: pure digraph automorphism on (C_p)^k root-pass
#      widgets at scale.
#
# Per-call wall budget: 120 seconds.  Anything longer is reported
# as "timeout" rather than blocking the rest of the sweep.

LoadPackage("vole", false);
LoadPackage("io", false);
LoadPackage("digraphs", false);
LoadPackage("primgrp", false);
LoadPackage("transgrp", false);

BUDGET_SECS := 120;

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

# Run `fn()` with a wall-clock cap of BUDGET_SECS.  Returns a record
# with `.value` (or fail on timeout/error) and `.ms` (wall time, -1
# if timed out).
_Time := function(fn)
    local raw;
    raw := IO_CallWithTimeout(rec(seconds := BUDGET_SECS),
        function()
            local t, v;
            t := NanosecondsSinceEpoch();
            v := fn();
            return [v, Int((NanosecondsSinceEpoch() - t) / 1000000)];
        end);
    if Length(raw) >= 2 and raw[1] = true then
        return rec(value := raw[2][1], ms := raw[2][2]);
    fi;
    return rec(value := fail, ms := -1);
end;

_FmtMs := function(ms) if ms < 0 then return "TIMEOUT"; fi; return Concatenation(String(ms), "ms"); end;

# ----------------------------------------------------------------
# Section 1 — Normaliser cases where Vole wins big
# ----------------------------------------------------------------
Print("\n========== SECTION 1: Normaliser cases where Vole wins big ==========\n");
Print("# (C_p)^k abelian regular and related — Vole's root Aut shortcut\n");
Print("# closes at the root; GAP runs partition backtrack as the input\n");
Print("# grows.  Wall times scale: GAP roughly polynomially in k, Vole\n");
Print("# stays near-constant (the cost is the sub-search on the widget).\n\n");
Print(Concatenation(["label", "n", "|H|", "|N|", "GAP_ms", "Vole_ms", "ratio"]));

_CompareNorm := function(label, H, n)
    local g, v, ratio;
    g := _Time({} -> Size(Normalizer(SymmetricGroup(n), H)));
    v := _Time({} -> Size(Vole.Normalizer(SymmetricGroup(n), H)));
    if g.value = fail or v.value = fail then
        Print(label, "  n=", n, "  |H|=", Size(H),
              "  GAP=", _FmtMs(g.ms), "  Vole=", _FmtMs(v.ms), "\n");
        return;
    fi;
    if g.value <> v.value then
        Print(label, "  *** MISMATCH ", g.value, " vs ", v.value, "\n");
        return;
    fi;
    if v.ms = 0 then ratio := "inf"; else ratio := String(Float(g.ms / v.ms)); fi;
    Print(label, "  n=", n, "  |H|=", Size(H), "  |N|=", g.value,
          "  GAP=", g.ms, "ms  Vole=", v.ms, "ms  ratio=", ratio, "\n");
end;

# (C_p)^k at scale
for spec in [[3,15], [3,20], [3,30], [3,40], [5,10], [5,15], [5,20],
             [7,10], [7,15], [11,10], [11,15], [13,15]] do
    if spec[1] * spec[2] > 200 then continue; fi;
    _CompareNorm(Concatenation("(C_", String(spec[1]), ")^", String(spec[2])),
                 _Disjoint(List([1..spec[2]],
                     i -> CyclicGroup(IsPermGroup, spec[1]))),
                 spec[1] * spec[2]);
od;

# Big primitive groups where Vole's root shortcut still closes
Print("\n# Big primitive groups where GAP runs PartitionBacktrack for\n");
Print("# seconds but Vole's shortcut closes the search at the root.\n\n");
for spec in [[36,14], [36,18], [36,9], [21,2], [21,4], [21,6], [25,17],
             [25,23], [45,2], [45,4], [45,6], [28,1], [28,9]] do
    if spec[1] > NrPrimitiveGroups(spec[1]) then continue; fi;
    if spec[2] > NrPrimitiveGroups(spec[1]) then continue; fi;
    _CompareNorm(Concatenation("PrimGrp(", String(spec[1]), ";", String(spec[2]), ")"),
                 PrimitiveGroup(spec[1], spec[2]),
                 spec[1]);
od;

# ----------------------------------------------------------------
# Section 2 — Normaliser cases where GAP wins big
# ----------------------------------------------------------------
Print("\n========== SECTION 2: Normaliser cases where GAP wins big ==========\n");
Print("# Big-AGL / Mathieu / large primitives.  GAP dispatches via\n");
Print("# DoNormalizerSA → NormalizerParentSA → recurse, computing a\n");
Print("# smaller parent group group-theoretically.  PartitionBacktrack\n");
Print("# is never reached.  Vole has no equivalent and runs the full\n");
Print("# refiner pipeline.\n\n");

for spec in [[3,5], [4,3], [5,2], [6,2], [2,11], [2,13]] do
    if spec[1] ^ spec[2] > 200 then continue; fi;
    _CompareNorm(Concatenation("AGL(", String(spec[1]), ";", String(spec[2]), ")"),
                 _FindAGL(spec[1], spec[2]),
                 spec[1] ^ spec[2]);
od;
_CompareNorm("M_22", MathieuGroup(22), 22);
_CompareNorm("M_23", MathieuGroup(23), 23);
_CompareNorm("M_24", MathieuGroup(24), 24);

# ----------------------------------------------------------------
# Section 3 — Pure search-vs-search with DoNormalizerPermGroup override
# ----------------------------------------------------------------
Print("\n========== SECTION 3: Pure search-vs-search (via override) ==========\n");
Print("# Same input on both sides; the outer NormalizerPermGroup\n");
Print("# pre-backtrack reductions run identically.  At the\n");
Print("# DoNormalizerPermGroup boundary GAP either runs its own\n");
Print("# partition backtrack or, with the override on, calls Vole.\n");
Print("# Diff reads as 'GAP backtrack ms vs Vole backtrack ms'.\n\n");

_PureCompare := function(label, H, n)
    local g, v;
    _Vole.OverrideGAP.NormalizerOff();
    g := _Time({} -> Size(Normalizer(SymmetricGroup(n), H)));
    _Vole.OverrideGAP.NormalizerOn();
    v := _Time({} -> Size(Normalizer(SymmetricGroup(n), H)));
    _Vole.OverrideGAP.NormalizerOff();
    if g.value <> fail and v.value <> fail and g.value <> v.value then
        Print(label, "  *** MISMATCH\n");
        return;
    fi;
    Print(label, "  n=", n, "  |N|=", g.value,
          "  GAP_search=", _FmtMs(g.ms),
          "  Vole_search=", _FmtMs(v.ms), "\n");
end;

# Intransitive (C_3)^k — orbit-by-orbit reduction routes to DNPG.
for k in [6, 8, 10, 12, 15] do
    _PureCompare(Concatenation("(C_3)^", String(k), "_int"),
                 _Disjoint(List([1..k], i -> CyclicGroup(IsPermGroup, 3))),
                 3 * k);
od;
# Intransitive (S_3)^k
for k in [4, 6, 8, 10] do
    _PureCompare(Concatenation("(S_3)^", String(k), "_int"),
                 _Disjoint(List([1..k], i -> SymmetricGroup(3))),
                 3 * k);
od;
# Big TransGrp entries where DoNormalizerSA falls through
for spec in [[16,500], [18,500], [20,100], [20,500], [20,1000], [22,50], [24,500]] do
    if spec[2] > NrTransitiveGroups(spec[1]) then continue; fi;
    _PureCompare(Concatenation("TG(", String(spec[1]), ";", String(spec[2]), ")"),
                 TransitiveGroup(spec[1], spec[2]),
                 spec[1]);
od;

# ----------------------------------------------------------------
# Section 4 — Vole-only: canonical image of a group
# ----------------------------------------------------------------
Print("\n========== SECTION 4: Canonical image of a permutation group ==========\n");
Print("# GAP has no built-in CanonicalImage for permutation groups\n");
Print("# under conjugation.  Vole does.  We time it across a range\n");
Print("# of inputs and verify a conjugate produces the same canonical\n");
Print("# image (correctness).\n\n");

_CanonCheck := function(label, G, H)
    local n, c1, c2, gen, H_conj, ok;
    n := LargestMovedPoint(G);
    c1 := _Time({} -> Vole.CanonicalImage(G, H, OnPoints));
    if c1.value = fail then
        Print(label, "  n=", n, "  |H|=", Size(H), "  Vole=", _FmtMs(c1.ms), "\n");
        return;
    fi;
    gen := PseudoRandom(G);
    H_conj := H ^ gen;
    c2 := _Time({} -> Vole.CanonicalImage(G, H_conj, OnPoints));
    ok := c2.value <> fail and c1.value = c2.value;
    Print(label, "  n=", n, "  |H|=", Size(H),
          "  Vole=", c1.ms, "ms",
          "  conjugate=", _FmtMs(c2.ms),
          "  consistent=", ok, "\n");
end;

# Pure abelian (C_p)^k
for spec in [[3,5], [3,8], [3,10], [3,15], [5,4], [5,6], [5,8], [7,4], [7,6]] do
    if spec[1] * spec[2] > 60 then continue; fi;
    _CanonCheck(Concatenation("(C_", String(spec[1]), ")^", String(spec[2])),
                SymmetricGroup(spec[1] * spec[2]),
                _Disjoint(List([1..spec[2]],
                    i -> CyclicGroup(IsPermGroup, spec[1]))));
od;
# Wreath products
for spec in [[3,3], [3,4], [4,3], [4,4], [5,3]] do
    if spec[1] * spec[2] > 30 then continue; fi;
    _CanonCheck(Concatenation("S_", String(spec[1]), "wrS_", String(spec[2])),
                SymmetricGroup(spec[1] * spec[2]),
                WreathProduct(SymmetricGroup(spec[1]), SymmetricGroup(spec[2])));
od;
# Primitives
_CanonCheck("AGL(3;3)", SymmetricGroup(27), _FindAGL(3, 3));
_CanonCheck("AGL(4;2)", SymmetricGroup(16), _FindAGL(4, 2));
_CanonCheck("M_11",  SymmetricGroup(11), MathieuGroup(11));
_CanonCheck("M_12",  SymmetricGroup(12), MathieuGroup(12));

# ----------------------------------------------------------------
# Section 5 — Vole vs Bliss: digraph automorphism
# ----------------------------------------------------------------
Print("\n========== SECTION 5: Vole vs Bliss on digraph automorphism ==========\n");
Print("# (C_p)^k root-pass widget digraphs.  Bliss is a state-of-the-\n");
Print("# art digraph-Aut implementation (the Digraphs package wraps\n");
Print("# it).  Both compute Aut(D) for the same input D.\n\n");

_BuildCpkWidget := function(p, k)
    local n_base, adj, orbit, step, arcs, j, src, dst, w, u, i;
    n_base := p * k;
    adj := List([1..n_base], i -> []);
    for orbit in [1..k] do
        Add(adj, [(orbit-1)*p + 1 .. orbit*p]);
        for j in [(orbit-1)*p + 1 .. orbit*p] do Add(adj[j], Length(adj)); od;
    od;
    for orbit in [1..k] do
        for step in [1..p-1] do
            arcs := List([0..p-1], j ->
                [(orbit-1)*p + 1 + j, (orbit-1)*p + 1 + ((j + step) mod p)]);
            Add(adj, []); w := Length(adj);
            for j in [1..Length(arcs)] do
                src := arcs[j][1]; dst := arcs[j][2];
                Add(adj, [dst]); u := Length(adj);
                Add(adj[src], u); Add(adj[w], u);
            od;
        od;
    od;
    return Digraph(adj);
end;

_VoleVsBliss := function(label, d)
    local v, b, ratio;
    v := _Time({} -> Size(Vole.AutomorphismGroup(d)));
    b := _Time({} -> Size(AutomorphismGroup(d)));  # bliss via digraphs
    if v.value <> fail and b.value <> fail and v.value <> b.value then
        Print(label, "  *** MISMATCH\n"); return;
    fi;
    if b.ms = 0 then ratio := "inf"; else ratio := String(Float(v.ms / b.ms)); fi;
    Print(label, "  V=", DigraphNrVertices(d),
          "  |Aut|=", v.value,
          "  Bliss=", b.ms, "ms",
          "  Vole=", v.ms, "ms",
          "  Vole/Bliss=", ratio, "\n");
end;

for spec in [[3,5], [3,8], [3,10], [3,15], [3,20],
             [5,3], [5,5], [5,8], [5,10],
             [7,3], [7,5], [7,8],
             [11,3], [11,5],
             [13,3]] do
    if spec[1] * spec[2] > 200 then continue; fi;
    _VoleVsBliss(Concatenation("C_", String(spec[1]), "^", String(spec[2])),
                 _BuildCpkWidget(spec[1], spec[2]));
od;

Print("\n========== SHOWCASE COMPLETE ==========\n");
QUIT;
