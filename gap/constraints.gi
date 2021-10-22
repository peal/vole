# Vole: Backtrack search in permutation groups with graphs
# A GAP package by Mun See Chang, Christopher Jefferson, and Wilf A. Wilson.
#
# SPDX-License-Identifier: MPL-2.0
#
# Implementations: Vole constraints

VoleCon.Stabilize := function(object, action...)

    # Determine action: default is OnPoints
    if Length(action) = 1 and IsFunction(action[1]) and
      (NumberArgumentsFunction(action[1]) = 2 or
       NumberArgumentsFunction(action[1]) < 0) then
        action := action[1];
    elif Length(action) = 0 then
        action := OnPoints;
    else
        ErrorNoReturn("VoleCon.Stabilize args: object[, action]");
    fi;

    # Determine which refiner(s) to return, based on the object and the action

    # OnPoints and pos int
    if action = OnPoints and IsPosInt(object) then
        return VoleRefiner.TupleStab([object]);

    # OnPoints and perm
    elif action = OnPoints and IsPerm(object) then
        return VoleCon.Centralise(object);

    # OnPoints and perm group
    elif action = OnPoints and IsPermGroup(object) then
        return VoleCon.Normalise(object);

    # OnSets
    elif action = OnSets and IsSet(object) and ForAll(object, IsPosInt) then
        return VoleRefiner.SetStab(object);

    # OnTuples
    elif action = OnTuples and IsHomogeneousList(object)
      and ForAll(object, IsPosInt) then
        return VoleRefiner.TupleStab(object);

    # OnSetsSets
    elif action = OnSetsSets and IsSet(object)
      and ForAll(object, x -> IsSet(x) and ForAll(x, IsPosInt)) then
        return VoleRefiner.SetSetStab(object);

    # OnSetsTuples
    elif action = OnSetsTuples and IsSet(object)
      and ForAll(object, x -> IsHomogeneousList(x) and ForAll(x, IsPosInt)) then
        return VoleRefiner.SetTupleStab(object);

    # OnTuplesSets
    elif action = OnTuplesSets and IsList(object)
      and ForAll(object, x -> IsSet(x) and ForAll(x, IsPosInt)) then
        return List(object, VoleRefiner.SetStab);

    # OnTuplesTuples
    elif action = OnTuplesTuples and IsList(object)
      and ForAll(object, x -> IsList(x) and ForAll(x, IsPosInt)) then
        return List(object, VoleRefiner.TupleStab);

    # OnDigraphs / list of adjacencies
    elif action = OnDigraphs and IsList(object)
      and ForAll(object, x -> IsList(x) and ForAll(x, IsPosInt)) then
        return VoleRefiner.DigraphStab(object);

    # OnDigraphs / Digraphs package object
    elif action = OnDigraphs and IsDigraph(object) then
        return VoleRefiner.DigraphStab(OutNeighbours(object));

    fi;
    ErrorNoReturn("VoleCon.Stabilize: Unrecognised combination of ",
                  "<object> and <action>:\n",
                  ViewString(object), " and ", NameFunction(action));
end;
VoleCon.Stabilise := VoleCon.Stabilize;

VoleCon.Transport := function(object1, object2, action...)

    # Determine action: default is OnPoints
    if Length(action) = 1 and IsFunction(action[1]) and
      (NumberArgumentsFunction(action[1]) = 2 or
       NumberArgumentsFunction(action[1]) < 0) then
        action := action[1];
    elif Length(action) = 0 then
        action := OnPoints;
    else
        ErrorNoReturn("VoleCon.Transport args: object1, object2[, action]");
    fi;

    # Determine which refiner(s) to return, based on the objects and the action

    # OnPoints and pos ints
    if action = OnPoints and IsPosInt(object1) and IsPosInt(object2) then
        return VoleRefiner.TupleTransporter([object1], [object2]);

    # OnPoints and perms
    elif action = OnPoints and IsPerm(object1) and IsPerm(object2) then
        return VoleCon.Conjugate(object1, object2);

    # OnPoints and perm groups
    elif action = OnPoints and ForAll([object1, object2], IsPermGroup) then
        return VoleCon.Conjugate(object1, object2);

    # OnSets
    elif action = OnSets and IsSet(object1) and ForAll(object1, IsPosInt)
      and IsSet(object2) and ForAll(object2, IsPosInt) then
        if Length(object1) <> Length(object2) then
            return VoleCon.None();
        else
            return VoleRefiner.SetTransporter(object1, object2);
        fi;

    # OnTuples
    elif action = OnTuples and ForAll([object1, object2], IsHomogeneousList)
      and ForAll(object1, IsPosInt) and ForAll(object2, IsPosInt) then
        if Length(object1) <> Length(object2) then
            return VoleCon.None();
        else
            return VoleRefiner.TupleTransporter(object1, object2);
        fi;

    # OnSetsSets
    elif action = OnSetsSets and ForAll([object1, object2], IsSet)
      and ForAll(object1, x -> IsSet(x) and ForAll(x, IsPosInt))
      and ForAll(object2, x -> IsSet(x) and ForAll(x, IsPosInt)) then
        if Length(object1) <> Length(object2) then
            return VoleCon.None();
        else
            return VoleRefiner.SetSetTransporter(object1, object2);
        fi;

    # OnSetsTuples
    elif action = OnSetsTuples and ForAll([object1, object2], IsSet)
      and ForAll(object1, x -> IsHomogeneousList(x) and ForAll(x, IsPosInt))
      and ForAll(object2, x -> IsHomogeneousList(x) and ForAll(x, IsPosInt))
      then
        if Length(object1) <> Length(object2) then
            return VoleCon.None();
        else
            return VoleRefiner.SetTupleTransporter(object1, object2);
        fi;

    # OnTuplesSets
    elif action = OnTuplesSets and ForAll([object1, object2], IsHomogeneousList)
      and ForAll(object1, x -> IsSet(x) and ForAll(x, IsPosInt))
      and ForAll(object2, x -> IsSet(x) and ForAll(x, IsPosInt)) then
        if Length(object1) <> Length(object2) then
            return VoleCon.None();
        else
            return List([1 .. Length(object1)], i ->
                        VoleRefiner.SetTransporter(object1[i], object2[i]));
        fi;

    # OnTuplesTuples
    elif action = OnTuplesTuples
      and ForAll([object1, object2], IsHomogeneousList)
      and ForAll(object1, x -> IsHomogeneousList(x) and ForAll(x, IsPosInt))
      and ForAll(object2, x -> IsHomogeneousList(x) and ForAll(x, IsPosInt))
      then
        if Length(object1) <> Length(object2) then
            return VoleCon.None();
        else
            return List([1 .. Length(object1)], i ->
                        VoleRefiner.TupleTransporter(object1[i], object2[i]));
        fi;

    # OnDigraphs / lists of adjacencies
    elif action = OnDigraphs and ForAll([object1, object2], IsList)
      and ForAll([object1, object2], o -> ForAll(o, x -> IsHomogeneousList(x)))
      then
        if Length(object1) <> Length(object2) then
            return VoleCon.None();
        else
            return VoleRefiner.DigraphTransporter(object1, object2);
        fi;

    # OnDigraphs / Digraphs package objects
    elif action = OnDigraphs and IsDigraph(object1) and IsDigraph(object2) then
        if DigraphNrVertices(object1) <> DigraphNrVertices(object2) then
            return VoleCon.None();
        else
            return VoleRefiner.DigraphTransporter(OutNeighbours(object1),
                                                  OutNeighbours(object2));
        fi;

    fi;
    ErrorNoReturn("VoleCon.Stabilize: Unrecognised combination of ",
                  "<object1>, <object2>, and <action>:\n",
                  ViewString(object1), ", ", ViewString(object2), " and ",
                  NameFunction(action));
end;

VoleCon.InGroup := function(G)
    if not IsPermGroup(G) then
        ErrorNoReturn("VoleCon.InGroup: The argument must be a perm group");
    fi;

    if IsNaturalSymmetricGroup(G) then
        return VoleRefiner.InSymmetricGroup(MovedPoints(G));
    fi;
    return GB_Con.InGroup(G);
end;

VoleCon.InCoset := function(U)
    if not IsRightCoset(U) then
        ErrorNoReturn("VoleCon.InCoset: ",
                      "The argument must be a GAP right coset object");
    fi;
    return VoleCon.InRightCoset(ActingDomain(U), Representative(U));
end;

VoleCon.InRightCoset := function(G, x)
    local movedG, movedx, differ;

    if not IsPermGroup(G) then
        ErrorNoReturn("VoleCon.InRightCoset: ",
                      "The first argument must be a perm group");
    elif not IsPerm(x) then
        ErrorNoReturn("VoleCon.InRightCoset: ",
                      "The second argument must be a permutation");
    elif IsNaturalSymmetricGroup(G) then
        movedG := MovedPoints(G);  # is a GAP set
        movedx := MovedPoints(x);
        differ := Difference(movedx, movedG);
        return [VoleCon.MovedPoints(Union(movedG, movedx)),
                VoleCon.Transport(movedG, OnSets(movedG, x), OnSets),
                VoleCon.Transport(differ, OnTuples(differ, x), OnTuples)];
    fi;
    return GB_Con.InCosetSimple(G, x);
end;

VoleCon.InLeftCoset := function(G, x)
    if not IsPermGroup(G) then
      ErrorNoReturn("VoleCon.InLeftCoset: ",
                    "The first argument must be a perm group");
    elif not IsPerm(x) then
      ErrorNoReturn("VoleCon.InRightCoset: ",
                    "The second argument must be a permutation");
    fi;
    return VoleCon.InRightCoset(G ^ x, x);
end;

VoleCon.Normalise := function(G)
    if not IsPermGroup(G) then
        ErrorNoReturn("VoleCon.Normalise: The argument must be a perm group");
    fi;
    return GB_Con.NormaliserSimple2(G);
end;
VoleCon.Normalize := VoleCon.Normalise;

VoleCon.Centralise := function(G)
    if IsPermGroup(G) then
        return List(GeneratorsOfGroup(G), VoleCon.Centralise);
    elif IsPerm(G) then
        return GB_Con.PermConjugacy(G, G);
    fi;
    ErrorNoReturn("VoleCon.Centralise: ",
                  "The argument must be a perm or perm group");
end;
VoleCon.Centralize := VoleCon.Centralise;

VoleCon.Conjugate := function(G, H)
    if IsPermGroup(G) and IsPermGroup(H) then
        return GB_Con.GroupConjugacySimple2(G,H);
    elif IsPerm(G) and IsPerm(H) then
        return GB_Con.PermConjugacy(G, H);
    fi;
    ErrorNoReturn("VoleCon.Conjugate: ",
                  "The arguments must be two perms or two perm groups");
end;

VoleCon.MovedPoints := function(pointlist)
    if not IsList(pointlist) or not ForAll(pointlist, IsPosInt) then
        ErrorNoReturn("VoleCon.MovedPoints: ",
                      "The argument must be a list of positive integers");
    fi;
    return VoleRefiner.InSymmetricGroup(pointlist);
end;

VoleCon.LargestMovedPoint := function(point)
    if not IsPosInt(point) then
        ErrorNoReturn("VoleCon.LargestMovedPoint: ",
                      "The argument must be a positive integer");
    fi;
    return VoleRefiner.InSymmetricGroup([1 .. point]);
end;

VoleCon.None := ReturnFail;
