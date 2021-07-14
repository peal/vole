# Vole: Backtrack search in permutation groups with graphs
# A GAP package by Mun See Chang, Christopher Jefferson, and Wilf A. Wilson.
#
# SPDX-License-Identifier: MPL-2.0
#
# Implementations: Wrappers for Vole functions to emulate the GAP interface.


################################################################################
# Wrapper for the GAP library

Vole.Intersection := function(permcolls...)
    local ret;
    if IsEmpty(permcolls) then
        ErrorNoReturn("Vole.Intersection: The arguments must specify at least ",
                      "one perm group or right coset");
    elif Length(permcolls) = 1 and IsList(permcolls[1]) then
        permcolls := permcolls[1];
    fi;
    if not ForAll(permcolls, x -> IsPermGroup(x) or IsRightCoset(x)) then
        ErrorNoReturn("Vole.Intersection: The arguments must be ",
                      "(a list containing) perm groups and/or ",
                      "right cosets of perm groups");
    fi;
    if ForAny(permcolls, IsRightCoset) then
        ret := VoleFind.Coset(permcolls);
        if ret = fail then
            return [];
        else
            return ret;
        fi;
    else
        return VoleFind.Group(permcolls);
    fi;
end;

Vole.Stabilizer := function(G, object, action...)
    local con;
    con := CallFuncList(VoleCon.Stabilize, Concatenation([object], action));
    return VoleFind.Group(G, con);
end;
Vole.Stabiliser := Vole.Stabilizer;

Vole.Normalizer := function(G, U)
    if not IsPermGroup(G) then
        ErrorNoReturn("Vole.Normalizer: ",
                      "The first argument must be a perm group");
    elif IsPermGroup(U) then
        return VoleFind.Group(G, VoleCon.Normalise(U));
    elif IsPerm(U) then
        return VoleFind.Group(G, VoleCon.Normalise(Group(U)));
    fi;
    ErrorNoReturn("Vole.Normalizer: The second argument ",
                  "must a perm group or a permutation");
end;
Vole.Normaliser := Vole.Normalizer;

Vole.Centralizer := function(G, x)
    if not IsPermGroup(G) then
        ErrorNoReturn("Vole.Centralizer: ",
                      "The first argument must be a perm group");
    elif not (IsPermGroup(x) or IsPerm(x)) then
        ErrorNoReturn("Vole.Centralizer: The second argument ",
                      "must be a perm group or a permutation");
    fi;
    return VoleFind.Group(G, VoleCon.Centralize(x));
end;
Vole.Centraliser := Vole.Centralizer;

Vole.IsConjugate := function(G, x, y)
    if not IsPermGroup(G) then
        ErrorNoReturn("Vole.IsConjugate: ",
                      "The first argument must be a perm group");
    elif not ForAll([x, y], IsPerm) and not ForAll([x, y], IsPermGroup) then
        ErrorNoReturn("Vole.IsConjugate: The second and third arguments ",
                      "must either be both permutations or both perm groups");
    fi;
    return Vole.RepresentativeAction(G, x, y) <> fail;
end;

Vole.RepresentativeAction := function(G, object1, object2, action...)
    if not IsPermGroup(G) then
        ErrorNoReturn("Vole.RepresentativeAction: ",
                      "The first argument must be a perm group");
    elif Length(action) > 1 then
        ErrorNoReturn("VoleCon.RepresentativeAction args: ",
                      "G, object1, object2[, action]");
    elif Length(action) = 1 then
        action := action[1];
    else
        action := OnPoints;
    fi;
    return VoleFind.Representative(G, VoleCon.Transport(object1, object2, action));
end;


################################################################################
# Wrapper for the images package

Vole.CanonicalPerm := function(G, object, action...)
    if not IsPermGroup(G) then
        ErrorNoReturn("Vole.CanonicalPerm: ",
                      "The first argument must be a perm group");
    elif Length(action) > 1 then
        ErrorNoReturn("VoleCon.CanonicalPerm args: G, object[, action]");
    elif Length(action) = 1 then
        action := action[1];
    else
        action := OnPoints;
    fi;
    return VoleFind.CanonicalPerm(G, VoleCon.Stabilize(object, action));
end;
Vole.CanonicalImagePerm := Vole.CanonicalPerm;

Vole.CanonicalImage := function(G, object, action...)
    local x;
    x := CallFuncList(Vole.CanonicalPerm, Concatenation([G, object], action));
    return action[1](object, x);
end;
