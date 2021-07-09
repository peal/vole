# Vole: Backtrack search in permutation groups with graphs
# A GAP package by Mun See Chang, Christopher Jefferson, and Wilf A. Wilson.
#
# SPDX-License-Identifier: MPL-2.0
#
# Implementations: TODO

InstallValue(VoleCon, rec());

VoleCon.Stabilize := function(s, action...)
    if Length(action) = 1 then
        action := action[1];
    elif Length(action) = 0 then
        action := OnPoints;
    else
        ErrorNoReturn("VoleCon.Stabilizer args: obj [, action]");
    fi;

    if action = OnSets then
        return VoleRefiner.SetStab(s);
    elif action = OnTuples then
        return VoleRefiner.TupleStab(s);
    elif action = OnSetsSets then 
        return VoleRefiner.SetSetStab(s);
    elif action = OnSetsTuples then
        return VoleRefiner.SetTupleStab(s);
    elif action = OnDigraphs then
        return VoleRefiner.DigraphStab(s);
    else
        ErrorNoReturn("Invalid action: ", action);
    fi;
end;

VoleCon.Transport := function(s, t, action...)
    if Length(action) = 1 then
        action := action[1];
    elif Length(action) = 0 then
        action := OnPoints;
    else
        ErrorNoReturn("VoleCon.Transport args: obj1, obj2 [, action]");
    fi;

    if action = OnSets then
        return VoleRefiner.SetTransporter(s,t);
    elif action = OnTuples then
        return VoleRefiner.TupleTransporter(s,t);
    elif action = OnSetsSets then 
        return VoleRefiner.SetSetTransporter(s,t);
    elif action = OnSetsTuples then
        return VoleRefiner.SetTupleTransporter(s,t);
    elif action = OnDigraphs then
        return VoleRefiner.DigraphTransporter(s,t);
    else
        ErrorNoReturn("Invalid action: ", action);
    fi;
end;

VoleCon.InGroup := function(g)
    if not IsPermGroup(g) then
        ErrorNoReturn("VoleCon.InGroup: the argument must be a perm group");
    fi;

    if IsNaturalSymmetricGroup(g) then
        return VoleRefiner.InSymmetricGroup(MovedPoints(g));
    fi;
    
    return rec(bounds := rec(largest_required_point :=_Vole.lmp(g), largest_moved_point := _Vole.lmp(g), con := GB_Con.InGroupSimple(g)));
end;

VoleCon.Normalize := function(g)
    if not IsPermGroup(g) then
        ErrorNoReturn("VoleCon.Normalize: the argument must be a perm group");
    fi;
    Error("TODO: not yet implemented");
end;

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
