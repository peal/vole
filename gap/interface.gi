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
        constraints := ShallowCopy(constraints[1]);
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
        constraints := ShallowCopy(constraints[1]);
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
        constraints := ShallowCopy(constraints[1]);
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

VoleFind.Canonical := function(G, constraints...)
    local conf, bounds, ret, i;

    if Length(constraints) = 1 and IsList(constraints[1]) then
        constraints := ShallowCopy(constraints[1]);
    fi;
    for i in [1 .. Length(constraints)] do
        if IsPermGroup(constraints[i]) then
            constraints[i] := VoleCon.Normalize(constraints[i]);
        fi;
    od;
    conf := _Vole.getConfig(rec(raw := false, points := infinity));
    bounds := _Vole.getBounds(Concatenation(constraints, [G]), conf.points, false);
    ret := _Vole.CanonicalSolve(bounds.max, G, constraints);

    if conf.raw then
        return ret;
    else
        return rec(group := ret.group, canonical := ret.canonical);
    fi;
end;

VoleFind.CanonicalPerm := function(G, constraints...)
    local x;
    x := CallFuncList(VoleFind.Canonical, Concatenation([G], constraints));
    return x.canonical;
end;

VoleFind.CanonicalImage := function(G, constraints...)
    local x;
    ErrorNoReturn("not yet implemented");
    x := CallFuncList(VoleFind.Canonical, Concatenation([G], constraints));
    # TODO: work out how to form the canonical image from the constraints,
    #       if it's even possible.
    x.image := "TODO";
    return x;
end;
