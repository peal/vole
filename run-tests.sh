#!/bin/bash

set -euo pipefail

(echo "Building Vole..." && cd rust && cargo test --release -q)


if which parallel 2> /dev/null; then
    ( for i in tst/*.tst; do
            echo gap -r -q -c "'QUIT_GAP(Test(\"$i\", rec(compareFunction := \"uptowhitespace\")));'"
        done ) | parallel --progress
else
    for i in tst/*.tst; do
        gap -r -q -c 'QUIT_GAP(Test("'$i'", rec(compareFunction := \"uptowhitespace\")));'
    done
fi;


echo "Tests all passed!"
