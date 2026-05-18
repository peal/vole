# Bank driver.
#
# Usage:
#   gap -q -c 'Read("tst/bank/run-bank.g"); RunBank("quick"); QUIT;'
#
# Modes: "quick" (≤ 1 min, PR gate), "nightly" (≤ 30 min), "full" (hours).

LoadPackage("vole", false);
LoadPackage("transgrp", false);
LoadPackage("primgrp", false);
LoadPackage("smallgrp", false);

Read("tst/bank/helpers.g");
Read("tst/bank/transgrp.g");
Read("tst/bank/primgrp.g");
Read("tst/bank/smallgrp.g");
Read("tst/bank/intransitive.g");
Read("tst/bank/random.g");
Read("tst/bank/variants.g");
Read("tst/bank/canonical_groups.g");
Read("tst/bank/regression.g");
Read("tst/bank/jnp.g");
Read("tst/bank/directprod.g");

# Each runner returns `true` iff all its checks passed.
RunBank := function(mode)
    local results, overall;
    results := rec();
    results.transgrp     := RunBank_transgrp(mode);
    results.primgrp      := RunBank_primgrp(mode);
    results.smallgrp     := RunBank_smallgrp(mode);
    results.intransitive := RunBank_intransitive(mode);
    results.random       := RunBank_random(mode);
    results.variants     := RunBank_variants(mode);
    results.canonical    := RunBank_canonical_groups(mode);
    results.regression   := RunBank_regression(mode);
    results.jnp          := RunBank_jnp(mode);
    results.directprod   := RunBank_directprod(mode);

    overall := ForAll(RecNames(results), n -> results.(n));
    Print(StringFormatted("\n=== Bank result (mode={}) ===\n", mode));
    Print(StringFormatted("Per-source: {}\n", results));
    Print(StringFormatted("Overall: {}\n", overall));
    return overall;
end;
