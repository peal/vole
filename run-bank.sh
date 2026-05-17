#!/bin/bash
# Run the Vole correctness bank against GAP as source of truth.
#
# Usage:
#   ./run-bank.sh            # default: quick (PR-gate budget, ≤ 1 min)
#   ./run-bank.sh quick
#   ./run-bank.sh nightly    # ≤ 30 min, intended for unattended CI
#   ./run-bank.sh full       # hours, manual / release
#
# The bank is a *living* artefact — see tst/bank/README.md for how to
# add new bank sources and how degree caps are bumped over time.

set -euo pipefail

MODE="${1:-quick}"

case "$MODE" in
    quick|nightly|full) ;;
    *)
        echo "run-bank.sh: unknown mode '$MODE' (expected: quick, nightly, full)" >&2
        exit 2
        ;;
esac

(echo "Building Vole..." && cd rust && cargo build --release -q)

# Bank driver prints "Overall: true" when all sources pass.
OUT=$(gap -r -q -c "Read(\"tst/bank/run-bank.g\"); ok := RunBank(\"$MODE\"); if ok then QUIT_GAP(0); else QUIT_GAP(1); fi;" 2>&1)
ST=$?
echo "$OUT"
if [ "$ST" -eq 0 ]; then
    echo "Bank ($MODE) passed."
else
    echo "Bank ($MODE) FAILED with exit $ST."
fi
exit "$ST"
