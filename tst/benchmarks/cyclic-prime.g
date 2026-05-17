# Cyclic-prime benchmark: C_p in S_p, regular action. The case Theißen
# §3.7 was designed for; Phase A's orbital widget should make these
# easy.

if not IsBoundGlobal("BenchSweep") then
    Read("tst/benchmarks/helpers.g");
fi;

RunBenchmarks_cyclic_prime := function(outStream)
    local p, primes, G, variants;
    primes := [5, 7, 11, 13, 17, 19, 23, 29];
    for p in primes do
        G := Group([CycleFromList([1 .. p])]);
        # Simple/Simple2/OrbitalNone are brute force for prime cyclic
        # groups in regular action — their cost explodes as p grows. For
        # p > 7 we drop them so the benchmark doesn't run for hours; the
        # interesting comparison there is just the orbital variants.
        if p <= 7 then
            variants := BenchAllVariants;
        else
            variants := BenchOrbitalsOnly;
        fi;
        BenchSweep(Concatenation("C_", String(p)),
                   G, p, variants, outStream);
    od;
end;
