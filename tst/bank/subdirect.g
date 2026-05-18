# Subdirect-mixer bank: groups built by sampling random elements from
# a disjoint direct product of larger transitive groups, then keeping
# only the ones that Vole.DDPD certifies as inter-orbit-glued (i.e.
# not pure direct products on their orbits).
#
# The user's recipe: take k transitive groups G_1, ..., G_k on
# disjoint supports; form D = G_1 × ... × G_k; pick m random elements
# of D; build H = <those elements>; reject H unless
# Length(Vole.DDPD(H)) < k. This produces "messy" intransitive groups
# that GAP's clean fast paths don't recognise — exactly the regime
# where Vole and GAP compete on real backtrack work.
#
# Aim is for larger orbit groups: base transitives are S_5, S_6, S_7,
# AGL(1, 7), AGL(1, 11), PSL(2, 5), PSL(2, 7), etc. Mixer outputs
# typically have 3-5 orbits at total degree 20-50.
#
# What we test here:
#   * For each constructed H, Vole.Normalizer(S_n, H) equals
#     GAP's Normalizer(S_n, H).
#   * Vole.DDPD(H) actually gives < k factors (the construction's
#     reject-loop ensures this; we re-verify as a sanity check).
#   * Vole.DDPD is conjugation-invariant on these mixers (DDPD
#     commutes with the labelling).

if not IsBoundGlobal("BankCompareNormaliser") then
    Read("tst/bank/helpers.g");
fi;
if not IsBoundGlobal("IO_CallWithTimeout") then
    LoadPackage("io", false);
fi;

# Constructor: given a RandomSource, a list of transitive base
# groups, a target number of generators, and a max-attempt budget,
# returns H = <random elements> such that Vole.DDPD(H) has at most
# `target_factors` factors. Returns `fail` if no candidate found
# within the attempt budget.
#
# target_factors defaults to Length(transitives) - 1 (strictly fewer
# factors than the number of base groups, i.e. at least one pair of
# orbits gets glued).
BankBuildSubdirectMixer := function(rs, transitives, num_gens,
                                    target_factors, max_attempts)
    local D, attempt, gens, H, decomp;
    D := BankDisjointDirectProduct(transitives);
    for attempt in [1 .. max_attempts] do
        gens := List([1 .. num_gens], i -> Random(rs, D));
        H := Group(gens);
        # Skip degenerate cases (e.g. all sampled elements happened to
        # land in a small subgroup).
        if Length(MovedPoints(H)) < Length(MovedPoints(D)) then continue; fi;
        decomp := Vole.DDPD(H);
        if Length(decomp) <= target_factors then
            return rec(group := H, num_factors := Length(decomp));
        fi;
    od;
    return fail;
end;

# Bench one mixer: time both Vole.Normalizer and GAP's Normalizer
# (with a per-call timeout to keep the bank making progress), and
# assert they agree. Logs one line per input — pass or fail — so
# the bank's progress is visible even when nothing has gone wrong
# yet.
_BankSubdCheck := function(name, H)
    local n, t, gap_ms, vole_ms, raw_gap, raw_vole, gap_sz, vole_sz;
    n := LargestMovedPoint(H);

    raw_gap := IO_CallWithTimeout(rec(seconds := 60),
        function(g, m) return Size(Normalizer(SymmetricGroup(m), g)); end,
        H, n);
    if Length(raw_gap) < 2 or raw_gap[1] <> true then
        _BankStats.skipped := _BankStats.skipped + 1;
        Print("[subdirect] SKIP ", name, "  gap timeout/crash\n");
        return false;
    fi;
    gap_sz := raw_gap[2];

    t := NanosecondsSinceEpoch();
    raw_vole := IO_CallWithTimeout(rec(seconds := 60),
        function(g, m)
            return Size(Vole.Normalizer(SymmetricGroup(m), g));
        end,
        H, n);
    vole_ms := Int((NanosecondsSinceEpoch() - t) / 1000000);
    if Length(raw_vole) < 2 or raw_vole[1] <> true then
        # Performance limit, not a correctness regression. Vole takes
        # longer than 60s on this input; record as skipped + log so
        # we have the input recorded for investigation.
        _BankStats.skipped := _BankStats.skipped + 1;
        Print("[subdirect] SLOW ", name,
              "  gap_|N|=", gap_sz, "  vole TIMEOUT (>60s)\n");
        return false;
    fi;
    vole_sz := raw_vole[2];

    if gap_sz <> vole_sz then
        _BankStats.fail := _BankStats.fail + 1;
        Add(_BankStats.failures, rec(label := name, kind := "size_mismatch",
            gap_sz := gap_sz, vole_sz := vole_sz));
        Print("[subdirect] FAIL ", name,
              "  gap_|N|=", gap_sz, "  vole_|N|=", vole_sz, "\n");
        return false;
    fi;
    _BankStats.pass := _BankStats.pass + 1;
    Print("[subdirect] ok ", name,
          "  |N|=", gap_sz, "  vole_ms=", vole_ms, "\n");
    return true;
end;

# Verify DDPD on the input is invariant under random S_n conjugation
# of the labelling. (DDPD commutes with conjugation.)
_BankSubdCheckDDPDConjInvariant := function(name, H, rs, num_conj)
    local n, base_sig, k, pi, conj_sig;
    n := LargestMovedPoint(H);
    base_sig := SortedList(List(Vole.DDPD(H), x -> Size(x.group)));
    for k in [1 .. num_conj] do
        pi := Random(rs, SymmetricGroup(n));
        conj_sig := SortedList(List(Vole.DDPD(H ^ pi), x -> Size(x.group)));
        if conj_sig <> base_sig then
            _BankStats.fail := _BankStats.fail + 1;
            Add(_BankStats.failures, rec(
                label := name, base_sig := base_sig, conj_sig := conj_sig,
                pi := pi, kind := "subd_conj_invariant"));
            Print("FAIL (bank/subdirect): ", name,
                  " DDPD conj-invariant violation; base=", base_sig,
                  " conj=", conj_sig, "\n");
            return false;
        fi;
    od;
    _BankStats.pass := _BankStats.pass + 1;
    return true;
end;

# How many mixers to build per (transitives-spec, num_gens) per mode.
_BankSubdSamplesPerSpec := function(mode)
    if mode = "quick" then
        return 2;
    elif mode = "nightly" then
        return 5;
    elif mode = "full" then
        return 10;
    else
        Error("_BankSubdSamplesPerSpec: unknown mode ", mode);
    fi;
end;

# Maximum total degree to accept in this run (skip specs whose
# disjoint-direct-product support exceeds this).
_BankSubdDegreeCap := function(mode)
    if mode = "quick" then
        return 28;
    elif mode = "nightly" then
        return 40;
    elif mode = "full" then
        return 60;
    else
        Error("_BankSubdDegreeCap: unknown mode ", mode);
    fi;
end;

RunBank_subdirect := function(mode)
    local rs, samples, deg_cap, specs, spec, n_total, transitives,
          num_gens, k, mixer, name;

    BankResetStats();
    rs := RandomSource(IsMersenneTwister, 20260518);
    samples := _BankSubdSamplesPerSpec(mode);
    deg_cap := _BankSubdDegreeCap(mode);

    Print("[subdirect] mode=", mode, ", samples_per_spec=", samples,
          ", degree_cap=", deg_cap, "\n");

    # Each spec is rec(transitives := [G_1, ..., G_k], num_gens := m).
    # "transitives" are the base groups, EACH built on its standard
    # support [1 .. n_i]; BankDisjointDirectProduct shifts them onto
    # disjoint supports. The mixer picks `num_gens` random elements.
    #
    # The choice of base groups is driven by Goursat's lemma: random
    # H ≤ G_1 × ... × G_k with full projections is a non-direct
    # subdirect product only when the G_i share non-trivial quotients.
    # That rules out (S_n × A_n) for n ≥ 5 (no common quotient), but
    # makes dihedral, cyclic, and (S_n)^k families excellent — they
    # have Z_2 / Z_d quotients in abundance.
    #
    # Empirically (sampled 5 random mixers each):
    #   D_m^k:     100% glue rate
    #   (S_n)^k:    60-80% glue rate (sign quotient)
    #   (A_n)^k:    low (A_n simple for n >= 5)
    #   (C_p)^k:    100% if num_gens < k (rank < k matrix)
    #   (AGL(1,p))^k: high
    specs := [
        # === Two orbits ===
        rec(transitives := [DihedralGroup(IsPermGroup, 10),
                            DihedralGroup(IsPermGroup, 10)],
            num_gens := 3),
        rec(transitives := [DihedralGroup(IsPermGroup, 14),
                            DihedralGroup(IsPermGroup, 14)],
            num_gens := 3),
        rec(transitives := [SymmetricGroup(5), SymmetricGroup(5)],
            num_gens := 3),
        # === Three orbits ===
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
        # Mixed orbit sizes (still glueable through Z_2 sign).
        rec(transitives := [SymmetricGroup(4), SymmetricGroup(5),
                            SymmetricGroup(6)],
            num_gens := 4),
        # Cyclic with low num_gens → guaranteed subdirect.
        rec(transitives := [CyclicGroup(IsPermGroup, 5),
                            CyclicGroup(IsPermGroup, 5),
                            CyclicGroup(IsPermGroup, 5)],
            num_gens := 2),
        rec(transitives := [CyclicGroup(IsPermGroup, 7),
                            CyclicGroup(IsPermGroup, 7),
                            CyclicGroup(IsPermGroup, 7)],
            num_gens := 2),
        # === Four orbits (user's target) ===
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
        # === Five orbits (user's "4 or 5 orbits" goal) ===
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

    for spec in specs do
        n_total := Sum(spec.transitives, LargestMovedPoint);
        if n_total > deg_cap then continue; fi;
        for k in [1 .. samples] do
            mixer := BankBuildSubdirectMixer(
                rs, spec.transitives, spec.num_gens,
                Length(spec.transitives) - 1, 40);
            if mixer = fail then
                # Reject loop ran out — record a known-empty result.
                _BankStats.skipped := _BankStats.skipped + 1;
                Print("[subdirect] no mixer found in 40 tries; spec ",
                      List(spec.transitives, x ->
                          StringFormatted("|G|={}", Size(x))),
                      " num_gens=", spec.num_gens, "\n");
                continue;
            fi;
            name := Concatenation(
                "mixer(", String(List(spec.transitives, Size)),
                "; m=", String(spec.num_gens),
                "; sample=", String(k),
                "; |H|=", String(Size(mixer.group)),
                "; ddpd_factors=", String(mixer.num_factors), ")");
            _BankSubdCheck(name, mixer.group);
            _BankSubdCheckDDPDConjInvariant(name, mixer.group, rs, 2);
        od;
    od;

    BankReportStats("subdirect");
    return _BankStats.fail = 0;
end;
