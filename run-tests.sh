#!/bin/bash

set -euo pipefail

(cd rust && cargo test --release -q)

( for i in tst/*.tst; do
        echo gap -r -q -c "'QUIT_GAP(Test(\"$i\"));'"
    done ) | parallel --progress

echo "Tests all passed!"
