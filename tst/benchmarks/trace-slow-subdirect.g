# Reproduce the 4 Vole-SLOW subdirect cases and run GAP's Normalizer
# with GAPNormTrace enabled, so we can see where GAP's speed comes
# from on inputs where Vole takes >60s. Targets:
#   - D_8^3   sample=2  (12 pts)
#   - S_4^4   sample=1  (16 pts)
#   - S_4^4   sample=2  (16 pts)
#   - D_8^5   sample=2  (20 pts)
# Seed and walk order from tst/bank/subdirect.g.

LoadPackage("vole", false);
LoadPackage("io", false);
Read("tst/bank/helpers.g");
Read("tst/bank/subdirect.g");

# Walk the seeded RandomSource through the spec list to reproduce the
# same H as the bank does. The bank order is documented in subdirect.g.
_BuildBySpec := function(rs, transitives, num_gens, target_factors, sample_idx)
    local k, mixer;
    for k in [1 .. sample_idx] do
        mixer := BankBuildSubdirectMixer(rs, transitives, num_gens,
                                          target_factors, 40);
    od;
    return mixer;
end;

# Re-run the bank's full spec walk to the desired (spec_idx, sample_idx).
# Returns the mixer record, or fail.
_ReproduceMixer := function(spec_idx, sample_idx)
    local rs, specs, spec, n_total, deg_cap, samples, mixer, i, k;
    rs := RandomSource(IsMersenneTwister, 20260518);
    deg_cap := 28; # "quick" mode
    samples := 2;
    specs := [
        rec(transitives := [DihedralGroup(IsPermGroup, 10),
                            DihedralGroup(IsPermGroup, 10)],
            num_gens := 3),
        rec(transitives := [DihedralGroup(IsPermGroup, 14),
                            DihedralGroup(IsPermGroup, 14)],
            num_gens := 3),
        rec(transitives := [SymmetricGroup(5), SymmetricGroup(5)],
            num_gens := 3),
        rec(transitives := [DihedralGroup(IsPermGroup, 8),
                            DihedralGroup(IsPermGroup, 8),
                            DihedralGroup(IsPermGroup, 8)],
            num_gens := 3),
        rec(transitives := [DihedralGroup(IsPermGroup, 12),
                            DihedralGroup(IsPermGroup, 12),
                            DihedralGroup(IsPermGroup, 12)],
            num_gens := 4),
        rec(transitives := [SymmetricGroup(4), SymmetricGroup(4),
                            SymmetricGroup(4)],
            num_gens := 4),
        rec(transitives := [SymmetricGroup(4), SymmetricGroup(5),
                            SymmetricGroup(6)],
            num_gens := 4),
        rec(transitives := [CyclicGroup(IsPermGroup, 5),
                            CyclicGroup(IsPermGroup, 5),
                            CyclicGroup(IsPermGroup, 5)],
            num_gens := 2),
        rec(transitives := [CyclicGroup(IsPermGroup, 7),
                            CyclicGroup(IsPermGroup, 7),
                            CyclicGroup(IsPermGroup, 7)],
            num_gens := 2),
        rec(transitives := [DihedralGroup(IsPermGroup, 8),
                            DihedralGroup(IsPermGroup, 8),
                            DihedralGroup(IsPermGroup, 8),
                            DihedralGroup(IsPermGroup, 8)],
            num_gens := 4),
        rec(transitives := [DihedralGroup(IsPermGroup, 12),
                            DihedralGroup(IsPermGroup, 12),
                            DihedralGroup(IsPermGroup, 12),
                            DihedralGroup(IsPermGroup, 12)],
            num_gens := 5),
        rec(transitives := [SymmetricGroup(4), SymmetricGroup(4),
                            SymmetricGroup(4), SymmetricGroup(4)],
            num_gens := 5),
        rec(transitives := [DihedralGroup(IsPermGroup, 8),
                            DihedralGroup(IsPermGroup, 8),
                            DihedralGroup(IsPermGroup, 8),
                            DihedralGroup(IsPermGroup, 8),
                            DihedralGroup(IsPermGroup, 8)],
            num_gens := 5),
        rec(transitives := [SymmetricGroup(3), SymmetricGroup(3),
                            SymmetricGroup(3), SymmetricGroup(3),
                            SymmetricGroup(3)],
            num_gens := 4),
        rec(transitives := [DihedralGroup(IsPermGroup, 10),
                            DihedralGroup(IsPermGroup, 10),
                            DihedralGroup(IsPermGroup, 10),
                            DihedralGroup(IsPermGroup, 10),
                            DihedralGroup(IsPermGroup, 10)],
            num_gens := 6)
    ];

    for i in [1 .. Length(specs)] do
        spec := specs[i];
        n_total := Sum(spec.transitives, LargestMovedPoint);
        if n_total > deg_cap then continue; fi;
        for k in [1 .. samples] do
            mixer := BankBuildSubdirectMixer(
                rs, spec.transitives, spec.num_gens,
                Length(spec.transitives) - 1, 40);
            if i = spec_idx and k = sample_idx then
                return mixer;
            fi;
        od;
    od;
    return fail;
end;

# Trace one input.
_TraceCase := function(label, spec_idx, sample_idx)
    local mixer, H, n, t0, N, t_ms, kind, e, j, s;
    Print("\n========================================================\n");
    Print("CASE: ", label, "\n");
    Print("========================================================\n");
    mixer := _ReproduceMixer(spec_idx, sample_idx);
    if mixer = fail then
        Print("(could not reproduce mixer for spec ", spec_idx,
              " sample ", sample_idx, ")\n");
        return;
    fi;
    H := mixer.group;
    n := LargestMovedPoint(H);
    Print("|H| = ", Size(H), ", n = ", n, ", orbits = ",
          SortedList(List(Orbits(H, [1..n]), Length)), "\n");

    GAPNormTrace_Enable();
    t0 := NanosecondsSinceEpoch();
    N := Normalizer(SymmetricGroup(n), H);
    t_ms := Int((NanosecondsSinceEpoch() - t0) / 1000000);
    GAPNormTrace_Disable();

    Print("|N| = ", Size(N), "  total wall = ", t_ms, " ms\n\n");
    GAPNormTrace_Print();
    Print("\n");
end;

_TraceCase("D_8^3 sample 2", 4, 2);
_TraceCase("S_4^4 sample 1", 12, 1);
_TraceCase("S_4^4 sample 2", 12, 2);
_TraceCase("D_8^5 sample 2", 13, 2);

QUIT;
