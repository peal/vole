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
# If either package IS installed, Vole lists it as a suggested package (see
# PackageInfo.g), so GAP loads the real package -- and orders its declarations
# before Vole's. In that case we must NOT read our bundled copy, or we would
# shadow/duplicate the real one. We therefore read a bundled copy only when the
# corresponding package is not available at all. This also keeps the load cycle
# BacktrackKit -> images -> Vole well behaved: when BacktrackKit is a real
# package, Vole defers to it rather than racing in its own bundled copy.
# The version checked here must match the bundled copy and the minimum
# declared in PackageInfo.g: an externally-installed copy that is too old to
# contain the refiners Vole relies on must be rejected so we fall back to the
# (compatible) bundled copy.
_BT_SKIP_INTERFACE := true;
if TestPackageAvailability("BacktrackKit", "1.1.0") = fail then
    _ReadBTPackage := {f} -> ReadPackage("Vole", Concatenation("dependencies/BacktrackKit/", f));
    ReadPackage("Vole", "dependencies/BacktrackKit/init.g");
    Unbind(_ReadBTPackage);
fi;
if TestPackageAvailability("GraphBacktracking", "1.1.0") = fail then
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


