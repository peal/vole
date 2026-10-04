# Orbital-graph selection-strategy sweep.
#
# Measures how the choice of orbital-graph SUBSET affects vole search
# performance across three problem families -- set stabiliser (OnSets),
# set-of-set stabiliser (OnSetsSets), and normaliser -- over a range of
# (mostly regular) permutation groups. Requires the BacktrackKit
# BTKIT_ORBITAL_STRATEGY scaffolding.
#
# Usage (writes CSV, flushes per row so partial results survive a timeout):
#   gap -A -q -b < /dev/null tst/benchmarks/orbital-strategy-sweep.g
# Optionally set  SWEEP_OUT := "path.csv";  and  SWEEP_GROUPS := <list>;  before
# Read()-ing this file to override the output path / group set.

LoadPackage("vole", false);;

if not IsBoundGlobal("SWEEP_OUT") then
    SWEEP_OUT := "tst/benchmarks/orbital-strategy-sweep.csv";
fi;

# Timing/validation effort (override before Read()-ing to dial down for slow
# flood rows). warmup + median-of-reps wall clock; SWEEP_CONST orbit-constancy
# checks per canonical row.
if not IsBoundGlobal("SWEEP_WARMUP") then SWEEP_WARMUP := 1; fi;
if not IsBoundGlobal("SWEEP_REPS") then SWEEP_REPS := 3; fi;
if not IsBoundGlobal("SWEEP_CONST") then SWEEP_CONST := 8; fi;

########################################################################
# Strategies (the "which graphs" variable). All deterministic.
########################################################################
_SW_bfun := function(m, g) return 8 * m * (LogInt(Maximum(2, m), 2) + 1); end;;
_SW_pfun := function(m, g) return Maximum(8, 2 * LogInt(Maximum(2, g), 2)); end;;

SWEEP_STRATEGIES := [
  rec(id := "all",        order := "ascending",  edgeBudget := infinity, maxPerClass := infinity),
  rec(id := "smallest",   order := "ascending",  edgeBudget := _SW_bfun, maxPerClass := _SW_pfun),
  rec(id := "largest",    order := "descending", edgeBudget := _SW_bfun, maxPerClass := _SW_pfun),
  rec(id := "diversity1", order := "ascending",  edgeBudget := infinity, maxPerClass := 1),
  rec(id := "diversity4", order := "ascending",  edgeBudget := infinity, maxPerClass := 4),
];;

########################################################################
# Timing: warmup, then median of `reps` wall-clock ms.
########################################################################
_SW_TimeMed := function(thunk, warmups, reps)
    local i, r, ts, t;
    r := fail;
    for i in [1 .. warmups] do r := thunk(); od;
    ts := [];
    for i in [1 .. reps] do
        t := NanosecondsSinceEpoch();
        r := thunk();
        Add(ts, (NanosecondsSinceEpoch() - t) / 1000000.);
    od;
    Sort(ts);
    return rec(ms := ts[Int((Length(ts) + 1) / 2)], val := r);
end;;

########################################################################
# Regular representation helper.
########################################################################
_SW_Reg := function(G0)
    return Image(RegularActionHomomorphism(G0));
end;;

########################################################################
# One job = (group, problem). `voleThunk` runs the vole search and returns
# the found group; `rootThunk` returns the orbital-graph list that this
# problem's refiner would ship at the root (shipping proxy); `gapTruth` is
# the correct group (or `fail` to skip the GAP cross-check and rely on
# agreement with the `all` baseline).
########################################################################
_SW_RunJob := function(out, gname, G, n, problem, voleThunk, rootThunk, gapTruth)
    local base, s, timed, root, rg, ra, eq_all, eq_gap;
    base := fail;
    for s in SWEEP_STRATEGIES do
        BTKIT_ORBITAL_STRATEGY := s;
        root := rootThunk();
        rg := Length(root);
        ra := Sum(root, DigraphNrEdges);
        timed := _SW_TimeMed(voleThunk, SWEEP_WARMUP, SWEEP_REPS);
        if s.id = "all" then base := timed.val; fi;
        if base = fail then
            eq_all := "-";
        elif timed.val = base then
            eq_all := "true";
        else
            eq_all := "FALSE";
        fi;
        if gapTruth = fail then
            eq_gap := "-";
        elif timed.val = gapTruth then
            eq_gap := "true";
        else
            eq_gap := "FALSE";
        fi;
        AppendTo(out, StringFormatted("{},{},{},{},{},{},{},{},{},{},{},{}\n",
            gname, Size(G), n, problem, s.id, rg, ra,
            _Vole.LastStats.search_nodes, _Vole.LastStats.refiner_calls,
            Int(timed.ms), eq_all, eq_gap));
        Print("  ", gname, " ", problem, " ", s.id,
              ": graphs=", rg, " nodes=", _Vole.LastStats.search_nodes,
              " ms=", Int(timed.ms), " eq_all=", eq_all, " eq_gap=", eq_gap, "\n");
    od;
    BTKIT_ORBITAL_STRATEGY := false;
end;;

########################################################################
# Canonical-image job. Instead of GAP equality we check the well-definedness
# invariant canon(obj^g) = canon(obj) for a few random g in G (canonical
# images must be orbit-constant), plus agreement with the `all` baseline.
########################################################################
_SW_RunCanonJob := function(out, gname, G, n, obj, action, rootThunk)
    local base, s, timed, root, rg, ra, eq_all, i, constant, x;
    base := fail;
    for s in SWEEP_STRATEGIES do
        BTKIT_ORBITAL_STRATEGY := s;
        root := rootThunk();
        rg := Length(root);
        ra := Sum(root, DigraphNrEdges);
        timed := _SW_TimeMed(function() return Vole.CanonicalImage(G, obj, action); end, SWEEP_WARMUP, SWEEP_REPS);
        if s.id = "all" then base := timed.val; fi;
        if base = fail then eq_all := "-";
        elif timed.val = base then eq_all := "true"; else eq_all := "FALSE"; fi;
        # orbit-constancy of the canonical image under this strategy
        constant := "true";
        for i in [1 .. SWEEP_CONST] do
            x := action(obj, Random(G));
            if Vole.CanonicalImage(G, x, action) <> timed.val then constant := "FALSE"; fi;
        od;
        AppendTo(out, StringFormatted("{},{},{},{},{},{},{},{},{},{},{},{}\n",
            gname, Size(G), n, "canon", s.id, rg, ra,
            _Vole.LastStats.search_nodes, _Vole.LastStats.refiner_calls,
            Int(timed.ms), eq_all, constant));
        Print("  ", gname, " canon ", s.id, ": graphs=", rg,
              " nodes=", _Vole.LastStats.search_nodes, " ms=", Int(timed.ms),
              " eq_all=", eq_all, " orbit_constant=", constant, "\n");
    od;
    BTKIT_ORBITAL_STRATEGY := false;
end;;

########################################################################
# Build a "hard" set-stab object for a regular group: the point-set of a
# subgroup H0 <= G0 under the regular action `hom`. Its OnSets-stabiliser
# contains (the regular image of) H0, so the search is non-trivial and
# actually uses the orbital-graph refiner.
########################################################################
_SW_SubgroupSet := function(hom, H0)
    return Set(Orbit(Image(hom, H0), 1));
end;;

########################################################################
# Build the (group, problem, object) job list for one group.
# `setstab`, `setsetstab` objects are chosen relative to the degree; norm
# validates against Normalizer(S_n, G) when `withNorm` is true.
########################################################################
_SW_JobsForGroup := function(out, gname, G, n, setobj, setsetobj, withNorm)
    local rootStab, rootNorm;
    # Shipping proxy for the InGroup-GB (stabiliser) path at the root.
    rootStab := function() return _BTKit.getOrbitalList(G, n); end;
    # Shipping proxy for the normaliser path at the root.
    rootNorm := function()
        return StabTreeStabilizerOrbitalGraphs(G, [],
                   rec(maxval := n, skipOneLarge := false, budgetMode := "normaliser"));
    end;

    _SW_RunJob(out, gname, G, n, "setstab",
        function() return VoleFind.Group(G, Constraint.Stabilise(setobj, OnSets)); end,
        rootStab, Stabilizer(G, setobj, OnSets));

    _SW_RunJob(out, gname, G, n, "setsetstab",
        function() return VoleFind.Group(G, Constraint.Stabilise(setsetobj, OnSetsSets)); end,
        rootStab, Stabilizer(G, setsetobj, OnSetsSets));

    if withNorm then
        _SW_RunJob(out, gname, G, n, "norm",
            function() return VoleFind.Group(SymmetricGroup(n), Constraint.Normalise(G)); end,
            rootNorm, Normalizer(SymmetricGroup(n), G));
    fi;
end;;

########################################################################
# Header + driver over a job spec list. Each spec:
#   rec(name, G, n, setobj, setsetobj, withNorm)
########################################################################
SweepRun := function(specs, outpath)
    local out, sp;
    out := OutputTextFile(outpath, false);
    SetPrintFormattingStatus(out, false);
    AppendTo(out, "group,order,degree,problem,strategy,root_graphs,root_arcs,",
                  "nodes,refiner_calls,wall_ms,eq_all,eq_gap\n");
    for sp in specs do
        Print("== ", sp.name, " (deg ", sp.n, ", |G|=", Size(sp.G), ") ==\n");
        _SW_JobsForGroup(out, sp.name, sp.G, sp.n, sp.setobj, sp.setsetobj, sp.withNorm);
    od;
    CloseStream(out);
    Print("\nWrote ", outpath, "\n");
end;;
