# Vole: Backtrack search in permutation groups with graphs
# A GAP package by Mun See Chang, Christopher Jefferson, and Wilf A. Wilson.
#
# SPDX-License-Identifier: MPL-2.0
#
# Reading the implementation part of the package.

ReadPackage("Vole", "gap/internal/util.g");

ReadPackage("Vole", "gap/internal/comms.gi");
ReadPackage("Vole", "gap/interface.gi");
ReadPackage("Vole", "gap/refiners.gi");
ReadPackage("Vole", "gap/constraints.gi");
ReadPackage("Vole", "gap/wrapper.gi");

Perform(["_Vole", "Vole", "VoleFind", "VoleRefiner"],
        SetNamesForFunctionsInRecord);
