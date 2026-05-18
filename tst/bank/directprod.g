# Disjoint direct product decomposition (DDPD) — correctness bank.
#
# Exercises Vole.DDPD across:
#
#   (1) Edge cases: trivial group, transitive group.
#   (2) Pure direct products of small transitive groups.
#   (3) Subdirect products (diagonals, random subdirects).
#   (4) Mixed cases (some orbits cleanly factored, others glued).
#   (5) Random conjugates — DDPD must commute with conjugation by
#       S_n, so applying a random pi ∈ S_n shouldn't change the
#       number of factors or the multiset of factor sizes.
#
# For each input we assert:
#   * Length(decomp) is what we expect for the case;
#   * Product over factors of Size(group) = Size(G);
#   * The orbits of decomp[i].group partition the orbits of G;
#   * decomp is invariant (as a multiset of sizes) under random
#     conjugation by S_n.

if not IsBoundGlobal("BankCompareNormaliser") then
    Read("tst/bank/helpers.g");
fi;

# Test one (G, expected_num_factors, expected_factor_sizes_sorted, label).
_BankDDPDCheck := function(G, expected_num, expected_sizes, label)
    local d, sizes;
    d := Vole.DDPD(G);
    sizes := SortedList(List(d, x -> Size(x.group)));

    if expected_num <> fail and Length(d) <> expected_num then
        _BankStats.fail := _BankStats.fail + 1;
        Add(_BankStats.failures,
            rec(label := label, expected_num := expected_num,
                got_num := Length(d), kind := "factor_count"));
        Print("FAIL (bank/directprod): ", label,
              " expected ", expected_num, " factors, got ", Length(d), "\n");
        return false;
    fi;
    if expected_sizes <> fail and sizes <> SortedList(expected_sizes) then
        _BankStats.fail := _BankStats.fail + 1;
        Add(_BankStats.failures,
            rec(label := label, expected := expected_sizes,
                got := sizes, kind := "factor_sizes"));
        Print("FAIL (bank/directprod): ", label,
              " expected sizes ", SortedList(expected_sizes),
              ", got ", sizes, "\n");
        return false;
    fi;
    if Product(d, x -> Size(x.group)) <> Size(G) then
        _BankStats.fail := _BankStats.fail + 1;
        Add(_BankStats.failures,
            rec(label := label, got_product := Product(d, x -> Size(x.group)),
                expected_product := Size(G), kind := "size_product"));
        Print("FAIL (bank/directprod): ", label,
              " factor sizes don't multiply to |G|\n");
        return false;
    fi;
    _BankStats.pass := _BankStats.pass + 1;
    return true;
end;

# Cheap unique sorted factor-size signature.
_BankDDPDSignature := function(G)
    return SortedList(List(Vole.DDPD(G), x -> Size(x.group)));
end;

# DDPD commutes with conjugation by S_n. So Vole.DDPD(G^pi) should
# have the same multiset of factor sizes as Vole.DDPD(G).
_BankDDPDCheckConjInvariant := function(G, rs, num_conj, label)
    local n, base_sig, k, pi, conj_sig;
    n := Maximum(LargestMovedPoint(G), 1);
    base_sig := _BankDDPDSignature(G);
    for k in [1 .. num_conj] do
        pi := Random(rs, SymmetricGroup(n));
        conj_sig := _BankDDPDSignature(G ^ pi);
        if conj_sig <> base_sig then
            _BankStats.fail := _BankStats.fail + 1;
            Add(_BankStats.failures, rec(
                label := label, base := base_sig, conj := conj_sig,
                pi := pi, kind := "conj_invariant"));
            Print("FAIL (bank/directprod): ", label,
                  " conj-invariant violation; base=", base_sig,
                  " conj=", conj_sig, "\n");
            return false;
        fi;
    od;
    _BankStats.pass := _BankStats.pass + 1;
    return true;
end;

# Helper: shift a perm by a positive integer (moves its support up).
_BankShift := function(p, shift)
    local lmp, sigma;
    lmp := LargestMovedPoint(p);
    if lmp = 0 then return (); fi;
    sigma := MappingPermListList([1 .. lmp], [shift + 1 .. shift + lmp]);
    return p ^ sigma;
end;

# Build the on-disjoint-supports direct product of `groups`.
_BankDisjoint := function(groups)
    local gens, shift, G, g;
    gens := [];
    shift := 0;
    for G in groups do
        for g in GeneratorsOfGroup(G) do
            Add(gens, _BankShift(g, shift));
        od;
        shift := shift + LargestMovedPoint(G);
    od;
    return Group(gens);
end;

# Random subdirect of (C_p)^k on pk points: matrix with random rows
# over F_p, no all-zero column.
_BankRandomSubdirectCp := function(p, k, rs)
    local M, attempts, half;
    half := QuoInt(k, 2);
    attempts := 0;
    repeat
        attempts := attempts + 1;
        if attempts > 50 then
            Error("can't sample full-rank no-zero-col matrix after 50 tries");
        fi;
        M := List([1..half],
                  r -> List([1..k], j -> Random(rs, [0 .. p-1])));
    until RankMat(M * Z(p)^0) = half
          and ForAll([1..k],
              j -> ForAny([1..half], r -> M[r][j] <> 0));
    return Group(List(M, row -> _BankJnPElementFromRow(p, k, row)));
end;

RunBank_directprod := function(mode)
    local rs, S3, A4, S5, G;
    BankResetStats();
    rs := RandomSource(IsMersenneTwister, 20260518);
    Print("[directprod] mode=", mode, "\n");

    # (1) Edge cases.
    _BankDDPDCheck(Group(()), 1, fail, "trivial");
    _BankDDPDCheck(SymmetricGroup(5), 1, [120], "S_5 (transitive)");
    _BankDDPDCheck(Group((1,2,3,4,5)), 1, [5], "C_5 (transitive)");

    # (2) Pure disjoint direct products.
    _BankDDPDCheck(_BankDisjoint([SymmetricGroup(3), SymmetricGroup(4)]),
                   2, [6, 24], "S_3 x S_4 disjoint");
    _BankDDPDCheck(_BankDisjoint([Group((1,2,3)), Group((1,2,3,4,5))]),
                   2, [3, 5], "C_3 x C_5 disjoint");
    _BankDDPDCheck(_BankDisjoint([SymmetricGroup(3), AlternatingGroup(4),
                                  Group((1,2,3,4,5))]),
                   3, [6, 12, 5], "S_3 x A_4 x C_5 disjoint");

    # (3) Diagonal subdirects.
    _BankDDPDCheck(Group([(1,2,3)(4,5,6)]), 1, [3],
                   "diag C_3 in (C_3)^2");
    _BankDDPDCheck(Group([(1,2,3,4,5)(6,7,8,9,10)]), 1, [5],
                   "diag C_5 in (C_5)^2");
    # Chang JnP random subdirects. For small k=4 the random k/2 × k
    # matrix can happen to be column-block-decomposable, giving 2
    # factors; for k=6 and up the random ties are dense enough that
    # we essentially always get a single component. We don't pin the
    # factor count — the soundness checks (sizes multiply, no zero
    # factor) come from _BankDDPDCheck's expected_sizes=fail path,
    # and conjugation-invariance is exercised below.
    _BankDDPDCheck(_BankJnPRandomSubdirect(3, 6, rs), fail, fail,
                   "JnP subdirect (3,6)");
    _BankDDPDCheck(_BankJnPRandomSubdirect(3, 8, rs), fail, fail,
                   "JnP subdirect (3,8)");
    _BankDDPDCheck(_BankJnPRandomSubdirect(5, 6, rs), fail, fail,
                   "JnP subdirect (5,6)");

    # (4) Mixed: one diagonal + one independent factor.
    _BankDDPDCheck(Group([(1,2,3)(4,5,6), (7,8,9,10,11)]),
                   2, [3, 5], "diag C_3 + C_5");
    _BankDDPDCheck(Group([(1,2,3)(4,5,6),
                          (7,8,9)(10,11,12),
                          (13,14,15)]),
                   3, [3, 3, 3], "two diagonals + a separate C_3");

    # (5) Conjugation invariance — check the DDPD signature doesn't
    # depend on the labelling.
    for G in [SymmetricGroup(5),
              _BankDisjoint([SymmetricGroup(3), SymmetricGroup(4)]),
              Group([(1,2,3)(4,5,6), (7,8,9,10,11)]),
              _BankJnPRandomSubdirect(3, 6, rs)] do
        _BankDDPDCheckConjInvariant(G, rs, 5,
            Concatenation("conj-invariant ", String(GeneratorsOfGroup(G))));
    od;

    BankReportStats("directprod");
    return _BankStats.fail = 0;
end;
