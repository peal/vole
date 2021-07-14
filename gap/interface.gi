# Vole: Backtrack search in permutation groups with graphs
# A GAP package by Mun See Chang, Christopher Jefferson, and Wilf A. Wilson.
#
# SPDX-License-Identifier: MPL-2.0
#
# Implementations: TODO

# TODO Better handling of one argument = list of constraints versus one argument
# per constraint

VoleFind.Representative := function(constraints...)
    local bounds, ret, conf;
    if not IsEmpty(constraints) and IsList(constraints[1]) then
        constraints := constraints[1];
    fi;
    conf := _Vole.getConfig(rec(raw := false, points := infinity));
    bounds := _Vole.getBound(constraints, conf.points);
    ret := _Vole.CosetSolve(bounds.max, constraints);
    if conf.raw then
        return ret;
    else
        if Length(ret.sol) > 0 then
            return ret.sol[1];
        else
            return fail;
        fi;
    fi;
end;
VoleFind.Rep := VoleFind.Representative;

VoleFind.Group := function(constraints...)
    local bounds, ret, conf;
    if not IsEmpty(constraints) and IsList(constraints[1]) then
        constraints := constraints[1];
    fi;
    conf := _Vole.getConfig(rec(raw := false, points := infinity));
    bounds := _Vole.getBound(constraints, conf.points);
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
        return [];
    fi;
    ErrorNoReturn("not yet implemented");
    # TODO convert the "constraints" into their group versions, as appropriate!
    G := VoleFind.Group();
    return RightCoset(G, x);
end;

VoleFind.CanonicalPerm := function(G, constraints...)
    local bounds, ret, max, conf;
    if not IsEmpty(constraints) and IsList(constraints[1]) then
        constraints := constraints[1];
    fi;
    conf := _Vole.getConfig(rec(raw := false, points := infinity));
    bounds := _Vole.getBound(Concatenation(constraints, [G]), conf.points);
    ret := _Vole.CanonicalSolve(bounds.max, G, constraints);
    if conf.raw then
        return ret;
    else
        return ret.canonical;
    fi;
end;
