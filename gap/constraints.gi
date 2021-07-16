# Vole: Backtrack search in permutation groups with graphs
# A GAP package by Mun See Chang, Christopher Jefferson, and Wilf A. Wilson.
#
# SPDX-License-Identifier: MPL-2.0
#
# Implementations: Vole constraints

VoleCon.Stabilize := function(object, action...)
    if Length(action) = 1 and IsFunction(action[1]) then
        action := action[1];
    elif Length(action) = 0 then
        action := OnPoints;
    else
        ErrorNoReturn("VoleCon.Stabilize args: object[, action]");
    fi;

    if action = OnSets and IsSet(object) and ForAll(object, IsPosInt) then
        return VoleRefiner.SetStab(object);
    elif action = OnTuples
      and IsHomogeneousList(object) and ForAll(object, IsPosInt) then
        return VoleRefiner.TupleStab(object);
    elif action = OnSetsSets
      and IsSet(object)
      and ForAll(object, x -> IsSet(x) and ForAll(x, IsPosInt)) then 
        return VoleRefiner.SetSetStab(object);
    elif action = OnSetsTuples
      and IsSet(object)
      and ForAll(object, x -> IsHomogeneousList(x) and ForAll(x, IsPosInt)) then
        return VoleRefiner.SetTupleStab(object);
    elif action = OnDigraphs and IsList(object)
      and ForAll(object, x -> IsHomogeneousList(x) and
                              ForAll(x, y -> y in [1 .. Length(object)])) then
        return VoleRefiner.DigraphStab(object);
    elif action = OnDigraphs and IsDigraph(object) then
        return VoleRefiner.DigraphStab(OutNeighbours(object));
    elif action = OnPoints and IsPosInt(object) then
        return VoleRefiner.TupleStab([object]);
    fi;
    ErrorNoReturn("VoleCon.Stabilize: Unrecognised combination of ",
                  "<object> and <action>: ",
                  ViewString(object), " and ", NameFunction(action));
end;
VoleCon.Stabilise := VoleCon.Stabilize;

VoleCon.Transport := function(object1, object2, action...)
    if Length(action) = 1 and IsFunction(action[1]) then
        action := action[1];
    elif Length(action) = 0 then
        action := OnPoints;
    else
        ErrorNoReturn("VoleCon.Transport args: object1, object2[, action]");
    fi;

    if action = OnSets then
        return VoleRefiner.SetTransporter(object1, object2);
    elif action = OnTuples then
        return VoleRefiner.TupleTransporter(object1, object2);
    elif action = OnSetsSets then 
        return VoleRefiner.SetSetTransporter(object1, object2);
    elif action = OnSetsTuples then
        return VoleRefiner.SetTupleTransporter(object1, object2);
    elif action = OnDigraphs
      and IsHomogeneousList(object1) and IsList(object2)
      and ForAll(object1, x -> IsHomogeneousList(x) and
                               ForAll(x, y -> y in [1 .. Length(object1)]))
      and ForAll(object1, x -> IsHomogeneousList(x) and
                               ForAll(x, y -> y in [1 .. Length(object2)])) then
        return VoleRefiner.DigraphTransporter(object1, object2);
    elif action = OnDigraphs then
        return VoleRefiner.DigraphTransporter(OutNeighbours(object1),
                                              OutNeighbours(object2));
    elif action = OnPoints and IsPosInt(object1) and IsPosInt(object2) then
        return VoleRefiner.TupleTransporter([object1], [object2]);
    fi;
    ErrorNoReturn("VoleCon.Stabilize: Unrecognised combination of ",
                  "<object1>, <object2>, and <action>: ",
                  ViewString(object1), ", ", ViewString(object2), " and ",
                  NameFunction(action));
end;

VoleCon.InGroup := function(G)
    if not IsPermGroup(G) then
        ErrorNoReturn("VoleCon.InGroup: the argument must be a perm group");
    fi;

    if IsNaturalSymmetricGroup(G) then
        return VoleRefiner.InSymmetricGroup(MovedPoints(G));
    fi;
    # TODO special case NaturalAlternatingGroup too?
    
    return GB_Con.InGroupSimple(_Vole.lmp(G), G);
end;

VoleCon.InCoset := function(U)
    if not IsRightCoset(U) then
        ErrorNoReturn("VoleCon.InCoset: ",
                      "the argument must be a GAP right coset object");
    fi;
    return VoleCon.InRightCoset(ActingDomain(U), Representative(U));
end;

VoleCon.InRightCoset := function(G, x)
    if not IsPermGroup(G) then
        ErrorNoReturn("VoleCon.InRightCoset: ",
                      "the first argument must be a perm group");
    elif not IsPerm(x) then
        ErrorNoReturn("VoleCon.InRightCoset: ",
                      "the second argument must be a permutation");
    fi;
    # TODO should we check whether x in G? And return VoleCon.InGroup if so?
    # TODO special case a coset of a natural symmetric group?

    # TODO is this the 'best' bound?
    return GB_Con.InCosetSimple(Maximum(_Vole.lmp(G), _Vole.lmp(x)), G, x);
end;

VoleCon.InLeftCoset := function(G, x)
    if not IsPermGroup(G) then
      ErrorNoReturn("VoleCon.InLeftCoset: ",
                    "the first argument must be a perm group");
    elif not IsPerm(x) then
      ErrorNoReturn("VoleCon.InRightCoset: ",
                    "the second argument must be a permutation");
    fi;
    return VoleCon.InRightCoset(G ^ x, x);
end;

VoleCon.Normalize := function(G)
    if not IsPermGroup(G) then
        ErrorNoReturn("VoleCon.Normalize: the argument must be a perm group");
    fi;
    return GB_Con.NormaliserSimple2(LargestMovedPoint(G), G);
end;
VoleCon.Normalise := VoleCon.Normalize;

VoleCon.Centralize := function(G)
    if IsPermGroup(G) then
        # TODO
    elif IsPerm(G) then
        # TODO
    else
        ErrorNoReturn("TODO");
    fi;
    Error("TODO: not yet implemented");
end;
VoleCon.Centralise := VoleCon.Centralize;

VoleCon.MovedPoints := function(pointlist)
    if not IsList(pointlist) or not ForAll(pointlist, IsPosInt) then
        ErrorNoReturn("VoleCon.MovedPoints: ",
                      "the argument must be a list of positive integers");
    fi;
    return VoleRefiner.InSymmetricGroup(pointlist);
end;

VoleCon.LargestMovedPoint := function(point)
    if not IsPosInt(point) then
        ErrorNoReturn("VoleCon.LargestMovedPoint: ",
                      "the argument must be a positive integer");
    fi;
    return VoleRefiner.InSymmetricGroup([1 .. point]);
end;
