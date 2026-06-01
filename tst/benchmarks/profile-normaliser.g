# Profiling harness for normaliser refiner phases.
# Instruments the key GAP-side computations and reports breakdown of
# where CPU time goes.
#
# Usage: gap -r tst/benchmarks/profile-normaliser.g

Read("tst/test_functions.g");

# Accumulate timing per phase.
_PF_TIMES := HashMap();
_PF_RESET := function() _PF_TIMES := HashMap(); end;
_PF_ADD := function(phase, dt)
    if phase in _PF_TIMES then
        _PF_TIMES[phase] := _PF_TIMES[phase] + dt;
    else
        _PF_TIMES[phase] := dt;
    fi;
end;
_PF_REPORT := function(nodeCount)
    local total, phases, phase, pct;
    total := 0.0;
    for phase in Keys(_PF_TIMES) do
        total := total + _PF_TIMES[phase];
    od;
    Print("  GAP refiner total: ", total, " ms (", nodeCount, " nodes)");
    if nodeCount > 0 and total > 0.0 then
        Print(" = ", Float(Int(100.0 * total / nodeCount)) / 100.0, " ms/node");
    fi;
    Print("\n");
    phases := SortedList(Keys(_PF_TIMES));
    if total = 0.0 then return; fi;
    for phase in phases do
        pct := Int(Float(10000.0 * _PF_TIMES[phase] / total)) / 100.0;
        Print("    ", phase, ": ", _PF_TIMES[phase], " ms (",
            pct, "%)\n");
    od;
end;

########################################################################
# Profiled wrappers
########################################################################

_Prof_getOrbitalListWithOptions := _BTKit.getOrbitalListWithOptions;
_BTKit.getOrbitalListWithOptions := function(sc, options...)
    local t0, res;
    t0 := Runtime();
    res := CallFuncList(_Prof_getOrbitalListWithOptions,
        Concatenation([sc], options));
    _PF_ADD("orbList", Runtime() - t0);
    return res;
end;

_Prof_orbitalEquivalenceKey := _BTKit.orbitalEquivalenceKey;
_BTKit.orbitalEquivalenceKey := function(og)
    local t0, res;
    t0 := Runtime();
    res := _Prof_orbitalEquivalenceKey(og);
    _PF_ADD("orbEquivKey(Bliss)", Runtime() - t0);
    return res;
end;

_Prof_buildSetOfGraphsWidget := _BTKit.buildSetOfGraphsWidget;
_BTKit.buildSetOfGraphsWidget := function(graphs, n)
    local t0, res;
    t0 := Runtime();
    res := _Prof_buildSetOfGraphsWidget(graphs, n);
    _PF_ADD("buildWidget", Runtime() - t0);
    return res;
end;

_Prof_stabTreeOrbGraphs := StabTreeStabilizerOrbitalGraphs;
StabTreeStabilizerOrbitalGraphs := function(group, points, options...)
    local t0, res;
    t0 := Runtime();
    res := CallFuncList(_Prof_stabTreeOrbGraphs,
        Concatenation([group, points], options));
    _PF_ADD("stabTreeOrbGraphs", Runtime() - t0);
    return res;
end;

_Prof_stabTreeOrbits := StabTreeStabilizerOrbits;
StabTreeStabilizerOrbits := function(group, points, domain)
    local t0, res;
    t0 := Runtime();
    res := _Prof_stabTreeOrbits(group, points, domain);
    _PF_ADD("stabTreeOrbits", Runtime() - t0);
    return res;
end;

_Prof_stabTreeBlockGraphs := StabTreeStabilizerBlockSystemGraphs;
StabTreeStabilizerBlockSystemGraphs := function(group, points, options...)
    local t0, res;
    t0 := Runtime();
    res := CallFuncList(_Prof_stabTreeBlockGraphs,
        Concatenation([group, points], options));
    _PF_ADD("stabTreeBlocks", Runtime() - t0);
    return res;
end;

_Prof_regOrbSchreier := _BTKit.regularOrbitSchreierTreeData;
_BTKit.regularOrbitSchreierTreeData := function(group, regOrb)
    local t0, res;
    t0 := Runtime();
    res := _Prof_regOrbSchreier(group, regOrb);
    _PF_ADD("regOrbitSchreier", Runtime() - t0);
    return res;
end;

_Prof_stabTreeRegOrb := StabTreeRegularOrbitData;
StabTreeRegularOrbitData := function(group)
    local t0, res;
    t0 := Runtime();
    res := _Prof_stabTreeRegOrb(group);
    _PF_ADD("regOrbitStabTree", Runtime() - t0);
    return res;
end;

_Prof_bfsOrbitWithTrace := _BTKit.bfsOrbitWithTrace;
_BTKit.bfsOrbitWithTrace := function(seed, gens)
    local t0, res;
    t0 := Runtime();
    res := _Prof_bfsOrbitWithTrace(seed, gens);
    _PF_ADD("crossBFS", Runtime() - t0);
    return res;
end;

########################################################################

BindGlobal("ProfileOne", function(label, G, H, refinerName)
    local N_gap, t_total, N, nodes;
    Print("\n=== ", label, " [", refinerName, "] ===\n");
    Print("|H|=", Size(H), " n=", LargestMovedPoint(G),
        " orbs=", List(Orbits(H, [1..LargestMovedPoint(G)]), Length), "\n");

    N_gap := Normalizer(G, H);

    _PF_RESET();
    _BTKit.ResetNormaliserNodeCount();

    t_total := Runtime();
    N := Vole.Normalizer(G, H : refiner := refinerName);
    t_total := Runtime() - t_total;
    nodes := _BTKit.NormaliserNodeCount();

    Print("  total=", t_total, "ms nodes=", nodes,
        " OK=", N = N_gap, "\n");
    _PF_REPORT(nodes);
end);

# Helper to build cyclic+quotient groups
_BuildCyclicQuotient := function(m, nonRegConfig)
    local gen, nextPt, entry, d, count, i;
    gen := MappingPermListList([1..m], Concatenation([2..m], [1]));
    nextPt := m;
    for entry in nonRegConfig do
        d := entry[1]; count := entry[2];
        for i in [1..count] do
            gen := gen * MappingPermListList(
                [nextPt+1 .. nextPt+d],
                Concatenation([nextPt+2 .. nextPt+d], [nextPt+1]));
            nextPt := nextPt + d;
        od;
    od;
    return rec(G := SymmetricGroup(nextPt), H := Group(gen),
        n := nextPt, label := Concatenation("C", String(m)));
end;

########################################################################
# Test groups
########################################################################

Print("=== Normaliser Profiler ===\n");

# (1) Large cyclic+quotients: root-heavy
r := _BuildCyclicQuotient(60, [[20,2], [15,2]]);
ProfileOne(Concatenation(r.label, "+2x20+2x15"), r.G, r.H, "Orbital");
ProfileOne(Concatenation(r.label, "+2x20+2x15"), r.G, r.H, "OrbitalRegOrbitCross");

# (2) Medium cyclic+quotients
r := _BuildCyclicQuotient(30, [[15,2]]);
ProfileOne(Concatenation(r.label, "+2x15"), r.G, r.H, "Orbital");
ProfileOne(Concatenation(r.label, "+2x15"), r.G, r.H, "OrbitalRegOrbitCross");

# (3) Search-heavy transitive
ProfileOne("T(7,5)", SymmetricGroup(7), TransitiveGroup(7,5), "Orbital");
ProfileOne("T(8,21)", SymmetricGroup(8), TransitiveGroup(8,21), "Orbital");

# (4) Regular transitive
ProfileOne("C13 reg", SymmetricGroup(13),
    Group([MappingPermListList([1..13], Concatenation([2..13],[1]))]),
    "OrbitalRegOrbitCross");

# (5) Direct product intransitive
ProfileOne("S3xS3 intrans", SymmetricGroup(6),
    Group([(1,2,3), (1,2), (4,5,6), (4,5)]), "Orbital");

QUIT;
