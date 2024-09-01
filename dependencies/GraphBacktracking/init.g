#
# GraphBacktracking: A simple but slow implementation of graph backtracking
#
# Reading the declaration part of the package.
#

if not IsBound(_ReadGBPackage) then
    _ReadGBPackage := {f} -> ReadPackage("GraphBacktracking", f);
fi;


if not IsBound(_BT_SKIP_INTERFACE) and not IsBound(_BTKit.InitInterfaceGB) then
    # _BTKit.InitInterfaceGB := true; in gap/interface.gd
    _ReadGBPackage( "gap/interface.gd");
fi;

if not IsBound(_BTKit.FilesInitGB) then
    # _BTKit.FilesInitGB := true; in gap/GraphBacktracking.gd
    _ReadGBPackage( "gap/GraphBacktracking.gd");
    _ReadGBPackage( "gap/Equitable.gd");
fi;
