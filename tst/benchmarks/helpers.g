# Benchmark helpers.
#
# Each call returns rec(nodes, refiner_calls, wall_time_ms, size, vole_eq_gap).

# Run a single normaliser variant on (G ≤ S_n, n) and return stats.
BenchVariant := function(variant, G, n)
    local refiner, t, stats, vgroup, voleSize, gapResult, gapSize;
    t := NanosecondsSinceEpoch();
    if variant = "gap" then
        gapResult := Normalizer(SymmetricGroup(n), G);
        t := Int((NanosecondsSinceEpoch() - t) / 1000000);
        return rec(
            nodes := -1,
            refiner_calls := -1,
            wall_time_ms := t,
            size := Size(gapResult),
            vole_eq_gap := true);
    fi;
    refiner := GB_Con.(Concatenation("Normaliser", variant))(G);
    vgroup := VoleFind.Group(SymmetricGroup(n), refiner);
    stats := _Vole.LastStats;
    t := Int((NanosecondsSinceEpoch() - t) / 1000000);
    voleSize := Size(vgroup);
    # Validate against GAP (only at problem creation time would normally
    # be useful, but here we redo it to catch drift).
    gapResult := Normalizer(SymmetricGroup(n), G);
    gapSize := Size(gapResult);
    return rec(
        nodes := stats.search_nodes,
        refiner_calls := stats.refiner_calls,
        wall_time_ms := t,
        size := voleSize,
        vole_eq_gap := vgroup = gapResult);
end;

# Sweep one problem across the listed variants.
#  problem_id : string identifying this benchmark row
#  G          : the input group (a permutation group)
#  n          : the symmetric-group degree
#  variants   : list of variant names (subset of BenchAllVariants); each
#               is run, in the order given, and a CSV row emitted
#  outStream  : open stream for CSV output
BenchSweep := function(problem_id, G, n, variants, outStream)
    local v, stats;
    for v in variants do
        stats := BenchVariant(v, G, n);
        PrintTo(outStream, StringFormatted(
            "{},{},{},{},{},{},{}\n",
            problem_id, v,
            stats.nodes, stats.refiner_calls, stats.wall_time_ms,
            stats.size, stats.vole_eq_gap));
    od;
end;

# Full variant list, in canonical CSV order. Individual benchmark files
# may pick a subset (e.g. drop expensive Simple variants on hard inputs).
#
# - All: every variant. Use when brute-force isn't prohibitive.
# - OrbitalsOnly: variants that actually push orbital graphs. Use when
#   brute force would dominate the runtime budget. Includes gap baseline.
BenchAllVariants := ["Simple", "Simple2", "OrbitalNone", "OrbitalRoot",
                      "Orbital", "OrbitalDeep", "OrbitalSmall", "gap"];
BenchOrbitalsOnly := ["OrbitalRoot", "Orbital", "OrbitalDeep",
                       "OrbitalSmall", "gap"];

# CSV header.
BenchWriteHeader := function(outStream)
    PrintTo(outStream,
        "problem_id,variant,nodes,refiner_calls,wall_time_ms,size,vole_eq_gap\n");
end;
