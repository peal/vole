# Vole: Backtrack search in permutation groups with graphs
# A GAP package by Mun See Chang, Christopher Jefferson, and Wilf A. Wilson.
#
# SPDX-License-Identifier: MPL-2.0
#
# Reading the declaration part of the package.

# Vole bundles (vendors) copies of BacktrackKit and GraphBacktracking under
# dependencies/, purely as a fallback for users who do not have them installed
# as separate packages.
#
# Defer to external packages only when GAP has marked them for loading.
# Installed suggested packages are skipped by OnlyNeeded. Checking the loading
# plan also handles the BacktrackKit -> images -> Vole dependency cycle before
# all packages have finished loading.
_BT_SKIP_INTERFACE := true;
if not IsPackageMarkedForLoading("BacktrackKit", "1.2.0") then
    _ReadBTPackage := {f} -> ReadPackage("Vole", Concatenation("dependencies/BacktrackKit/", f));
    ReadPackage("Vole", "dependencies/BacktrackKit/init.g");
    Unbind(_ReadBTPackage);
fi;
if not IsPackageMarkedForLoading("GraphBacktracking", "1.2.0") then
    _ReadGBPackage := {f} -> ReadPackage("Vole", Concatenation("dependencies/GraphBacktracking/", f));
    ReadPackage("Vole", "dependencies/GraphBacktracking/init.g");
    Unbind(_ReadGBPackage);
fi;
UnbindGlobal("_BT_SKIP_INTERFACE");

ReadPackage("Vole", "gap/internal/comms.gd");
ReadPackage("Vole", "gap/constraints.gd");
ReadPackage("Vole", "gap/interface.gd");
ReadPackage("Vole", "gap/refiners.gd");
ReadPackage("Vole", "gap/wrapper.gd");
ReadPackage("Vole", "gap/directprod.gd");


