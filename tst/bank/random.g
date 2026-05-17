# Random subgroups of S_n, seeded for reproducibility. The point is to
# escape the structural regularities of TransGrp / PrimGrp / SmallGroups
# and stress-test along a distribution we don't curate.

if not IsBoundGlobal("BankCompareNormaliser") then
    Read("tst/bank/helpers.g");
fi;

BankRandomCounts := function(mode)
    if mode = "quick" then
        return rec(max_n := 12, samples_per_n := 5);
    elif mode = "nightly" then
        return rec(max_n := 18, samples_per_n := 20);
    elif mode = "full" then
        return rec(max_n := 28, samples_per_n := 50);
    else
        Error("BankRandomCounts: unknown mode ", mode);
    fi;
end;

RunBank_random := function(mode)
    local cfg, n, sample, src, num_gens, gens, k, G, seed;
    cfg := BankRandomCounts(mode);
    BankResetStats();
    Print(StringFormatted("[random] mode={}, max_n={}, samples_per_n={}\n",
                          mode, cfg.max_n, cfg.samples_per_n));
    # Seed for reproducibility. Re-seed PER (mode, n) so quick subset
    # is a prefix of nightly when caps are increased.
    src := RandomSource(IsMersenneTwister, 42);
    for n in [3 .. cfg.max_n] do
        for sample in [1 .. cfg.samples_per_n] do
            num_gens := Random(src, [1 .. 4]);
            gens := List([1 .. num_gens], k -> Random(src, SymmetricGroup(n)));
            G := Group(Concatenation([()], gens));   # () guards trivial
            BankCompareNormaliser(n, G);
        od;
    od;
    BankReportStats("random");
    return _BankStats.fail = 0;
end;
