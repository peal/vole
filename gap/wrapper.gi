# Vole: Backtrack search in permutation groups with graphs
# A GAP package by Mun See Chang, Christopher Jefferson, and Wilf A. Wilson.
#
# SPDX-License-Identifier: MPL-2.0
#
# Implementations: Wrappers for Vole functions to emulate the GAP interface.

Vole.Stabilizer := function(G, object, action...)
    return Vole.FindGroup([VoleCon.InGroup(G), CallFuncList(VoleCon.Stabilize(Concatenation([object], action)))]);
end;

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
Vole.Stabiliser := Vole.Stabilizer;

Vole.Normalizer := function(G, H)
    if not IsPermGroup(G) then
        ErrorNoReturn("Vole.Normaliser: First argument must be a perm group");
    fi;

    if IsPermGroup(H) then
        return Vole.FindGroup([VoleCon.InGroup(G), VoleCon.Normalise(H)]);
    elif IsPerm(H) then
        return Vole.FindGroup([VoleCon.InGroup(G), VoleCon.Centraliser(H)]);
    else
        ErrorNoReturn("Vole.Normaliser: Second argument must a perm group or permutation");
    fi;
end;
Vole.Normaliser := Vole.Normalizer;

Vole.IsConjugate := function(G, x, y)
    if not IsPermGroup(G) then
        ErrorNoReturn("Vole.Normaliser: First argument must be a perm group");
    fi;
    if not (IsPerm(x) and IsPerm(y)) then
        ErrorNoReturn("Vole.Normaliser: Second and Third arguments must be permutations");
    fi;
    Vole.FindOne([VoleCon.InGroup(G), VoleCon.Conjugate(x,y)]);
end;

