# Vole: Backtrack search in permutation groups with graphs
# A GAP package by Mun See Chang, Christopher Jefferson, and Wilf A. Wilson.
#
# SPDX-License-Identifier: MPL-2.0
#
# Implementations: The native interface to Vole

VoleFind.Representative := function(constraints...)
    local bounds, ret, conf, i;
    conf := _Vole.getConfig(rec(raw := false, points := infinity));
    constraints := _Vole.processConstraints(constraints);
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
    conf := _Vole.getConfig(rec(raw := false, points := infinity));
    constraints := _Vole.processConstraints(constraints);
    bounds := _Vole.getBounds(constraints, conf.points, false);
    ret := _Vole.GroupSolve(bounds.max, constraints);

    if conf.raw then
        return ret;
    else
        return ret.group;
    fi;
end;

# TODO:
VoleFind.Coset := function(constraints...)
    local G, x, i;
    constraints := _Vole.processConstraints(constraints);
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
