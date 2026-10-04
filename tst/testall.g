#
# Vole: Backtrack search in permutation groups with graphs
#
# This file runs package tests. It is also referenced in the package
# metadata in PackageInfo.g.
#
# Prefer bundled refiners on a fresh package load.
# Ferret must declare its shared IsConstraint category before BacktrackKit.
# Assisted-by: OpenAI Codex (GPT-6), bundled-dependency test coverage.
if TestPackageAvailability("ferret", "") <> fail then
    LoadPackage("ferret", false);
fi;
LoadPackage("vole", false : OnlyNeeded);

TestDirectory(DirectoriesPackageLibrary( "Vole", "tst" ),
  rec(exitGAP := true, testOptions := rec(compareFunction := "uptowhitespace")));

FORCE_QUIT_GAP(1); # if we ever get here, there was an error
