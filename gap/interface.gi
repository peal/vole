# Vole: Backtrack search in permutation groups with graphs
# A GAP package by Mun See Chang, Christopher Jefferson, and Wilf A. Wilson.
#
# SPDX-License-Identifier: MPL-2.0
#
# Implementations: TODO

# TODO refactor to reduce code duplication

VoleFind.Representative := function(constraints...)
    local bounds, ret, conf, i;
    if Length(constraints) = 1 and IsList(constraints[1]) then
        constraints := constraints[1];
    fi;
    for i in [1 .. Length(constraints)] do
        if IsPermGroup(constraints[i]) then
            constraints[i] := VoleCon.InGroup(constraints[i]);
        elif IsRightCoset(constraints[i]) then
            constraints[i] := VoleCon.InCoset(constraints[i]);
        fi;
    od;
    conf := _Vole.getConfig(rec(raw := false, points := infinity));
    bounds := _Vole.getBounds(constraints, conf.points, true);
    ret := _Vole.CosetSolve(Minimum(bounds.min, bounds.max), constraints);
    if conf.raw then
        return ret;
    elif not IsEmpty(ret.sol) then
        return ret.sol[1];
    fi;
    return fail;
end;
VoleFind.Rep := VoleFind.Representative;

VoleFind.Group := function(constraints...)
    local bounds, ret, conf, i;
    if Length(constraints) = 1 and IsList(constraints[1]) then
        constraints := constraints[1];
    fi;
    for i in [1 .. Length(constraints)] do
        if IsPermGroup(constraints[i]) then
            constraints[i] := VoleCon.InGroup(constraints[i]);
        elif IsRightCoset(constraints[i]) then
            constraints[i] := VoleCon.InCoset(constraints[i]);
        fi;
    od;
    conf := _Vole.getConfig(rec(raw := false, points := infinity));
    bounds := _Vole.getBounds(constraints, conf.points, false);
    ret := _Vole.GroupSolve(bounds.max, constraints);
    if conf.raw then
        return ret;
    else
        return ret.group;
    fi;
end;

# TODO can we do this all in one search?
VoleFind.Coset := function(constraints...)
    local G, x, i;
    if Length(constraints) = 1 and IsList(constraints[1]) then
        constraints := constraints[1];
    fi;
    for i in [1 .. Length(constraints)] do
        if IsPermGroup(constraints[i]) then
            constraints[i] := VoleCon.InGroup(constraints[i]);
        elif IsRightCoset(constraints[i]) then
            constraints[i] := VoleCon.InCoset(constraints[i]);
        fi;
    od;
    x := VoleFind.Representative(constraints);
    if x = fail then
        return fail;
    fi;
    ErrorNoReturn("not yet implemented");
    # TODO convert the "constraints" into their group versions, as appropriate!
    G := VoleFind.Group();
    return RightCoset(G, x);
end;

VoleFind.CanonicalPerm := function(G, constraints...)
    local bounds, ret, max, conf;
    if Length(constraints) = 1 and IsList(constraints[1]) then
        constraints := constraints[1];
    fi;
    # TODO does it even make sense for the constraint in a canonical image
    #      search to VoleCon.InGroup?
    #      Or should the default for a group be VoleCon.Normalize?
    #for i in [1 .. Length(constraints)] do
    #    if IsPermGroup(constraints[i]) then
    #        constraints[i] := VoleCon.InGroup(constraints[i]);
    #    elif IsRightCoset(constraints[i]) then
    #        constraints[i] := VoleCon.InCoset(constraints[i]);
    #    fi;
    #od;
    conf := _Vole.getConfig(rec(raw := false, points := infinity));
    bounds := _Vole.getBounds(Concatenation(constraints, [G]), conf.points, false);
    ret := _Vole.CanonicalSolve(bounds.max, G, constraints);
    if conf.raw then
        return ret;
    else
        return ret.canonical;
    fi;
end;
