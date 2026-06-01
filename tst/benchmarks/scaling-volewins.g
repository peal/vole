# Scaling sweep over the families where Vole BEATS GAP at small sizes
# (wreaths, iterated/deep wreaths, large intransitive direct products,
# hard transitive groups).  Question: as we push these until a run takes
# several seconds (up to a 30 s budget), does Vole's advantage hold, grow,
# or collapse?
#
# Timing is WALL CLOCK (Vole forks a Rust subprocess, so GAP CPU time would
# miss it).  Per-call budget 30 s.
#   - GAP : wrapped in IO_CallWithTimeout (Normalizer spawns no subprocess,
#           so killing the child is clean).
#   - Vole: timed in-process (Vole has no timeout, so a single call always
#           runs to completion; we can't hard-cap it here without forking,
#           which would lose the in-process node count).
# Each ladder stops escalating once a Vole call's measured wall time exceeds
# the budget — so an over-budget run still completes, but we don't escalate
# further.
# Rows are appended to scaling-volewins.csv one at a time (flushed per row).
#
# Usage: gap -r tst/benchmarks/scaling-volewins.g

LoadPackage("vole", false);
LoadPackage("io", false);
LoadPackage("transgrp", false);

OUT := "tst/benchmarks/scaling-volewins-v2.csv";
BUDGET_MS := 30000;
# Refiner under test. The wrapper default (OrbitalRegOrbitChar) pays an
# unconditional FittingSubgroup(H) on construction — 100x overhead on
# imprimitive groups for no benefit. OrbitalRegOrbit keeps the regular-orbit
# deduction without the characteristic-subgroup search.
REFINER := "OrbitalRegOrbit";

# Stop GAP wrapping long Size(H) integers across lines (keeps the CSV one
# logical row per physical line).
SizeScreen([4096, 4096]);

PrintTo(OUT, "family,label,deg,sizeH,gap_ms,vole_ms,gap_status,",
            "vole_status,match,vole_nodes\n");

# Warm up: the first Vole call forks the persistent Rust subprocess, which
# adds ~30 ms one-off. Pay it now so the ladder numbers are steady-state.
Vole.Normalizer(SymmetricGroup(6), Group([(1,2,3),(4,5,6)]));

_Shift := function(p, shift)
    local lmp;
    lmp := LargestMovedPoint(p);
    if lmp = 0 then return (); fi;
    return p ^ MappingPermListList([1 .. lmp], [shift + 1 .. shift + lmp]);
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

# Time one group under both engines, append a CSV row, return Vole ms
# (or fail if Vole timed out) so the caller can decide whether to escalate.
_TimeBoth := function(family, label, H)
    local n, S, raw_g, gms, gN, gst, t0, vN, vms, vst, nodes, match;
    n := LargestMovedPoint(H);
    S := SymmetricGroup(n);

    # GAP side: forked, hard-killed at the budget.
    raw_g := IO_CallWithTimeout(rec(seconds := QuoInt(BUDGET_MS, 1000)),
        function(g, m)
            local s;
            s := NanosecondsSinceEpoch();
            return [Size(Normalizer(SymmetricGroup(m), g)),
                    Int((NanosecondsSinceEpoch() - s) / 1000000)];
        end, H, n);
    if Length(raw_g) >= 2 and raw_g[1] = true then
        gN := raw_g[2][1]; gms := raw_g[2][2]; gst := "ok";
    else
        gN := fail; gms := -1; gst := "timeout";
    fi;

    # Vole side: timed in-process (runs to completion; no timeout).
    _BTKit.ResetNormaliserNodeCount();
    t0 := NanosecondsSinceEpoch();
    vN := Vole.Normalizer(S, H : refiner := REFINER);
    vms := Int((NanosecondsSinceEpoch() - t0) / 1000000);
    nodes := _BTKit.NormaliserNodeCount();
    vst := "ok";

    if gN <> fail then
        match := Size(vN) = gN;
    else
        match := "NA";
    fi;

    AppendTo(OUT, family, ",", label, ",", n, ",", Size(H), ",",
        gms, ",", vms, ",", gst, ",", vst, ",", match, ",", nodes, "\n");
    Print(family, " ", label, " deg=", n,
        " GAP=", gms, "ms(", gst, ") Vole=", vms, "ms(", vst, ")",
        " nodes=", nodes, " match=", match, "\n");

    return vms;
end;

# Run an ordered ladder of [label, group] pairs; stop escalating once a Vole
# call's measured wall time exceeds the budget. Vole has no timeout, so the
# call that trips the budget still runs to completion (observed up to ~183 s
# on the hardest entries); we just don't escalate past it.
_RunLadder := function(family, ladder)
    local entry, v;
    Print("\n=== ", family, " ===\n");
    for entry in ladder do
        v := _TimeBoth(family, entry[1], entry[2]);
        if v > BUDGET_MS then
            Print("  (Vole reached the ", BUDGET_MS, "ms budget; stopping ",
                  family, ")\n");
            break;
        fi;
    od;
end;

########################################################################
# Family 1: S_n wr S_k  (transitive imprimitive; block automorphism is
# the structure GAP's generic backtrack struggles with).
########################################################################
_RunLadder("Swr", List(
    [[4,4],[5,4],[4,6],[5,5],[4,8],[5,8],[6,8],[5,10],[8,8],[6,12],[8,10],[10,10]],
    p -> [Concatenation("S",String(p[1]),"wrS",String(p[2])),
          WreathProduct(SymmetricGroup(p[1]), SymmetricGroup(p[2]))]));

########################################################################
# Family 2: C_p wr S_k  (the "big wreath" / deep family from the hunt).
########################################################################
_RunLadder("Cwr", List(
    [[5,5],[7,5],[5,8],[7,7],[5,10],[11,5],[7,10],[5,16],[13,8]],
    p -> [Concatenation("C",String(p[1]),"wrS",String(p[2])),
          WreathProduct(CyclicGroup(IsPermGroup, p[1]), SymmetricGroup(p[2]))]));

########################################################################
# Family 3: iterated/nested wreath  S_a wr S_b wr S_c  (deg = a*b*c).
# Two levels of imprimitivity — the deepest structure here.
########################################################################
_RunLadder("deepwr", List(
    [[2,2,2],[2,2,3],[2,3,3],[2,2,5],[3,3,3],[2,2,7],[3,3,4],[2,5,5],[3,4,4],[2,4,7]],
    p -> [Concatenation("S",String(p[1]),"wrS",String(p[2]),"wrS",String(p[3])),
          WreathProduct(WreathProduct(SymmetricGroup(p[1]), SymmetricGroup(p[2])),
                        SymmetricGroup(p[3]))]));

########################################################################
# Family 4: large intransitive direct products (S_n)^k on disjoint
# supports — the orbit-by-orbit territory.
########################################################################
_RunLadder("Sk_int", List(
    [[3,10],[3,15],[3,20],[4,15],[3,30],[4,20],[5,15],[3,40],[5,20],[4,30]],
    p -> [Concatenation("(S",String(p[1]),")^",String(p[2])),
          _Disjoint(List([1..p[2]], i -> SymmetricGroup(p[1])))]));

########################################################################
# Family 5: hard transitive groups from the library, increasing degree.
# Picks a handful of large-index (typically solvable/imprimitive) groups
# that exist in the loaded TransGrp library.
########################################################################
# NB: omits T(24,5000)/T(27,*)/T(30,*) — those trigger a genuine
# multi-minute backtrack (nodes in the tens of thousands); since Vole has no
# timeout, they would run uncapped.
_tgPicks := [[15,50],[16,100],[16,500],[18,50],[18,500],[20,100],[20,500],
             [24,1000]];
_tgLadder := [];
for _p in _tgPicks do
    if _p[2] <= NrTransitiveGroups(_p[1]) then
        Add(_tgLadder, [Concatenation("T(",String(_p[1]),",",String(_p[2]),")"),
                        TransitiveGroup(_p[1], _p[2])]);
    fi;
od;
_RunLadder("transgrp_hard", _tgLadder);

QUIT;
