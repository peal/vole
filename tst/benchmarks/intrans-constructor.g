# Framework for constructing intransitive permutation groups.
#
# Motivation: intransitive groups with a mix of orbit sizes (not "all
# small" and not transitive) are under-studied in the normaliser
# literature.  This file provides constructors for common patterns,
# plus benchmarking and comparison tools.
#
# Constructors return rec(G, H, n, orbits, label) where G = Sym(n).
#
# Usage:
#   Read("tst/benchmarks/intrans-constructor.g");
#   r := RegularPlusCyclicQuotients(30, [[15,2],[10,3]]);
#   CompareRefinersAll(r.G, r.H);
#   SweepAndReport([r1, r2, ...]);
#

########################################################################
# API
########################################################################

# Compare Orbital / RegOrbit / RegOrbitCross on a given group.
# Returns list of rec(name, t_ms, nodes, ok).
BindGlobal("CompareRefinersAll", function(G, H)
    local N_gap, results, r, t, N, nodes;
    N_gap := Normalizer(G, H);
    results := [];

    for r in [
        ["Orbital", "Orbital"],
        ["RegOrbit", "OrbitalRegOrbit"],
        ["RegOrbitCross", "OrbitalRegOrbitCross"],
    ] do
        _BTKit.ResetNormaliserNodeCount();
        t := Runtime();
        N := Vole.Normalizer(G, H : refiner := r[2]);
        t := Runtime() - t;
        nodes := _BTKit.NormaliserNodeCount();
        if not (N = N_gap) then
            Add(results, rec(name := r[1], t_ms := t,
                nodes := nodes, ok := "WRONG"));
        else
            Add(results, rec(name := r[1], t_ms := t,
                nodes := nodes, ok := "OK"));
        fi;
    od;
    return results;
end);

BindGlobal("PrintCompare", function(label, G, H)
    local results, r, n;
    n := LargestMovedPoint(G);
    results := CompareRefinersAll(G, H);
    Print(label, " |H|=", Size(H), " n=", n,
        " orbs=", List(Orbits(H, [1..n]), Length), "\n");
    for r in results do
        Print("  ", r.name, ": ", r.t_ms, "ms nodes=", r.nodes,
            " ", r.ok, "\n");
    od;
end);

# Sweep a list of groups and report all.
BindGlobal("SweepAndReport", function(groups)
    local g;
    for g in groups do
        PrintCompare(g.label, g.G, g.H);
    od;
end);

########################################################################
# Constructor 1: Cyclic group with quotient actions.
#
# H = C_m.  Regular on {1..m}.  For each [d, count] pair (d|m),
# adds `count` d-cycles on disjoint blocks of size d, acting via
# the quotient C_m / C_{m/d} ≅ C_d.
#
# This is the simplest way to get a regular orbit (size m = |H|)
# plus non-regular orbits (size d < m, kernel size m/d).
########################################################################
BindGlobal("RegularPlusCyclicQuotients", function(m, nonRegConfig)
    local gen, nextPt, entry, d, count, i;
    gen := MappingPermListList([1..m],
            Concatenation([2..m], [1]));
    nextPt := m;
    for entry in nonRegConfig do
        d := entry[1]; count := entry[2];
        for i in [1..count] do
            gen := gen * MappingPermListList(
                [nextPt+1 .. nextPt+d],
                Concatenation([nextPt+2 .. nextPt+d],
                    [nextPt+1]));
            nextPt := nextPt + d;
        od;
    od;
    return rec(
        label := Concatenation("C", String(m), "+",
            JoinStringsWithSeparator(
                List(nonRegConfig, x ->
                    Concatenation(String(x[2]), "x", String(x[1]))),
                "+")),
        H := Group(gen),
        G := SymmetricGroup(nextPt),
        n := nextPt
    );
end);

########################################################################
# Constructor 2: Direct product R × K where R is regular on m points.
#
# R acts regularly on {1..m}.  K acts on {m+1..m+d} via its natural
# (or given) permutation representation.
#
# The full group H = R × K has order |R|*|K|.  The orbit on the
# R-part has size m, which is NOT regular (|H| > m unless |K|=1).
# This tests the regime where NO orbit is regular — the
# regular-orbit machinery should be inert.
#
# This is the regime where Chang-DDPD / orbit-by-orbit reductions
# apply.  Useful for testing wrapper-level decompositions.
########################################################################
BindGlobal("DirectProductRegularPlus", function(R, K)
    local m, d, genR, genK, gens, gR, gK, n, perms;
    m := LargestMovedPoint(R);
    d := LargestMovedPoint(K);
    n := m + d;
    perms := [];
    for gR in GeneratorsOfGroup(R) do
        Add(perms, gR);
    od;
    for gK in GeneratorsOfGroup(K) do
        Add(perms, gK * MappingPermListList([1..m], [1..m]));
    od;
    return rec(
        label := Concatenation("R", String(Size(R)), "xK", String(Size(K))),
        H := Group(perms),
        G := SymmetricGroup(n),
        n := n
    );
end;

########################################################################
# Constructor 3: Subdirect product — regular on one orbit,
# non-faithful on others (via quotient), with MULTIPLE generators.
#
# Given m generators of a regular group R of order m on {1..m},
# and a list of quotient actions [d, gen_patterns, count] where
# gen_patterns specifies the generator images on each block of size d.
#
# This handles non-cyclic regular groups.
########################################################################
BindGlobal("RegularPlusQuotientMultiGen", function(regGens, nonRegConfig)
    # regGens: list of permutations generating a regular group on {1..m}
    # nonRegConfig: list of [d, count, genMat] where:
    #   d = orbit size, count = number of blocks,
    #   genMat[i][j] = image of generator i on block j (as a d-cycle)
    # Simplified: genMat[i][j] is the PERMUTATION for gen i on block j
    local m, nextPt, outGens, entry, d, count, genMats, i, j, n;
    m := LargestMovedPoint(Group(regGens));
    nextPt := m;
    outGens := ShallowCopy(regGens);
    for entry in nonRegConfig do
        d := entry[1]; count := entry[2]; genMats := entry[3];
        for j in [1..count] do
            for i in [1..Length(outGens)] do
                outGens[i] := outGens[i] *
                    MappingPermListList(
                        [1..nextPt-1],
                        [1..nextPt-1])  # identity on previous points
                    * genMats[i][j];     # action on this block
            od;
            nextPt := nextPt + d;
        od;
    od;
    return rec(
        label := "MultiGenReg+Quotients",
        H := Group(outGens),
        G := SymmetricGroup(nextPt - 1),
        n := nextPt - 1
    );
end;

########################################################################
# Constructor 4: Wreath-style — regular group R on each of k blocks,
# with the blocks permuted by a top group T.
#
# H = R ≀ T (permutational wreath product).  R acts regularly on
# blocks of size m; T permutes the k blocks.  The group has order
# |R|^k * |T|.  Orbits: either one transitive orbit of size m*k
# (if T is transitive on blocks), or k orbits of size m (if T=1).
#
# For T transitive, this is transitive — the regular-orbit machinery
# is inert (no regular orbit unless |R|^k = m*k, which is rare).
# For T = 1, each orbit IS regular (size m = |R|, and |H| = |R|^k,
# so the orbit is NOT regular for k>1 — but wait, |H|=|R|^k, orbit
# size = m = |R|, so orbit size < |H| for k>1, not regular).
########################################################################
BindGlobal("WreathRegular", function(R, k)
    local m, gens, i, base, g, n;
    m := LargestMovedPoint(R);
    n := m * k;
    gens := [];
    # Copy R into each block
    for i in [1..k] do
        base := (i-1) * m;
        for g in GeneratorsOfGroup(R) do
            Add(gens, MappingPermListList([1..n],
                Concatenation(
                    [1..base],
                    List([base+1..base+m], x -> base + (x-base)^g),
                    [base+m+1..n])));
        od;
    od;
    return rec(
        label := Concatenation("WreathReg_", String(Size(R)),
            "x", String(k)),
        H := Group(gens),
        G := SymmetricGroup(n),
        n := n
    );
end;
