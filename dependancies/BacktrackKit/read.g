#
# BacktrackKit: An extensible, easy to understand backtracking framework
#
# Reading the implementation part of the package.
#

# A store of the BTKit refiners
if not IsBound(BTKit_Refiner) then
    BTKit_Refiner := AtomicRecord(rec());
fi;



if not IsBound(_BTKit.CheckReadg) then
    ReadPackage( "BacktrackKit", "gap/internal/util.g");
    ReadPackage( "BacktrackKit", "gap/stabtree.g");
    ReadPackage( "BacktrackKit", "gap/BacktrackKit.gi");
fi;


if not IsBound(_BT_SKIP_INTERFACE) and not IsBound(_BTKit.CheckReadgInterface) then
    # _BTKit.CheckReadgInterface := true; set in gap/interface.gi
    ReadPackage( "BacktrackKit", "gap/interface.gi");
fi;

if not IsBound(_BTKit.CheckReadg) then
    # _BTKit.CheckReadg := true; set in gap/canonical.gi

    ReadPackage( "BacktrackKit", "gap/canonical.gi");
    ReadPackage( "BacktrackKit", "gap/constraint.gi");
    ReadPackage( "BacktrackKit", "gap/partitionstack.gi");
    ReadPackage( "BacktrackKit", "gap/refiner.gi");
    ReadPackage( "BacktrackKit", "gap/tracer.gi");

    ReadPackage( "BacktrackKit", "gap/refiners/simple.g");
    ReadPackage( "BacktrackKit", "gap/refiners/conjugacyexample.g");
    ReadPackage( "BacktrackKit", "gap/refiners/normaliserexample.g");
    ReadPackage( "BacktrackKit", "gap/refiners/graphs.g");
    ReadPackage( "BacktrackKit", "gap/refiners/canonicalrefiners.g");
    ReadPackage( "BacktrackKit", "gap/refiners/tree/tree.g");

    Perform(["BTKit_Refiner", "_BTKit", "Constraint"],
            SetNamesForFunctionsInRecord);
fi;

