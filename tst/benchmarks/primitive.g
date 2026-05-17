# Primitive-group benchmark: hand-picked non-2-transitive primitive
# groups where the orbital widget should reduce search significantly.

if not IsBoundGlobal("BenchSweep") then
    Read("tst/benchmarks/helpers.g");
fi;

RunBenchmarks_primitive := function(outStream)
    local allVar, orbOnly, deepOnly, spec, G, n, gname;
    # Inputs where every variant (incl. Simple) finishes in seconds.
    allVar := [
        ["PSL(2,7)",      PSL(2, 7),         8],
        ["PGL(2,7)",      PGL(2, 7),         8],
        ["PSL(2,11)",     PSL(2, 11),        12],
        ["A_5_on_6",      PrimitiveGroup(6, 1), 6],
        ["A_6",           AlternatingGroup(6), 6],
        ["M_11",          MathieuGroup(11),  11]
    ];
    # AGL(1, p) and similar — order is small but the group has large
    # index in S_n. OrbitalRoot AND Simple both brute force; only the
    # deep-orbital variants finish in reasonable time. We use a tight
    # variant list to keep the benchmark runtime bounded.
    deepOnly := ["Orbital", "OrbitalDeep", "OrbitalSmall", "gap"];
    orbOnly := [
        ["AGL(1,11)",     PrimitiveGroup(11, 4), 11],
        ["AGL(1,13)",     PrimitiveGroup(13, 4), 13]
    ];
    for spec in allVar do
        gname := spec[1]; G := spec[2]; n := spec[3];
        BenchSweep(gname, G, n, BenchAllVariants, outStream);
    od;
    for spec in orbOnly do
        gname := spec[1]; G := spec[2]; n := spec[3];
        BenchSweep(gname, G, n, deepOnly, outStream);
    od;
end;
