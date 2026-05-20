# Big-showcase: same structure as showcase.g but each section pushed
# to inputs where the slow side hits at least 10 s.  Per-call budget
# raised to 300 s; cases pre-selected so the typical total wall time
# is a couple of hours.

LoadPackage("vole", false);
LoadPackage("io", false);
LoadPackage("digraphs", false);
LoadPackage("primgrp", false);
LoadPackage("transgrp", false);

BUDGET_SECS := 300;

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

_FmtRatio := function(num, den)
    if den <= 0 then return "n/a"; fi;
    return String(Float(num / den));
end;

# ----------------------------------------------------------------
# Section 1 — Big Vole wins
# ----------------------------------------------------------------
Print("\n========== SECTION 1: Big Vole wins on normaliser ==========\n");
Print("# (C_p)^k pushed to where GAP takes 10+ seconds.\n\n");

_CompareNorm := function(label, H, n)
    local g, v, ratio;
    g := _Time({} -> Size(Normalizer(SymmetricGroup(n), H)));
    v := _Time({} -> Size(Vole.Normalizer(SymmetricGroup(n), H)));
    if g.value = fail or v.value = fail then
        Print(label, "  n=", n, "  GAP=", _FmtMs(g.ms),
              "  Vole=", _FmtMs(v.ms), "\n");
        return;
    fi;
    if g.value <> v.value then
        Print(label, "  *** MISMATCH\n");
        return;
    fi;
    Print(label, "  n=", n, "  |H|=", Size(H),
          "  GAP=", g.ms, "ms",
          "  Vole=", v.ms, "ms",
          "  GAP/Vole=", _FmtRatio(g.ms, v.ms), "\n");
end;

for spec in [[3,30], [3,40], [3,50], [3,60],
             [5,20], [5,25], [5,30],
             [7,15], [7,20], [7,25],
             [11,15], [11,20], [13,15], [13,20]] do
    if spec[1] * spec[2] > 250 then continue; fi;
    _CompareNorm(Concatenation("(C_", String(spec[1]), ")^", String(spec[2])),
                 _Disjoint(List([1..spec[2]], i -> CyclicGroup(IsPermGroup, spec[1]))),
                 spec[1] * spec[2]);
od;

# Big primitive groups where Vole's shortcut closes
Print("\n# Big primitive groups — GAP runs PartitionBacktrack, Vole shortcut closes.\n\n");
for spec in [[25,23], [25,28], [36,9], [36,14], [36,18], [36,21], [45,2], [45,6], [49,29], [49,35]] do
    if spec[2] > NrPrimitiveGroups(spec[1]) then continue; fi;
    _CompareNorm(Concatenation("PrimGrp(", String(spec[1]), ";", String(spec[2]), ")"),
                 PrimitiveGroup(spec[1], spec[2]),
                 spec[1]);
od;

# ----------------------------------------------------------------
# Section 2 — Big GAP wins
# ----------------------------------------------------------------
Print("\n========== SECTION 2: Big GAP wins on normaliser ==========\n");
Print("# AGL / Mathieu / big primitive — GAP's NormalizerParentSA path\n");
Print("# avoids partition backtrack entirely.\n\n");

for spec in [[3,5], [4,3], [5,2], [6,2], [2,11], [2,13], [2,17], [2,19], [2,23]] do
    if spec[1] ^ spec[2] > 250 then continue; fi;
    _CompareNorm(Concatenation("AGL(", String(spec[1]), ";", String(spec[2]), ")"),
                 _FindAGL(spec[1], spec[2]),
                 spec[1] ^ spec[2]);
od;
_CompareNorm("M_22", MathieuGroup(22), 22);
_CompareNorm("M_23", MathieuGroup(23), 23);
_CompareNorm("M_24", MathieuGroup(24), 24);
# PSLs / PGLs on larger degree
for q in [11, 13, 17, 19, 23, 29, 31, 37, 41, 47, 53] do
    if q + 1 > 200 then continue; fi;
    _CompareNorm(Concatenation("PSL(2;", String(q), ")"), PSL(2, q), q + 1);
od;

# ----------------------------------------------------------------
# Section 3 — Pure search-vs-search
# ----------------------------------------------------------------
Print("\n========== SECTION 3: Pure search-vs-search via override ==========\n");
Print("# Outer reductions run identically; only the partition\n");
Print("# backtrack differs.  Vole-side overrides DoNormalizerPermGroup.\n\n");

_PureCompare := function(label, H, n)
    local g, v;
    _Vole.OverrideGAP.NormalizerOff();
    g := _Time({} -> Size(Normalizer(SymmetricGroup(n), H)));
    _Vole.OverrideGAP.NormalizerOn();
    v := _Time({} -> Size(Normalizer(SymmetricGroup(n), H)));
    _Vole.OverrideGAP.NormalizerOff();
    if g.value <> fail and v.value <> fail and g.value <> v.value then
        Print(label, "  *** MISMATCH\n"); return;
    fi;
    Print(label, "  n=", n, "  |N|=", g.value,
          "  GAP_search=", _FmtMs(g.ms),
          "  Vole_search=", _FmtMs(v.ms),
          "  GAP/Vole=", _FmtRatio(g.ms, v.ms), "\n");
end;

# Push intransitive direct products to where GAP backtrack takes seconds
for k in [10, 15, 20, 25, 30, 40] do
    if 3 * k > 200 then continue; fi;
    _PureCompare(Concatenation("(C_3)^", String(k), "_int"),
                 _Disjoint(List([1..k], i -> CyclicGroup(IsPermGroup, 3))),
                 3 * k);
od;
for k in [6, 10, 15, 20] do
    if 3 * k > 100 then continue; fi;
    _PureCompare(Concatenation("(S_3)^", String(k), "_int"),
                 _Disjoint(List([1..k], i -> SymmetricGroup(3))),
                 3 * k);
od;
# Bigger TransGrp where Vole was losing — push degrees up
for spec in [[20,500], [20,1000], [22,50], [22,500],
             [24,500], [24,1000], [24,2000], [26,500], [28,500]] do
    if spec[2] > NrTransitiveGroups(spec[1]) then continue; fi;
    _PureCompare(Concatenation("TG(", String(spec[1]), ";", String(spec[2]), ")"),
                 TransitiveGroup(spec[1], spec[2]),
                 spec[1]);
od;

# ----------------------------------------------------------------
# Section 4 — Vole-only: canonical image of a group
# ----------------------------------------------------------------
Print("\n========== SECTION 4: Canonical image at scale ==========\n");
Print("# Vole-only feature.  Each entry checks consistency under one\n");
Print("# random G-conjugation.\n\n");

_CanonCheck := function(label, G, H)
    local n, c1, c2, gen, H_conj, ok;
    n := LargestMovedPoint(G);
    c1 := _Time({} -> Vole.CanonicalImage(G, H, OnPoints));
    if c1.value = fail then
        Print(label, "  n=", n, "  Vole=", _FmtMs(c1.ms), "\n");
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

for spec in [[3,12], [3,15], [3,20], [3,25],
             [5,6], [5,8], [5,10], [5,12],
             [7,6], [7,8], [7,10],
             [11,5], [11,8], [13,5], [13,8]] do
    if spec[1] * spec[2] > 150 then continue; fi;
    _CanonCheck(Concatenation("(C_", String(spec[1]), ")^", String(spec[2])),
                SymmetricGroup(spec[1] * spec[2]),
                _Disjoint(List([1..spec[2]],
                    i -> CyclicGroup(IsPermGroup, spec[1]))));
od;
for spec in [[3,4], [3,5], [4,3], [4,4], [4,5], [5,3], [5,4]] do
    if spec[1] * spec[2] > 30 then continue; fi;
    _CanonCheck(Concatenation("S_", String(spec[1]), "wrS_", String(spec[2])),
                SymmetricGroup(spec[1] * spec[2]),
                WreathProduct(SymmetricGroup(spec[1]), SymmetricGroup(spec[2])));
od;
_CanonCheck("AGL(3;3)", SymmetricGroup(27), _FindAGL(3, 3));
_CanonCheck("AGL(4;2)", SymmetricGroup(16), _FindAGL(4, 2));
_CanonCheck("AGL(4;3)", SymmetricGroup(81), _FindAGL(4, 3));
_CanonCheck("AGL(5;2)", SymmetricGroup(32), _FindAGL(5, 2));
_CanonCheck("M_11",  SymmetricGroup(11), MathieuGroup(11));
_CanonCheck("M_12",  SymmetricGroup(12), MathieuGroup(12));
_CanonCheck("M_22",  SymmetricGroup(22), MathieuGroup(22));
_CanonCheck("M_24",  SymmetricGroup(24), MathieuGroup(24));

# ----------------------------------------------------------------
# Section 5 — Vole vs Bliss on big widget digraphs
# ----------------------------------------------------------------
Print("\n========== SECTION 5: Vole vs Bliss on big widget digraphs ==========\n");
Print("# (C_p)^k widgets pushed to thousands of vertices.\n\n");

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
    local v, b;
    v := _Time({} -> Size(Vole.AutomorphismGroup(d)));
    b := _Time({} -> Size(AutomorphismGroup(d)));
    if v.value <> fail and b.value <> fail and v.value <> b.value then
        Print(label, "  *** MISMATCH\n"); return;
    fi;
    Print(label, "  V=", DigraphNrVertices(d),
          "  |Aut|=", v.value,
          "  Bliss=", _FmtMs(b.ms),
          "  Vole=", _FmtMs(v.ms),
          "  Vole/Bliss=", _FmtRatio(v.ms, b.ms), "\n");
end;

for spec in [[3,15], [3,30], [3,50], [3,75], [3,100],
             [5,10], [5,15], [5,25], [5,40],
             [7,10], [7,15], [7,25],
             [11,10], [11,15],
             [13,8], [13,12],
             [17,6], [17,8],
             [19,5], [19,8],
             [23,5], [23,7]] do
    if spec[1] * spec[2] > 500 then continue; fi;
    _VoleVsBliss(Concatenation("C_", String(spec[1]), "^", String(spec[2])),
                 _BuildCpkWidget(spec[1], spec[2]));
od;

Print("\n========== BIG SHOWCASE COMPLETE ==========\n");
QUIT;
