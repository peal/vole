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
    elif IsDigraph(s) then
        return DigraphNrVertices(s);
    fi;
    ErrorNoReturn("Vole: Do not recognise...");
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
        ErrorNoReturn("Vole is unable to deduce an upper bound for the number ",
                      "of points on which the search is defined. ",
                      "Please include an additional argument that is ",
                      "a containing group, or a constraint of the form ",
                      "VoleCon.LargestMovedPoint(point) or ",
                      "VoleCon.MovedPoints(pointlist), ",
                      "in order to give a bound explicitly,");
    fi;
    return rec(min := min, max := max);
end;


# Fill in a configuration 'default', using user-supplied values from 'conf'
_Vole.getConfig := function(default)
    local r, conf;

    conf := ValueOption("conf");
    if conf = fail then
        return default;
    elif IsRecord(conf) then
        for r in RecNames(conf) do
            if not IsBound(default.(r)) then
                ErrorNoReturn("Vole: Invalid config key - ", r);
            fi;
            default.(r) := conf.(r);
        od;
        return default;
    fi;
    ErrorNoReturn("Vole: The value option 'conf' must be a record, not ", conf);
end;
