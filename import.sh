#!/usr/bin/env bash

rm -rf dependancies
mkdir dependancies
cp -r ../BacktrackKit ../GraphBacktracking dependancies

for i in BacktrackKit GraphBacktracking; do
(
    cd dependancies/$i &&
    rm -rf PackageInfo.g makedoc.g README.md examples tst doc .git* .release .codecov.yml gh-pages
)
done