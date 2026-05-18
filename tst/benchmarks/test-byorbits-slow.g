# Quick test: do the 4 Vole-SLOW subdirect cases finish within a
# reasonable time when we call Vole.Normalizer with the "ByOrbits"
# wrapper? If yes, the existing L-overgroup machinery already encodes
# the canonical-image / per-orbit-normaliser reduction we wanted —
# just not as the default wrapper.

LoadPackage("vole", false);
LoadPackage("io", false);
Read("tst/bank/helpers.g");
Read("tst/bank/subdirect.g");

_ReproduceMixer := function(spec_idx, sample_idx)
    local rs, specs, spec, n_total, deg_cap, samples, mixer, i, k;
    rs := RandomSource(IsMersenneTwister, 20260518);
    deg_cap := 28;
    samples := 2;
    specs := [
        rec(transitives := [DihedralGroup(IsPermGroup, 10),
                            DihedralGroup(IsPermGroup, 10)], num_gens := 3),
        rec(transitives := [DihedralGroup(IsPermGroup, 14),
                            DihedralGroup(IsPermGroup, 14)], num_gens := 3),
        rec(transitives := [SymmetricGroup(5), SymmetricGroup(5)], num_gens := 3),
        rec(transitives := [DihedralGroup(IsPermGroup, 8),
                            DihedralGroup(IsPermGroup, 8),
                            DihedralGroup(IsPermGroup, 8)], num_gens := 3),
        rec(transitives := [DihedralGroup(IsPermGroup, 12),
                            DihedralGroup(IsPermGroup, 12),
                            DihedralGroup(IsPermGroup, 12)], num_gens := 4),
        rec(transitives := [SymmetricGroup(4), SymmetricGroup(4),
                            SymmetricGroup(4)], num_gens := 4),
        rec(transitives := [SymmetricGroup(4), SymmetricGroup(5),
                            SymmetricGroup(6)], num_gens := 4),
        rec(transitives := [CyclicGroup(IsPermGroup, 5),
                            CyclicGroup(IsPermGroup, 5),
                            CyclicGroup(IsPermGroup, 5)], num_gens := 2),
        rec(transitives := [CyclicGroup(IsPermGroup, 7),
                            CyclicGroup(IsPermGroup, 7),
                            CyclicGroup(IsPermGroup, 7)], num_gens := 2),
        rec(transitives := [DihedralGroup(IsPermGroup, 8),
                            DihedralGroup(IsPermGroup, 8),
                            DihedralGroup(IsPermGroup, 8),
                            DihedralGroup(IsPermGroup, 8)], num_gens := 4),
        rec(transitives := [DihedralGroup(IsPermGroup, 12),
                            DihedralGroup(IsPermGroup, 12),
                            DihedralGroup(IsPermGroup, 12),
                            DihedralGroup(IsPermGroup, 12)], num_gens := 5),
        rec(transitives := [SymmetricGroup(4), SymmetricGroup(4),
                            SymmetricGroup(4), SymmetricGroup(4)], num_gens := 5),
        rec(transitives := [DihedralGroup(IsPermGroup, 8),
                            DihedralGroup(IsPermGroup, 8),
                            DihedralGroup(IsPermGroup, 8),
                            DihedralGroup(IsPermGroup, 8),
                            DihedralGroup(IsPermGroup, 8)], num_gens := 5),
        rec(transitives := [SymmetricGroup(3), SymmetricGroup(3),
                            SymmetricGroup(3), SymmetricGroup(3),
                            SymmetricGroup(3)], num_gens := 4),
        rec(transitives := [DihedralGroup(IsPermGroup, 10),
                            DihedralGroup(IsPermGroup, 10),
                            DihedralGroup(IsPermGroup, 10),
                            DihedralGroup(IsPermGroup, 10),
                            DihedralGroup(IsPermGroup, 10)], num_gens := 6)
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

_TimeOne := function(label, spec_idx, sample_idx)
    local mixer, H, n, t0, t_gap, t_direct, t_byorb, N_gap, N_direct, N_byorb,
          r_direct, r_byorb;
    Print("\n=== ", label, " ===\n");
    mixer := _ReproduceMixer(spec_idx, sample_idx);
    H := mixer.group;
    n := LargestMovedPoint(H);
    Print("|H| = ", Size(H), ", n = ", n, "\n");

    t0 := NanosecondsSinceEpoch();
    N_gap := Size(Normalizer(SymmetricGroup(n), H));
    t_gap := Int((NanosecondsSinceEpoch() - t0) / 1000000);
    Print("GAP                  |N|=", N_gap, "  ", t_gap, " ms\n");

    # Direct wrapper with 90s timeout (only relevant for SLOW cases).
    r_direct := IO_CallWithTimeout(rec(seconds := 90), function(g, m)
        local t1, sz;
        t1 := NanosecondsSinceEpoch();
        sz := Size(Vole.Normalizer(SymmetricGroup(m), g : wrapper := "direct"));
        return [sz, Int((NanosecondsSinceEpoch() - t1) / 1000000)];
    end, H, n);
    if Length(r_direct) >= 2 and r_direct[1] = true then
        Print("Vole wrapper=direct  |N|=", r_direct[2][1],
              "  ", r_direct[2][2], " ms\n");
    else
        Print("Vole wrapper=direct  TIMEOUT (>90s)\n");
    fi;

    r_byorb := IO_CallWithTimeout(rec(seconds := 90), function(g, m)
        local t1, sz;
        t1 := NanosecondsSinceEpoch();
        sz := Size(Vole.Normalizer(SymmetricGroup(m), g : wrapper := "ByOrbits"));
        return [sz, Int((NanosecondsSinceEpoch() - t1) / 1000000)];
    end, H, n);
    if Length(r_byorb) >= 2 and r_byorb[1] = true then
        Print("Vole wrapper=ByOrbits |N|=", r_byorb[2][1],
              "  ", r_byorb[2][2], " ms\n");
    else
        Print("Vole wrapper=ByOrbits TIMEOUT (>90s)\n");
    fi;
end;

_TimeOne("D_8^3 sample 2", 4, 2);
_TimeOne("S_4^4 sample 1", 12, 1);
_TimeOne("S_4^4 sample 2", 12, 2);
_TimeOne("D_8^5 sample 2", 13, 2);

QUIT;
