#!/bin/bash

set -euo pipefail

cargo test --release -q

( for i in gap-code/tst/*.tst; do
        echo gap -A -q -c "'QUIT_GAP(Test(\"$i\"));'"
    done ) | parallel --progress

echo "Tests all passed!"