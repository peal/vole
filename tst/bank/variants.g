# Variant cross-check.
#
# The main bank validates Vole.Normalizer (which dispatches to the
# default `Orbital` variant) against GAP's Normalizer. This file
# additionally validates that EVERY variant — Simple, Simple2,
# OrbitalNone, OrbitalRoot, Orbital, OrbitalDeep, OrbitalSmall —
# produces the same normaliser group on a sample of inputs. This
# catches bugs in non-default variants that bank's main sweep wouldn't.
#
# Sample size is small in quick mode to keep CI cheap; nightly does
# more.

if not IsBoundGlobal("BankCompareNormaliser") then
    Read("tst/bank/helpers.g");
fi;

# Variants to compare. Keep this in sync with helpers in
# tst/benchmarks/helpers.g.
BankAllVariantNames     := ["Simple", "Simple2", "OrbitalNone",
                             "OrbitalRoot", "Orbital", "OrbitalDeep",
                             "OrbitalSmall", "OrbitalRegOrbit"];
BankFastVariantNames    := ["OrbitalRoot", "Orbital", "OrbitalDeep",
                             "OrbitalSmall", "OrbitalRegOrbit"];

# Returns true iff every variant in `variantNames` produces a group equal
# to GAP's Normalizer(SymmetricGroup(n), G). Failures dumped to stdout.
BankCheckVariants := function(n, G, problem_id, variantNames)
    local gapResult, v, refiner, voleResult, failed;
    gapResult := Normalizer(SymmetricGroup(n), G);
    failed := false;
    for v in variantNames do
        refiner := GB_Con.(Concatenation("Normaliser", v))(G);
        voleResult := VoleFind.Group(SymmetricGroup(n), refiner);
        if voleResult <> gapResult then
            failed := true;
            _BankStats.fail := _BankStats.fail + 1;
            Print(StringFormatted(
                "FAIL (bank/variants): {} variant={}, " ,
                "|G|={}, |gap N|={}, |vole N|={}\n",
                problem_id, v, Size(G), Size(gapResult),
                Size(voleResult)));
        fi;
    od;
    if not failed then
        _BankStats.pass := _BankStats.pass + 1;
    fi;
    return not failed;
end;

# Counts for sampling. Two pools:
# - `all_low_degree`: where ALL variants (including brute-force Simple
#   etc.) are fast enough to run. Caps degree at 8 in quick mode.
# - `fast_high_degree`: degrees where only orbital-pushing variants
#   complete in time; we test only those.
BankVariantsSampleCounts := function(mode)
    if mode = "quick" then
        return rec(
            all_degree_cap := 8,
            all_count := 20,
            fast_degree_cap := 12,
            fast_count := 15);
    elif mode = "nightly" then
        return rec(
            all_degree_cap := 10,
            all_count := 100,
            fast_degree_cap := 16,
            fast_count := 80);
    elif mode = "full" then
        return rec(
            all_degree_cap := 12,
            all_count := 500,
            fast_degree_cap := 20,
            fast_count := 400);
    else
        Error("BankVariantsSampleCounts: unknown mode ", mode);
    fi;
end;

# Sample `count` indices deterministically from [1..total] (uniform stride).
_BankUniformSample := function(total, count)
    if total <= count then
        return [1 .. total];
    fi;
    return Set(List([1 .. count],
        i -> 1 + QuoInt((i - 1) * total, count)));
end;

# Collect input tuples [n, k] for one source (transgrp or primgrp) up to
# the given degree cap, skipping known-hang entries for transgrp.
_BankCollectInputs := function(source, cap)
    local res, n, k, num, NrFn;
    if source = "transgrp" then
        NrFn := NrTransitiveGroups;
    elif source = "primgrp" then
        NrFn := NrPrimitiveGroups;
    else
        Error("_BankCollectInputs: unknown source ", source);
    fi;
    res := [];
    for n in [2 .. cap] do
        num := NrFn(n);
        for k in [1 .. num] do
            if BankIsKnownHang(source, [n, k]) = fail then
                Add(res, [n, k]);
            fi;
        od;
    od;
    return res;
end;

# Run BankCheckVariants over a sampled subset of inputs from one source.
_BankRunSubset := function(source, degreeCap, count, variantNames, label)
    local pool, sampleIdx, idx, n, k, G, problem_id;
    pool := _BankCollectInputs(source, degreeCap);
    sampleIdx := _BankUniformSample(Length(pool), count);
    Print(StringFormatted(
        "[variants/{}/{}] {} inputs from {} available\n",
        source, label, Length(sampleIdx), Length(pool)));
    for idx in sampleIdx do
        n := pool[idx][1];
        k := pool[idx][2];
        if source = "transgrp" then
            G := TransitiveGroup(n, k);
            problem_id := StringFormatted("TransGrp({},{})", n, k);
        else
            G := PrimitiveGroup(n, k);
            problem_id := StringFormatted("PrimGrp({},{})", n, k);
        fi;
        BankCheckVariants(n, G, problem_id, variantNames);
    od;
end;

RunBank_variants := function(mode)
    local counts;
    counts := BankVariantsSampleCounts(mode);
    BankResetStats();

    # Lower-degree pool: test all variants (including brute-force ones).
    _BankRunSubset("transgrp", counts.all_degree_cap, counts.all_count,
                    BankAllVariantNames, "all-variants");
    _BankRunSubset("primgrp",  counts.all_degree_cap, counts.all_count,
                    BankAllVariantNames, "all-variants");

    # Higher-degree pool: only test the orbital-pushing variants. The
    # brute-force ones would time out without giving us useful coverage.
    _BankRunSubset("transgrp", counts.fast_degree_cap, counts.fast_count,
                    BankFastVariantNames, "fast-variants");
    _BankRunSubset("primgrp",  counts.fast_degree_cap, counts.fast_count,
                    BankFastVariantNames, "fast-variants");

    BankReportStats("variants");
    return _BankStats.fail = 0;
end;
