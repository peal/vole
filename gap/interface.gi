# Vole: Backtrack search in permutation groups with graphs
# A GAP package by Mun See Chang, Christopher Jefferson, and Wilf A. Wilson.
#
# SPDX-License-Identifier: MPL-2.0
#
# Implementations: TODO

# TODO Better handling of one argument = list of constraints versus one argument
# per constraint

Vole.FindOne := function(constraints...)
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

Vole.FindGroup := function(constraints...)
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

Vole.CanonicalPerm := function(G, constraints...)
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

# TODO: work in progress - this does not currently work
Vole.CanonicalImage := function(G, constraints...)
    local perm;
    if not IsEmpty(constraints) and IsList(constraints[1]) then
        constraints := constraints[1];
    fi;
    perm := Vole.CanonicalPerm(G, constraints);
    return constraints[1] ^ perm;
end;
