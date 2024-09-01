#
# BacktrackKit: An extensible, easy to understand backtracking framework
#
# Reading the declaration part of the package.
#

if not IsBound(_ReadBTPackage) then
    _ReadBTPackage := {f} -> ReadPackage("BacktrackKit", f);
fi;

# Private members
if not IsBound(_BTKit) then
    _BTKit := AtomicRecord(rec());
fi;

if not IsBound(_BTKit.CheckInitg) then
    _ReadBTPackage( "gap/tracer.gd");
    _ReadBTPackage( "gap/partitionstack.gd");
fi;

if not IsBound(_BT_SKIP_INTERFACE) and not IsBound(_BTKit.CheckInitgInterface) then
    # _BTKit.CheckInitgInterface := true; is in gap/interface.gd
    _ReadBTPackage( "gap/interface.gd");
fi;

if not IsBound(_BTKit.CheckInitg) then
    # _BTKit.CheckInitg := true; in gap/BacktrackKit.gd
    _ReadBTPackage( "gap/BacktrackKit.gd");

    _ReadBTPackage( "gap/canonical.gd");
    _ReadBTPackage( "gap/constraint.gd");
    _ReadBTPackage( "gap/refiner.gd");
fi;
