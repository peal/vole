#!/usr/bin/env bash

rm -rf dependencies
mkdir dependencies
cp -r ../BacktrackKit ../GraphBacktracking dependencies

for i in BacktrackKit GraphBacktracking; do
(
    cd dependencies/$i &&
    rm -rf PackageInfo.g makedoc.g README.md examples tst doc .git* .release .codecov.yml gh-pages
)
done