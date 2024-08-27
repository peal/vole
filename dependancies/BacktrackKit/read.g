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
    _ReadBTPackage( "gap/internal/util.g");
    _ReadBTPackage( "gap/stabtree.g");
    _ReadBTPackage( "gap/BacktrackKit.gi");
fi;


if not IsBound(_BT_SKIP_INTERFACE) and not IsBound(_BTKit.CheckReadgInterface) then
    # _BTKit.CheckReadgInterface := true; set in gap/interface.gi
    _ReadBTPackage( "gap/interface.gi");
fi;

if not IsBound(_BTKit.CheckReadg) then
    # _BTKit.CheckReadg := true; set in gap/canonical.gi

    _ReadBTPackage( "gap/canonical.gi");
    _ReadBTPackage( "gap/constraint.gi");
    _ReadBTPackage( "gap/partitionstack.gi");
    _ReadBTPackage( "gap/refiner.gi");
    _ReadBTPackage( "gap/tracer.gi");

    _ReadBTPackage( "gap/refiners/simple.g");
    _ReadBTPackage( "gap/refiners/conjugacyexample.g");
    _ReadBTPackage( "gap/refiners/normaliserexample.g");
    _ReadBTPackage( "gap/refiners/graphs.g");
    _ReadBTPackage( "gap/refiners/canonicalrefiners.g");
    _ReadBTPackage( "gap/refiners/tree/tree.g");

    Perform(["BTKit_Refiner", "_BTKit", "Constraint"],
            SetNamesForFunctionsInRecord);
fi;

