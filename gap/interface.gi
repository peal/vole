# Vole: Backtrack search in permutation groups with graphs
# A GAP package by Mun See Chang, Christopher Jefferson, and Wilf A. Wilson.
#
# SPDX-License-Identifier: MPL-2.0
#
# Implementations: The native interface to Vole

VoleFind.Representative := function(arguments...)
    local conf, constraints, bounds, ret;

    if IsEmpty(arguments) then
        ErrorNoReturn("at least one argument must be given");
    fi;

    constraints := _Vole.processConstraints(arguments);
    conf := _Vole.getConfig(rec(raw := false, points := infinity));
    bounds := _Vole.getBounds(constraints, conf.points, true);
    ret := _Vole.CosetSolve(Minimum(bounds.min, bounds.max), constraints);

    if conf.raw then
        return ret;
    elif not IsEmpty(ret.sol) then
        return ret.sol[1];
    else
        return fail;
    fi;
end;
VoleFind.Rep := VoleFind.Representative;

VoleFind.Group := function(arguments...)
    local conf, constraints, bounds, ret;

    if IsEmpty(arguments) then
        ErrorNoReturn("at least one argument must be given");
    fi;

    constraints := _Vole.processConstraints(arguments);
    conf := _Vole.getConfig(rec(raw := false, points := infinity));
    bounds := _Vole.getBounds(constraints, conf.points, false);
    ret := _Vole.GroupSolve(bounds.max, constraints);

    if conf.raw then
        return ret;
    else
        return ret.group;
    fi;
end;

# TODO: This could be implemented at the Vole level: there should be an
#       option to continue a coset search after the first element is found
VoleFind.Coset := function(arguments...)
    local constraints, x, G;

    ErrorNoReturn("not yet implemented");

    if IsEmpty(arguments) then
        ErrorNoReturn("at least one argument must be given");
    fi;

    constraints := _Vole.processConstraints(arguments);
    x := VoleFind.Representative(constraints);
    if x = fail then
        return fail;
    fi;
    # TODO convert the "constraints" into their group versions, as appropriate!
    G := VoleFind.Group();
    return RightCoset(G, x);
end;

VoleFind.Canonical := function(G, arguments...)
    local constraints, conf, bounds, ret;

    if IsEmpty(arguments) then
        ErrorNoReturn("at least two arguments must be given");
    elif Length(arguments) = 1 and IsList(arguments[1]) then
        arguments := ShallowCopy(arguments[1]);
    fi;

    constraints := arguments; # We don't do any processing
    conf := _Vole.getConfig(rec(raw := false, points := infinity));
    bounds := _Vole.getBounds(Concatenation(constraints, [G]), conf.points, false);
    ret := _Vole.CanonicalSolve(bounds.max, G, constraints);

    if conf.raw then
        return ret;
    else
        return rec(group := ret.group, canonical := ret.canonical);
    fi;
end;

VoleFind.CanonicalPerm := {G, constraints...} ->
    CallFuncList(VoleFind.Canonical, Concatenation([G], constraints)).canonical;
