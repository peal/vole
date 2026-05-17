# Top-level driver for the loss hunt.
# Usage:
#   gap -q -c 'BUDGET := 60; Read("tst/benchmarks/run-hunt.g"); QUIT;'
# Defaults to 30s/call.

LoadPackage("vole", false);
LoadPackage("io", false);
LoadPackage("transgrp", false);
LoadPackage("primgrp", false);

Read("tst/benchmarks/hunt.g");

if not IsBoundGlobal("BUDGET") then
    BUDGET := 30;
fi;

RunHunt(BUDGET);
