# Vole: Backtrack search in permutation groups with graphs
# A GAP package by Mun See Chang, Christopher Jefferson, and Wilf A. Wilson.
#
# SPDX-License-Identifier: MPL-2.0
#
# Implementations: TODO

VoleCon.Stabilize := function(obj, action...)
    if Length(action) = 1 then
        action := action[1];
    elif Length(action) = 0 then
        action := OnPoints;
    else
        ErrorNoReturn("VoleCon.Stabilizer args: obj[, action]");
    fi;

    if action = OnSets then
        return VoleRefiner.SetStab(obj);
    elif action = OnTuples then
        return VoleRefiner.TupleStab(obj);
    elif action = OnSetsSets then 
        return VoleRefiner.SetSetStab(obj);
    elif action = OnSetsTuples then
        return VoleRefiner.SetTupleStab(obj);
    elif action = OnDigraphs then
        return VoleRefiner.DigraphStab(obj);
    fi;
    # TODO OnPoints
    ErrorNoReturn("Invalid action: ", action);
end;
VoleCon.Stabilise := VoleCon.Stabilize;

VoleCon.Transport := function(obj1, obj2, action...)
    if Length(action) = 1 then
        action := action[1];
    elif Length(action) = 0 then
        action := OnPoints;
    else
        ErrorNoReturn("VoleCon.Transport args: obj1, obj2[, action]");
    fi;

    if action = OnSets then
        return VoleRefiner.SetTransporter(obj1, obj2);
    elif action = OnTuples then
        return VoleRefiner.TupleTransporter(obj1, obj2);
    elif action = OnSetsSets then 
        return VoleRefiner.SetSetTransporter(obj1, obj2);
    elif action = OnSetsTuples then
        return VoleRefiner.SetTupleTransporter(obj1, obj2);
    elif action = OnDigraphs then
        return VoleRefiner.DigraphTransporter(obj1, obj2);
    fi;
    ErrorNoReturn("Unrecognised action: ", action);
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
    Error("TODO: not yet implemented");
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
        ErrorNoReturn("VoleCon.MovedPoints: the argument must be a list of positive integers");
    fi;
    return VoleRefiner.InSymmetricGroup(pointlist);
end;

VoleCon.LargestMovedPoint := function(point)
    if not IsPosInt(point) then
        ErrorNoReturn("VoleCon.LargestMovedPoint: the argument must be a positive integer");
    fi;
    return VoleRefiner.InSymmetricGroup([1 .. point]);
end;
