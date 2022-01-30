# Vole: Backtrack search in permutation groups with graphs
# A GAP package by Mun See Chang, Christopher Jefferson, and Wilf A. Wilson.
#
# SPDX-License-Identifier: MPL-2.0
#
# Implementations: Wrappers for Vole functions that emulate GAP/images/Digraphs

################################################################################
# Wrapper for the GAP library

# Respects raw := true
Vole.Intersection := function(permcolls...)
    local ret;
    if Length(permcolls) = 1 and IsList(permcolls[1]) then
        permcolls := permcolls[1];
    fi;
    if IsEmpty(permcolls) then
        ErrorNoReturn("Vole.Intersection: The arguments must specify at least ",
                      "one perm group or right coset");
    elif not ForAll(permcolls, x -> IsPermGroup(x) or IsRightCoset(x)) then
        ErrorNoReturn("Vole.Intersection: The arguments must be ",
                      "(a list containing) perm groups and/or ",
                      "right cosets of perm groups");
    elif ForAll(permcolls, IsPermGroup) then
        return VoleFind.Group(permcolls);
    else
        ret := VoleFind.Coset(permcolls);
        if ret <> fail then
            return ret;  # Always returns here if ValueOption raw := true
        else
            return [];
        fi;
    fi;
end;

# Respects raw := true
Vole.Stabilizer := function(G, object, action...)
    local con, ret;
    con := CallFuncList(Constraint.Stabilize, Concatenation([object], action));
    ret := VoleFind.Group(G, con);
    _Vole.setParent(ret, G);
    return ret;
end;
Vole.Stabiliser := Vole.Stabilizer;

# Respects raw := true
Vole.Normalizer := function(G, U)
    local ret;
    if not IsPermGroup(G) then
        ErrorNoReturn("Vole.Normalizer: ",
                      "The first argument must be a perm group");
    elif IsPermGroup(U) then
        ret := VoleFind.Group(G, Constraint.Normalise(U));
    elif IsPerm(U) then
        ret := VoleFind.Group(G, Constraint.Normalise(Group(U)));
    else
        ErrorNoReturn("Vole.Normalizer: The second argument ",
                      "must a perm group or a permutation");
    fi;
    _Vole.setParent(ret, G);
    return ret;
end;
Vole.Normaliser := Vole.Normalizer;

# Respects raw := true
Vole.Centralizer := function(G, x)
    local ret;
    if not IsPermGroup(G) then
        ErrorNoReturn("Vole.Centralizer: ",
                      "The first argument must be a perm group");
    elif not (IsPermGroup(x) or IsPerm(x)) then
        ErrorNoReturn("Vole.Centralizer: The second argument ",
                      "must be a perm group or a permutation");
    fi;
    ret := VoleFind.Group(G, Constraint.Centralize(x));
    _Vole.setParent(ret, G);
    return ret;
end;
Vole.Centraliser := Vole.Centralizer;

# Ignores raw := true
Vole.IsConjugate := function(G, x, y)
    if not IsPermGroup(G) then
        ErrorNoReturn("Vole.IsConjugate: ",
                      "The first argument must be a perm group");
    elif not ForAll([x, y], IsPerm) and not ForAll([x, y], IsPermGroup) then
        ErrorNoReturn("Vole.IsConjugate: The second and third arguments ",
                      "must either be both permutations or both perm groups");
    fi;
    return Vole.RepresentativeAction(G, x, y : raw := false) <> fail;
end;

# Respects raw := true
Vole.RepresentativeAction := function(G, object1, object2, action...)
    if not IsPermGroup(G) then
        ErrorNoReturn("Vole.RepresentativeAction: ",
                      "The first argument must be a perm group");
    elif Length(action) > 1 then
        ErrorNoReturn("Vole.RepresentativeAction args: ",
                      "G, object1, object2[, action]");
    elif Length(action) = 1 then
        action := action[1];
    else
        action := OnPoints;
    fi;
    return VoleFind.Representative(G, Constraint.Transport(object1, object2, action));
end;

# Sometimes respects raw := true (depending on whether it does a search)
Vole.TwoClosure := function(G)
    local points, func, digraphs, digraph_con;
    if not IsPermGroup(G) then
        ErrorNoReturn("Vole.TwoClosure: ",
                      "The argument must be a perm group");
    fi;

    points := MovedPoints(G);
    if not IsPackageLoaded("orbitalgraphs") then
        ErrorNoReturn("Vole.TwoClosure requires the OrbitalGraphs package, ",
                      "which is not currently loaded");
        # The following is quite slow, we don't include it for now
        # orbitals := Orbits(G, Arrangements(points, 2), OnPairs);
        # digraphs := List(orbitals, DigraphByEdges);
    else
        func     := EvalString("OrbitalGraphs");  # Hack to avoid warnings
        digraphs := func(G);
    fi;

    if Length(digraphs) = 1 then
        # 1 OrbitalGraph -> complete digraph -> two-closure is symmetric group
        return SymmetricGroup(points);
    else
        digraph_con := Constraint.Stabilise(digraphs, OnTuplesDigraphs);
        return VoleFind.Group(Constraint.MovedPoints(points), digraph_con);
    fi;
end;

################################################################################
# Wrapper for the images package

# Respects raw := true
Vole.CanonicalPerm := function(G, object, action...)
    local ret;
    if not IsPermGroup(G) then
        ErrorNoReturn("Vole.CanonicalPerm: ",
                      "The first argument must be a perm group");
    elif Length(action) > 1 then
        ErrorNoReturn("Vole.CanonicalPerm args: G, object[, action]");
    elif Length(action) = 1 then
        action := action[1];
    else
        action := OnPoints;
    fi;
    ret := VoleFind.Canonical(G, Constraint.Stabilize(object, action));
    if IsBound(ret.raw) then
        return ret;
    else
        return ret.canonical;
    fi;
end;
Vole.CanonicalImagePerm := Vole.CanonicalPerm;

# Ignores raw := true
Vole.CanonicalImage := function(G, object, action...)
    local x, args;
    args := Concatenation([G, object], action);
    x := CallFuncList(Vole.CanonicalPerm, args : raw := false);
    return action[1](object, x);
end;

################################################################################
# Wrapper for the Digraphs package

# Respects raw := true
Vole.AutomorphismGroup := function(D, colours...)
    if not IsDigraph(D) then
        ErrorNoReturn("Vole.AutomorphismGroup: ",
                      "The first argument must be a digraph");
    elif not IsEmpty(colours) then
        ErrorNoReturn("not yet implemented for vertex/edge colours");
    fi;
    return Vole.Stabilizer(SymmetricGroup(DigraphVertices(D)), D, OnDigraphs);
end;

# Ignores raw := true
Vole.CanonicalDigraph := function(D)
    if not IsDigraph(D) then
        ErrorNoReturn("Vole.AutomorphismGroup: ",
                      "The first argument must be a digraph");
    fi;
    return Vole.CanonicalImage(SymmetricGroup(DigraphVertices(D)), D, OnDigraphs);
end;

# Respects raw := true
Vole.DigraphCanonicalLabelling := function(D, colours...)
    if not IsDigraph(D) then
        ErrorNoReturn("Vole.AutomorphismGroup: ",
                      "The first argument must be a digraph");
    elif not IsEmpty(colours) then
        ErrorNoReturn("not yet implemented for vertex/edge colours");
    fi;
    return Vole.CanonicalPerm(SymmetricGroup(DigraphVertices(D)), D, OnDigraphs);
end;

# Ignores raw := true
Vole.IsIsomorphicDigraph := function(D1, D2)
    if not IsDigraph(D1) or not IsDigraph(D2) then
        ErrorNoReturn("Vole.IsIsomorphicDigraph: ",
                      "The arguments must be digraphs");
    fi;
    return Vole.IsomorphismDigraphs(D1, D2) <> fail;
end;

# Respects raw := true
Vole.IsomorphismDigraphs := function(D1, D2)
    local G;
    if not (IsDigraph(D1) and IsDigraph(D2)) then
        ErrorNoReturn("Vole.IsomorphismDigraphs: ",
                      "The arguments must be digraphs");
    fi;
    return VoleFind.Rep(Constraint.Transport(D1, D2, OnDigraphs));
end;
