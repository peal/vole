# Canonical-image-of-group consistency sweep.
#
# For each group G in TransitiveGroups (and PrimitiveGroups) up to a
# degree cap, conjugate G by `num_conjugates` random perms π ∈ S_n
# and assert that Vole.CanonicalImage gives the same group for G and
# every G^π. Random perms come from a seeded RandomSource so failures
# are reproducible.
#
# Test every refiner variant we expose for normaliser search. This
# catches bugs that affect canonical search even when the normaliser
# itself comes out right (e.g. a search-tree non-determinism).

if not IsBoundGlobal("BankCompareCanonicalGroup") then
    Read("tst/bank/helpers.g");
fi;

# Number of random conjugates to test per (group, variant) pair.
BankCanonicalConjugatesPerGroup := function(mode)
    if mode = "quick" then
        return 2;
    elif mode = "nightly" then
        return 5;
    elif mode = "full" then
        return 10;
    else
        Error("BankCanonicalConjugatesPerGroup: unknown mode ", mode);
    fi;
end;

# Variants that ARE canonical-safe — `Vole.CanonicalImage` on conjugate
# groups produces equal results. New refiner variants should be added
# here once verified.
BankCanonicalSafeVariants := ["default", "Orbital"];

# Variants that are KNOWN canonical-unsafe (symmetry-correct but
# canonical mode can return conjugate-not-equal canonicals). Listed
# explicitly so a regression that re-introduces canonical-safety can
# be detected (we'd see the variant pass a check we'd marked as
# expected-to-fail). The current canonical-unsafe variant family is
# `OrbitalRegOrbit` — see notes in normaliser.g.
BankCanonicalUnsafeVariants := ["OrbitalRegOrbit", "OrbitalRegOrbitChar"];

BankCanonicalVariants := BankCanonicalSafeVariants;

RunBank_canonical_groups := function(mode)
    local cap, n, k, G, num, conj, rs, variant;
    cap := BankDegreeCap(mode);
    conj := BankCanonicalConjugatesPerGroup(mode);
    BankResetStats();
    Print(StringFormatted(
        "[canonical_groups] mode={}, degree cap={}, conjugates per group={}\n",
        mode, cap, conj));

    # Deterministic, reproducible failures: seed the RNG once per mode.
    rs := RandomSource(IsMersenneTwister, 20260517);

    for n in [2 .. cap] do
        num := NrTransitiveGroups(n);
        Print(StringFormatted(
            "[canonical_groups/transgrp] n={}, NrTransitiveGroups={}\n",
            n, num));
        for k in [1 .. num] do
            if BankShouldRun("transgrp", [n, k]) then
                G := TransitiveGroup(n, k);
                for variant in BankCanonicalVariants do
                    BankCompareCanonicalGroup(n, G, rs, conj, variant);
                od;
            fi;
        od;
    od;

    BankReportStats("canonical_groups");
    return _BankStats.fail = 0;
end;
