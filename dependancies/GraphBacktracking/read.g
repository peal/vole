#
# GraphBacktracking: A simple but slow implementation of graph backtracking
#
# Reading the implementation part of the package.
#

if not IsBound(_BTKit.FilesReadGB) then
    _GB := AtomicRecord(rec());
fi;

if not IsBound(_BT_SKIP_INTERFACE) and not IsBound(_BTKit.ReadInterfaceGB) then
    # _BTKit.ReadInterfaceGB := true; in gap/interface.gi
    ReadPackage( "GraphBacktracking", "gap/interface.gi");
fi;

if not IsBound(_BTKit.FilesReadGB) then
    # _BTKit.FilesReadGB := true; in gap/GraphBacktracking.gi
    ReadPackage( "GraphBacktracking", "gap/GraphBacktracking.gi");
    ReadPackage( "GraphBacktracking", "gap/Equitable.gi");
    ReadPackage( "GraphBacktracking", "gap/constraints/simpleconstraints.g");
    ReadPackage( "GraphBacktracking", "gap/constraints/normaliser.g");
    ReadPackage( "GraphBacktracking", "gap/constraints/canonicalconstraints.g");
    ReadPackage( "GraphBacktracking", "gap/constraints/conjugacy.g");
    ReadPackage( "GraphBacktracking", "gap/constraints/digraphs.g");
    ReadPackage( "GraphBacktracking", "gap/refiners.gi");

    Perform(["GB_Con", "_GB"],
            SetNamesForFunctionsInRecord);
fi;