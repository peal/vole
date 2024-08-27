#
# BacktrackKit: An extensible, easy to understand backtracking framework
#
# Reading the declaration part of the package.
#

# Private members
if not IsBound(_BTKit) then
    _BTKit := AtomicRecord(rec());
fi;

if not IsBound(_BTKit.CheckInitg) then
    ReadPackage( "BacktrackKit", "gap/tracer.gd");
    ReadPackage( "BacktrackKit", "gap/partitionstack.gd");
fi;

if not IsBound(_BT_SKIP_INTERFACE) and not IsBound(_BTKit.CheckInitgInterface) then
    # _BTKit.CheckInitgInterface := true; is in gap/interface.gd
    ReadPackage( "BacktrackKit", "gap/interface.gd");
fi;

if not IsBound(_BTKit.CheckInitg) then
    # _BTKit.CheckInitg := true; in gap/BacktrackKit.gd
    ReadPackage( "BacktrackKit", "gap/BacktrackKit.gd");

    ReadPackage( "BacktrackKit", "gap/canonical.gd");
    ReadPackage( "BacktrackKit", "gap/constraint.gd");
    ReadPackage( "BacktrackKit", "gap/refiner.gd");
fi;
