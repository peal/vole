# Vole: Backtrack search in permutation groups with graphs
# A GAP package by Mun See Chang, Christopher Jefferson, and Wilf A. Wilson.
#
# SPDX-License-Identifier: MPL-2.0
#
# Reading the implementation part of the package.

# See init.g: read each bundled dependency only when the corresponding external
# package is not available, otherwise defer to the real (suggested) package.
_BT_SKIP_INTERFACE := true;
if TestPackageAvailability("BacktrackKit", "1.1.0") = fail then
    _ReadBTPackage := {f} -> ReadPackage("Vole", Concatenation("dependencies/BacktrackKit/", f));
    ReadPackage("Vole", "dependencies/BacktrackKit/read.g");
    Unbind(_ReadBTPackage);
fi;
if TestPackageAvailability("GraphBacktracking", "1.1.0") = fail then
    _ReadGBPackage := {f} -> ReadPackage("Vole", Concatenation("dependencies/GraphBacktracking/", f));
    ReadPackage("Vole", "dependencies/GraphBacktracking/read.g");
    Unbind(_ReadGBPackage);
fi;
UnbindGlobal("_BT_SKIP_INTERFACE");


ReadPackage("Vole", "gap/internal/util.g");

# Experimental regular-orbit cross-propagation refiners. These extend the
# GraphBacktracking normaliser refiners (loaded above) via its
# extraRegOrbitDeduction hook, and are kept in Vole rather than upstream
# because they are still research-grade.
ReadPackage("Vole", "gap/normaliser-cross.g");

ReadPackage("Vole", "gap/internal/comms.gi");
ReadPackage("Vole", "gap/interface.gi");
ReadPackage("Vole", "gap/refiners.gi");
ReadPackage("Vole", "gap/onset.gi");
ReadPackage("Vole", "gap/constraints.gi");
ReadPackage("Vole", "gap/wrapper.gi");
ReadPackage("Vole", "gap/directprod.gi");
ReadPackage("Vole", "gap/override.gi");

Perform(["_Vole", "Vole", "VoleFind", "VoleRefiner"],
        SetNamesForFunctionsInRecord);
