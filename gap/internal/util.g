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
    elif IsPerm(s) or IsPermGroup(s) or IsRightCoset(s) then
        return LargestMovedPoint(s);
    elif IsDigraph(s) then
        return Maximum(DigraphVertices(s));
    fi;
    ErrorNoReturn("Vole: Do not recognise...");
end;

# Get the upper and lower bounds for a list of constraints
# The list of constraints may contain permutation groups (in the event
# we are solving a canonical problem)
_Vole.getBounds := function(constraints, initial_max, allow_max_inf)
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
    max := Maximum(min, max); # TODO Wilf: I'm not sure if I want this line... need to think about it
    if max = infinity and not allow_max_inf then
        ErrorNoReturn("Vole is unable to deduce an upper bound for the number ",
                      "of points on which the search is defined. ",
                      "Please include an additional argument that is ",
                      "a containing group, or a constraint of the form ",
                      "VoleCon.LargestMovedPoint(point) or ",
                      "VoleCon.MovedPoints(pointlist), ",
                      "in order to give a bound explicitly, ",
                      "type '?Bounds associated' for more information, ",
                      "or look at the manual...");
    fi;
    return rec(min := min, max := max);
end;


# TODO Wilf has been adjusting this and it's still a bit of a work in progress
# I want the 'main' configuration interface to just be listing the options
# as value options individually, i.e.
# VoleFind.Group(constraints : points := 5);
# VoleFind.Group(constraints : raw := true);
#
# For me the question is: do we still want to support the conf := rec() way
# of doing things too? As both a ValueOption and as an optional final
# argument? Currently you can give it as a value option and it still works
# (and overrides individual options) but I don't think it's sensible to keep
# both ways around. I'll talk to Chris about it.
#
# Fill in a configuration 'default', using user-supplied values from
# ValueOptions
_Vole.getConfig := function(default)
    local r, conf;

    conf := ValueOption("conf");
    if conf = fail then
        conf := rec();
    elif not IsRecord(conf) then
        ErrorNoReturn("Vole: The value option 'conf' must be a record, not ",
                      conf);
    fi;
    for r in RecNames(default) do
        #if not IsBound(default.(r)) then
        #    ErrorNoReturn("Vole: Invalid config key - ", r);
        #fi;
        if IsBound(conf.(r)) then
            default.(r) := conf.(r);
        elif ValueOption(r) <> fail then
            default.(r) := ValueOption(r);
        fi;
    od;
    return default;
end;

# Take a list of constraints and process as follows:
# * Replace any group G by VoleCon.InGroup(G)
# * Replace any right coset object U by VoleCon.InCoset(U)
# * Replace any positive integer k by VoleCon.LargestMovedPoint(k)
_Vole.processConstraints := function(constraints)
    local i;
    constraints := Flat(constraints);
    for i in [1 .. Length(constraints)] do
        if IsPermGroup(constraints[i]) then
            constraints[i] := VoleCon.InGroup(constraints[i]);
        elif IsRightCoset(constraints[i]) then
            constraints[i] := VoleCon.InCoset(constraints[i]);
        elif IsPosInt(constraints[i]) then
            constraints[i] := VoleCon.LargestMovedPoint(constraints[i]);
        fi;
    od;
    # TODO if VoleCon.IsEven and VoleCon.IsOdd are specified, then return fail!
    # TODO remove duplicates?
    return Flat(constraints);
end;

# For some wrapper functions, we are explicitly asking for a subgroup of
# the first argument G. GAP sets the parent of the result to be G, so we
# should do this too. However, the result is sometimes a group, or sometimes
# a record (in the 'raw' case), and so we have this little helper function
# to reduce code repetition.
_Vole.setParent := function(ret, G)
    local obj;
    if IsPermGroup(ret) then
        obj := ret;
    else
        obj := ret.group;
    fi;
    SetParent(obj, G);
end;
