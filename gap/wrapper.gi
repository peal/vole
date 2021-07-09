# Vole: Backtrack search in permutation groups with graphs
# A GAP package by Mun See Chang, Christopher Jefferson, and Wilf A. Wilson.
#
# SPDX-License-Identifier: MPL-2.0
#
# Implementations: Wrappers for Vole functions to emulate the GAP interface.

Vole.Intersection := function(grps...)
    if Length(grps) = 1 and IsList(grps[1]) then
        grps := grps[1];
    fi;
    if not ForAll(grps, IsPermGroup) then
        ErrorNoReturn("Vole.Intersection: The arguments must be perm groups ",
                      "or a list of perm groups");
    fi;
    if IsEmpty(grps) then
        ErrorNoReturn("Vole.Intersection: The arguments must be (a list ",
                      "containing) at least one perm group");
    fi;
    return Vole.FindGroup(List(grps, VoleCon.InGroup));
end;

Vole.Stabilizer := function(G, object, action...)
    return Vole.FindGroup([VoleCon.InGroup(G), CallFuncList(VoleCon.Stabilize(Concatenation([object], action)))]);
end;
Vole.Stabiliser := Vole.Stabilizer;

Vole.Normalizer := function(G, H)
    if not IsPermGroup(G) then
        ErrorNoReturn("Vole.Normalizer: The first argument must be a perm group");
    fi;

    if IsPermGroup(H) then
        return Vole.FindGroup([VoleCon.InGroup(G), VoleCon.Normalise(H)]);
    elif IsPerm(H) then
        return Vole.FindGroup([VoleCon.InGroup(G), VoleCon.Normalise(Group(H))]);
    else
        ErrorNoReturn("Vole.Normalizer: The second argument must a perm group or a permutation");
    fi;
end;
Vole.Normaliser := Vole.Normalizer;

Vole.Centralizer := function(G, x)
    if not IsPermGroup(G) then
        ErrorNoReturn("Vole.Normalizer: The first argument must be a perm group");
    elif not (IsPermGroup(x) or IsPerm(x)) then
        ErrorNoReturn("Vole.Centralizer: The second argument must be a perm group or a permutation");
    fi;

    return Vole.FindGroup([VoleCon.InGroup(G), VoleCon.Centralize(x)]);
end;
Vole.Centraliser := Vole.Centralizer;

Vole.IsConjugate := function(G, g, h)
    if not IsPermGroup(G) then
        ErrorNoReturn("Vole.IsConjugate: The first argument must be a perm group");
    elif (not (IsPerm(g) and IsPerm(h)) and not (IsPermGroup(g) and IsPermGroup(h))) then
        ErrorNoReturn("Vole.IsConjugate: The second and third arguments must both be either permutations or perm groups");
    fi;

    return Vole.RepresentativeAction(G, g, h, OnPoints) <> fail;
end;

Vole.RepresentativeAction := function(G, obj1, obj2, action...)
    if Length(action) = 1 then
        action := action[1];
    elif Length(action) = 0 then
        action := OnPoints;
    else
        ErrorNoReturn("VoleCon.RepresentativeAction args: G, obj1, obj2[, action]");
    fi;

    return Vole.FindOne([VoleCon.InGroup(G), VoleCon.Transport(obj1, obj2, action)]);
end;
