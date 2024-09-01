# Vole: Backtrack search in permutation groups with graphs
# A GAP package by Mun See Chang, Christopher Jefferson, and Wilf A. Wilson.
#
# SPDX-License-Identifier: MPL-2.0
#
# Reading the declaration part of the package.

_ReadGBPackage := {f} -> ReadPackage("Vole", Concatenation("dependencies/GraphBacktracking/", f));
_ReadBTPackage := {f} -> ReadPackage("Vole", Concatenation("dependencies/BacktrackKit/", f));
_BT_SKIP_INTERFACE := true;
ReadPackage("Vole", "dependencies/BacktrackKit/init.g");
ReadPackage("Vole", "dependencies/GraphBacktracking/init.g");
UnbindGlobal("_BT_SKIP_INTERFACE");
Unbind(_ReadBTPackage);
Unbind(_ReadGBPackage);

ReadPackage("Vole", "gap/internal/comms.gd");
ReadPackage("Vole", "gap/constraints.gd");
ReadPackage("Vole", "gap/interface.gd");
ReadPackage("Vole", "gap/refiners.gd");
ReadPackage("Vole", "gap/wrapper.gd");


