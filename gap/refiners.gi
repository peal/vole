# Vole: Backtrack search in permutation groups with graphs
# A GAP package by Mun See Chang, Christopher Jefferson, and Wilf A. Wilson.
#
# SPDX-License-Identifier: MPL-2.0
#
# Implementations: Vole refiners

# In-group refiners
VoleRefiner.InSymmetricGroup := {s} -> rec(
    bounds := rec(
        largest_required_point := _BTKit.LargestRelevantPoint(s),
        largest_moved_point := _BTKit.LargestRelevantPoint(s),
    ),
    con := rec(InSymmetricGroup := rec(points := _Vole.points(s))),
);

# Stabilisers
VoleRefiner.PointStab     := {s} -> rec( bounds := rec(largest_required_point :=_BTKit.LargestRelevantPoint(s)), con := rec(PointStab := rec(points := [s])));
VoleRefiner.SetStab       := {s} -> rec( bounds := rec(largest_required_point :=_BTKit.LargestRelevantPoint(s)), con := rec(SetStab := rec(points := s)));
VoleRefiner.TupleStab     := {s} -> rec( bounds := rec(largest_required_point :=_BTKit.LargestRelevantPoint(s)), con := rec(TupleStab := rec(points := s)));
VoleRefiner.SetSetStab    := {s} -> rec( bounds := rec(largest_required_point :=_BTKit.LargestRelevantPoint(s)), con := rec(SetSetStab := rec(points := s)));
VoleRefiner.SetTupleStab  := {s} -> rec( bounds := rec(largest_required_point :=_BTKit.LargestRelevantPoint(s)), con := rec(SetTupleStab := rec(points := s)));
VoleRefiner.DigraphStab   := {s} -> rec( bounds := rec(largest_required_point :=_BTKit.LargestRelevantPoint(s)), con := rec(DigraphStab := rec(edges := _Vole.Digraph(s))));

# Transporters
VoleRefiner.PointTransporter    := {s,t} -> rec( bounds := rec(largest_required_point :=_BTKit.LargestRelevantPoint(s,t)), con := rec(PointTransport    := rec(left_points := [s], right_points := [t])));
VoleRefiner.SetTransporter      := {s,t} -> rec( bounds := rec(largest_required_point :=_BTKit.LargestRelevantPoint(s,t)), con := rec(SetTransport      := rec(left_points := s, right_points := t)));
VoleRefiner.TupleTransporter    := {s,t} -> rec( bounds := rec(largest_required_point :=_BTKit.LargestRelevantPoint(s,t)), con := rec(TupleTransport    := rec(left_points := s, right_points := t)));
VoleRefiner.SetSetTransporter   := {s,t} -> rec( bounds := rec(largest_required_point :=_BTKit.LargestRelevantPoint(s,t)), con := rec(SetSetTransport   := rec(left_points := s, right_points := t)));
VoleRefiner.SetTupleTransporter := {s,t} -> rec( bounds := rec(largest_required_point :=_BTKit.LargestRelevantPoint(s,t)), con := rec(SetTupleTransport := rec(left_points := s, right_points := t)));
VoleRefiner.DigraphTransporter  := {s,t} -> rec( bounds := rec(largest_required_point :=_BTKit.LargestRelevantPoint(s,t)), con := rec(DigraphTransport  := rec(left_edges := _Vole.Digraph(s), right_edges := _Vole.Digraph(t))));

VoleRefiner.FromConstraint := function(con)
    local action, source, result;

    # FIXME Hack, should probably only be called on constraint objects
    if not IsConstraint(con) then
        return con;
    fi;

    if HasIsEmptyConstraint(con) and IsEmptyConstraint(con) then
        return BTKit_Refiner.Nothing();

    elif IsGroupConstraint(con) and HasUnderlyingGroup(con) and IsNaturalSymmetricGroup(UnderlyingGroup(con)) then
        return VoleRefiner.InSymmetricGroup(MovedPoints(UnderlyingGroup(con)));

    elif IsTransporterConstraint(con) then
        action := ActionFunc(con);
        source := SourceObject(con);
        result := ResultObject(con);

        if action = OnPoints and IsPosInt(source) then
            if IsStabiliserConstraint(con) then
                return VoleRefiner.TupleStab([source]);
            else
                return VoleRefiner.TupleTransporter([source], [result]);
            fi;

        elif action = OnTuples and ForAll(source, IsPosInt) then
            if IsStabiliserConstraint(con) then
                return VoleRefiner.TupleStab(source);
            else
                return VoleRefiner.TupleTransporter(source, result);
            fi;

        elif action = OnSets and ForAll(source, IsPosInt) then
            if IsStabiliserConstraint(con) then 
                return VoleRefiner.SetStab(source);
            else
                return VoleRefiner.SetTransporter(source, result);
            fi;

        elif action = OnTuplesTuples then
            if IsStabiliserConstraint(con) then
                return List(source, i -> VoleRefiner.TupleStab(i));
            else
                return List([1 .. Length(source)], i -> VoleRefiner.TupleTransporter(source[i], result[i]));
            fi;

        elif action = OnTuplesSets then
            if IsStabiliserConstraint(con) then
                return List(source, i -> VoleRefiner.SetStab(i));
            else
                return List([1 .. Length(source)], i -> VoleRefiner.SetTransporter(source[i], result[i]));
            fi;

        elif action = OnSetsTuples then
            if IsStabiliserConstraint(con) then 
                return VoleRefiner.SetTupleStab(source);
            else
                return VoleRefiner.SetTupleTransporter(source, result);
            fi;

        elif action = OnSetsSets then
            if IsStabiliserConstraint(con) then 
                return VoleRefiner.SetSetStab(source);
            else
                return VoleRefiner.SetSetTransporter(source, result);
            fi;

        elif action = OnDigraphs then
            if IsDigraph(source) then
                source := OutNeighbours(source);
                result := OutNeighbours(result);
            fi;
            if IsStabiliserConstraint(con) then
                return VoleRefiner.DigraphStab(source);
            else
                return VoleRefiner.DigraphTransporter(source, result);
            fi;

        elif action = OnTuplesDigraphs then
            if ForAll(source, IsDigraph) then
                source := List(source, OutNeighbours);
                result := List(result, OutNeighbours);
            fi;
            if IsStabiliserConstraint(con) then
                return List(source, i -> VoleRefiner.DigraphStab(i));
            else
                return List([1 .. Length(source)], i -> VoleRefiner.DigraphTransporter(source[i], result[i]));
            fi;

        elif action = OnPoints and IsPerm(source) then
            return BTKit_Refiner.PermTransporter(source, result);

        fi;

    fi;

    return GB_RefinerFromConstraint(con);
end;
