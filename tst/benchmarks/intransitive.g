# Intransitive benchmark: direct products and wreath products of small
# transitive groups. The class where Phase F (Chang DDPD) would have
# the biggest payoff; currently Phase A handles most of these via the
# orbit-partition push.

if not IsBoundGlobal("BenchSweep") then
    Read("tst/benchmarks/helpers.g");
fi;

# Build a permutation group on [1..a+b] that acts as G_1 on [1..a] and
# G_2 on [a+1..a+b]. Same helper as in tst/bank/intransitive.g but
# duplicated here for benchmark-self-contained-ness.
_BenchShiftPerm := function(p, shift)
    local lmp, sigma;
    lmp := LargestMovedPoint(p);
    if lmp = 0 then
        return ();
    fi;
    sigma := MappingPermListList([1 .. lmp], [shift + 1 .. shift + lmp]);
    return p ^ sigma;
end;

_BenchDirectProduct := function(G1, G2)
    local a, gens, gen;
    a := LargestMovedPoint(G1);
    gens := ShallowCopy(GeneratorsOfGroup(G1));
    for gen in GeneratorsOfGroup(G2) do
        Add(gens, _BenchShiftPerm(gen, a));
    od;
    return Group(gens);
end;

RunBenchmarks_intransitive := function(outStream)
    local specs, spec, gname, G, n;
    specs := [
        # Equal-shape direct products: N(E) should be N(G_1) wr S_2.
        ["C_5 x C_5",    _BenchDirectProduct(CyclicGroup(IsPermGroup, 5),
                                              CyclicGroup(IsPermGroup, 5)), 10],
        ["C_7 x C_7",    _BenchDirectProduct(CyclicGroup(IsPermGroup, 7),
                                              CyclicGroup(IsPermGroup, 7)), 14],
        ["S_3 x S_3",    _BenchDirectProduct(SymmetricGroup(3),
                                              SymmetricGroup(3)), 6],
        ["A_4 x A_4",    _BenchDirectProduct(AlternatingGroup(4),
                                              AlternatingGroup(4)), 8],
        # Different-shape direct products: factor swap not in N(E).
        ["C_5 x C_7",    _BenchDirectProduct(CyclicGroup(IsPermGroup, 5),
                                              CyclicGroup(IsPermGroup, 7)), 12],
        ["S_3 x S_4",    _BenchDirectProduct(SymmetricGroup(3),
                                              SymmetricGroup(4)), 7],
        # Three-factor.
        ["(C_3)^3",      _BenchDirectProduct(_BenchDirectProduct(
                            CyclicGroup(IsPermGroup, 3),
                            CyclicGroup(IsPermGroup, 3)),
                          CyclicGroup(IsPermGroup, 3)), 9]
    ];
    for spec in specs do
        gname := spec[1]; G := spec[2]; n := spec[3];
        BenchSweep(gname, G, n, BenchAllVariants, outStream);
    od;
end;
