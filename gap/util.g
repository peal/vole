# Vole: Backtrack search in permutation groups with graphs
# A GAP package by Mun See Chang, Christopher Jefferson, and Wilf A. Wilson.
#
# SPDX-License-Identifier: MPL-2.0
#
# Internal utility functions.

DeclareGlobalVariable("_Vole");
InstallValue(_Vole, rec());

# Simple function to recursively find the largest value (or largest moved point)
# in lists, sets, permutations and permutation groups
_Vole.lmp := function(s...)
    if Length(s) = 1 then
        s := s[1];
    fi;

    if IsList(s) then
        return MaximumList(List(s, _Vole.lmp), 0);
    elif IsInt(s) then
        return s;
    elif IsPerm(s) or IsPermGroup(s) then
        return LargestMovedPoint(s);
    fi;
end;

# Get the upper and lower bounds for a list of constraints
# The list of constraints may contain permutation groups (in the event
# we are solving a canonical problem)
_Vole.getBound := function(constraints, initial_max)
    local min, max, this_min, this_max, c;
    min := 1;
    max := initial_max;
    for c in constraints do
        this_min := 1;
        this_max := infinity;
        if IsPermGroup(c) then
            this_min := LargestMovedPoint(c);
            this_max := LargestMovedPoint(c);
        elif IsRecord(c) then
            if IsBound(c.bounds) then
                this_min := c.bounds.largest_required_point;
                if IsBound(c.bounds.largest_moved_point) then
                    this_max := c.bounds.largest_moved_point;
                fi;
            fi;
        elif IsRefiner(c) then
            this_min := c!.largest_required_point;
            if IsBound(c!.largest_moved_point) then
                this_max := c!.largest_moved_point;
            fi;
        fi;
        min := Maximum(min, this_min);
        max := Minimum(max, this_max);
    od;
    max := Maximum(min, max);
    if max = infinity then
        ErrorNoReturn("Error: Cannot prove an upper bound for 'vole' call. Consider adding an instance of VoleRefiner.SymmetricGroup(D) to set a group to search in");
    fi;
    return rec(min := min, max := max);
end;


# Fill in a configuration 'default', using user-supplied values from 'conf'
_Vole.getConfig := function(conf, default)
    local r;
    if Length(conf) = 0 then
        return default;
    elif Length(conf) = 1 then
        if not IsRecord(conf[1]) then
            ErrorNoReturn("Vole: configuration must be a record, not", conf[1]);
        fi;
        for r in RecNames(conf[1]) do
            if not IsBound(default.(r)) then
                ErrorNoReturn("Vole: Invalid config key - ", r);
            fi;
            default.(r) := conf[1].(r);
        od;
        return default;
    else
        ErrorNoReturn("Vole: Too many arguments");
    fi;
end;
