# Pure digraph-automorphism benchmark: Vole vs Bliss.
#
# Replicates the kind of digraph that `_BTKit.buildSetOfGraphsWidget`
# emits for (C_p)^k root-pass widgets (in normaliser refinement),
# then asks each backend for its automorphism group. This isolates
# Vole's general partition-backtrack engine against a state-of-the-
# art digraph-Aut implementation (Bliss, via the Digraphs package)
# on identical inputs.
#
# The widget shape (1 equivalence class containing k(p-1) directed
# p-cycles, with aux vertices that encode set-permutability):
#   * Base vertices: 1..p*k, the points (C_p)^k acts on.
#   * For each orbit i ∈ [1..k]: base vertices (i-1)*p+1 .. i*p form
#     a directed p-cycle. For each step s ∈ [1..p-1] we have one
#     orbital graph: vertex j connected to vertex j+s within the orbit
#     (mod p). All k(p-1) graphs share one equivalence class.
#   * Per orbital graph we add 1 "graph identity" aux vertex w_i, and
#     for each of the p arcs in that graph an "arc tag" aux vertex u
#     with edges  α → u, u → β, w_i → u.
#   * Plus one "orbit length" aux vertex per orbit, connected to all
#     points in that orbit (so orbit lengths are distinguished).
#
# This matches the (C_p)^k root-pass numbers we measured:
#   ext_domain = base + k * p^2

LoadPackage("vole", false);
LoadPackage("digraphs", false);

# Build the widget-shaped digraph for (C_p)^k.
# Returns the digraph (no vertex labels — Vole/Bliss both treat it
# as plain directed). Total vertex count: p*k + k*p^2 = pk(p+1).
_BuildCpkWidget := function(p, k)
    local n_base, adj, aux, orbit, step, arcs, j, src, dst, w, u, i;
    n_base := p * k;
    adj := List([1..n_base], i -> []);

    # Orbit-length aux: 1 per orbit, connected to its members.
    for orbit in [1..k] do
        Add(adj, [(orbit-1)*p + 1 .. orbit*p]);
        for j in [(orbit-1)*p + 1 .. orbit*p] do
            Add(adj[j], Length(adj));
        od;
    od;

    # Orbital-graph widget: for each (orbit, step) the directed p-cycle
    # at that step on that orbit.
    for orbit in [1..k] do
        for step in [1..p-1] do
            arcs := List([0..p-1], j ->
                [(orbit-1)*p + 1 + j, (orbit-1)*p + 1 + ((j + step) mod p)]);
            # Graph identity vertex w.
            Add(adj, []);
            w := Length(adj);
            for j in [1..Length(arcs)] do
                src := arcs[j][1];
                dst := arcs[j][2];
                # Arc-tag vertex u.
                Add(adj, [dst]);
                u := Length(adj);
                Add(adj[src], u);
                Add(adj[w], u);
            od;
        od;
    od;

    return Digraph(adj);
end;

_TimeMs := function(fn)
    local t, ret;
    t := NanosecondsSinceEpoch();
    ret := fn();
    return rec(result := ret,
               ms := Int((NanosecondsSinceEpoch() - t) / 1000000));
end;

_Compare := function(p, k)
    local d, v, e, t, bliss_grp, bliss_ms, raw, stats;
    d := _BuildCpkWidget(p, k);
    v := DigraphNrVertices(d);
    e := DigraphNrEdges(d);

    t := NanosecondsSinceEpoch();
    bliss_grp := AutomorphismGroup(d);
    bliss_ms := Int((NanosecondsSinceEpoch() - t) / 1000000);

    raw := Vole.AutomorphismGroup(d : raw := true);
    stats := raw.raw.stats;

    if Size(raw.group) <> Size(bliss_grp) then
        Print("C_", p, "^", k, "  *** MISMATCH ***\n");
        return;
    fi;

    Print("C_", p, "^", k,
          "  V=", v, "  E=", e,
          "  |Aut|=", Size(bliss_grp),
          "  Bliss=", bliss_ms, "ms",
          "  Vole=", raw.time, "ms",
          "  nodes=", stats.search_nodes,
          "  refines=", stats.refiner_calls,
          "  trace_fail=", stats.trace_fail_nodes,
          "  bad_iso=", stats.bad_iso,
          "  good_iso=", stats.good_iso,
          "\n");
end;

# Sweep (C_p)^k. Stop at 30 base points so we don't push Vole into
# minutes-territory; Bliss handles all of these comfortably.
for spec in [[3,2],[3,3],[3,4],[3,5],[3,6],[3,7],[3,8],[3,9],[3,10],
             [5,2],[5,3],[5,4],[5,5],
             [7,2],[7,3],[7,4],
             [11,2]] do
    if spec[1] * spec[2] > 30 then continue; fi;
    _Compare(spec[1], spec[2]);
od;

QUIT;
