# Example/benchmark: pairs of transformations up to conjugacy, the readable way.
#
# We classify unordered pairs {a, b} of transformations on [1 .. n] up to
# simultaneous S_n-conjugacy: {a, b} ~ {a', b'} iff some g in S_n has
# {a ^ g, b ^ g} = {a', b'}. A conjugacy refiner plus VoleFind.CanonicalPerm
# gives a canonical form -- one refiner for a single transformation, two wrapped
# in VoleRefiner.SetOf for an unordered pair (the same canonical permutation is
# applied to both members).
#
# The point of the example is the search-space cut, and *why it is exactly this
# cut and no more*:
#   * Every pair-class has a representative whose ONE chosen member is canonical
#     (conjugate the pair by the permutation that canonises that member). So it
#     suffices to range the first member over the single-class representatives
#     and the second over the whole monoid -- |singles| * |M| pairs, not |M|^2.
#   * You may NOT canonise BOTH members in advance: the permutation that canonises
#     a pair need not canonise either member alone. E.g. the pair of distinct
#     transpositions {(1,2),(1,3)} has no conjugate in which both members equal
#     the canonical transposition (1,2), since conjugation keeps them distinct --
#     so a "pair of canonical reps" enumeration would miss its class.
#
# This is deliberately the simple, no-group-work formulation (no stabilisers):
# just canonical images via SetOf, with GAP's Orbits as the correctness oracle.
# It is not built for reach -- SetOf canonical images cost ~ms each, so n = 5 is
# already heavy -- it is built to read top to bottom.
#
# Run (default cap n = 4):
#   gap -q -c 'Read("tst/benchmarks/pairs-one-canonical.g"); QUIT;'
#   gap -q -c 'PAIRS_ONE_CANONICAL_MAXN := 5;; \
#              Read("tst/benchmarks/pairs-one-canonical.g"); QUIT;'
# The GAP orbit cross-check is only run while it is cheap (n <= 4).

LoadPackage("vole", false);

if not IsBoundGlobal("PAIRS_ONE_CANONICAL_MAXN") then
    PAIRS_ONE_CANONICAL_MAXN := 4;
fi;

# Canonical form of one transformation t under S_n-conjugacy.
_PairsCanon1 := {t, S} -> t ^ VoleFind.CanonicalPerm(S,
                                GB_Con.TransformationConjugacy(t, t));

# Canonical form of the unordered pair {a, b} under simultaneous conjugacy.
_PairsCanonPair := function(a, b, S)
    local c;
    c := VoleFind.CanonicalPerm(S, VoleRefiner.SetOf(
           [GB_Con.TransformationConjugacy(a, a),
            GB_Con.TransformationConjugacy(b, b)]));
    return Set([a ^ c, b ^ c]);
end;

_PairsOneCanonicalRun := function(maxN)
    local n, S, M, t, singles, pairs, ms, gapCount, ok;
    Print("n  |M|  singles  pairs  gap_check  wall_s\n");
    for n in [2 .. maxN] do
        S := SymmetricGroup(n);
        M := Elements(FullTransformationMonoid(n));
        t := NanosecondsSinceEpoch();
        # one member canonical, the other ranging over all of M
        singles := Set(M, x -> _PairsCanon1(x, S));
        pairs := Set(Filtered(Cartesian(singles, M), p -> p[1] <> p[2]),
                     p -> _PairsCanonPair(p[1], p[2], S));
        ms := Int((NanosecondsSinceEpoch() - t) / 1000000000);
        # oracle: GAP orbits of distinct unordered pairs (only while cheap)
        if n <= 4 then
            gapCount := Length(Orbits(S, Combinations(M, 2),
                {p, g} -> Set([p[1] ^ g, p[2] ^ g])));
            ok := String(Length(pairs) = gapCount);
        else
            ok := "skipped";
        fi;
        Print(StringFormatted("{}  {}  {}  {}  {}  {}\n",
              n, Length(M), Length(singles), Length(pairs), ok, ms));
    od;
end;

_PairsOneCanonicalRun(PAIRS_ONE_CANONICAL_MAXN);
