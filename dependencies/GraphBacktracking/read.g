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
    _ReadGBPackage( "gap/interface.gi");
fi;

if not IsBound(_BTKit.FilesReadGB) then
    # _BTKit.FilesReadGB := true; in gap/GraphBacktracking.gi
    _ReadGBPackage( "gap/GraphBacktracking.gi");
    _ReadGBPackage( "gap/Equitable.gi");
    _ReadGBPackage( "gap/constraints/simpleconstraints.g");
    _ReadGBPackage( "gap/constraints/normaliser.g");
    _ReadGBPackage( "gap/constraints/canonicalconstraints.g");
    _ReadGBPackage( "gap/constraints/conjugacy.g");
    _ReadGBPackage( "gap/constraints/digraphs.g");
    _ReadGBPackage( "gap/refiners.gi");

    Perform(["GB_Con", "_GB"],
            SetNamesForFunctionsInRecord);
fi;