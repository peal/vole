# Vole: Backtrack search in permutation groups with graphs
# A GAP package by Mun See Chang, Christopher Jefferson, and Wilf A. Wilson.
#
# SPDX-License-Identifier: MPL-2.0
#
# Implementations: Vole refiners

# In-group refiners
VoleRefiner.InSymmetricGroup := {s} -> Objectify(VoleRefinerType,
rec(
    constraint := Constraint.MovedPoints(_Vole.points(s)),
    con := rec(InSymmetricGroup := rec(points := _Vole.points(s))),
    largest_required_point := _BTKit.LargestRelevantPoint(s),
));

# Stabilisers
VoleRefiner.SetStab := {s} -> Objectify(VoleRefinerType,
rec(
    constraint := Constraint.Stabilise(s, OnSets),
    con := rec(SetStab := rec(points := s)),
    largest_required_point := _BTKit.LargestRelevantPoint(s),
));
VoleRefiner.TupleStab := {s} -> Objectify(VoleRefinerType,
rec(
    constraint := Constraint.Stabilise(s, OnTuples),
    con := rec(TupleStab := rec(points := s)),
    largest_required_point := _BTKit.LargestRelevantPoint(s),
));
VoleRefiner.SetSetStab := {s} -> Objectify(VoleRefinerType,
rec(
    constraint := Constraint.Stabilise(s, OnSetsSets),
    con := rec(SetSetStab := rec(points := s)),
    largest_required_point := _BTKit.LargestRelevantPoint(s),
));
VoleRefiner.SetTupleStab := {s} -> Objectify(VoleRefinerType,
rec(
    constraint := Constraint.Stabilise(s, OnSetsTuples),
    con := rec(SetTupleStab := rec(points := s)),
    largest_required_point := _BTKit.LargestRelevantPoint(s),
));
VoleRefiner.DigraphStab := {s} -> Objectify(VoleRefinerType,
rec(
    constraint := Constraint.Stabilise(s, OnDigraphs),
    con := rec(DigraphStab := rec(edges := _Vole.Digraph(s))),
    largest_required_point := _BTKit.LargestRelevantPoint(s),
));

# Transporters
VoleRefiner.SetTransporter := {s, t} -> Objectify(VoleRefinerType,
rec(
    constraint := Constraint.Transport(s, t, OnSets),
    con := rec(SetTransport := rec(left_points := s, right_points := t)),
    largest_required_point := _BTKit.LargestRelevantPoint(s, t),
));
VoleRefiner.TupleTransporter := {s, t} -> Objectify(VoleRefinerType,
rec(
    constraint := Constraint.Transport(s, t, OnTuples),
    con := rec(TupleTransport := rec(left_points := s, right_points := t)),
    largest_required_point := _BTKit.LargestRelevantPoint(s, t),
));
VoleRefiner.SetSetTransporter := {s, t} -> Objectify(VoleRefinerType,
rec(
    constraint := Constraint.Transport(s, t, OnSetsSets),
    con := rec(SetSetTransport := rec(left_points := s, right_points := t)),
    largest_required_point := _BTKit.LargestRelevantPoint(s, t),
));
VoleRefiner.SetTupleTransporter := {s, t} -> Objectify(VoleRefinerType,
rec(
    constraint := Constraint.Transport(s, t, OnSetsTuples),
    con := rec(SetTupleTransport := rec(left_points := s, right_points := t)),
    largest_required_point := _BTKit.LargestRelevantPoint(s, t),
));
VoleRefiner.DigraphTransporter := {s, t} -> Objectify(VoleRefinerType,
rec(
    constraint := Constraint.Transport(s, t, OnDigraphs),
    con := rec(
        DigraphTransport := rec(
            left_edges  := _Vole.Digraph(s),
            right_edges := _Vole.Digraph(t),
        ),
    ),
    largest_required_point := _BTKit.LargestRelevantPoint(s, t),
));

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

InstallMethod(ViewString, "for a Vole refiner", [IsVoleRefiner],
function(r)
    local str, con, nam;
    con := r!.constraint;
    nam := RecNames(r!.con)[1];
    str := StringFormatted("<Vole refiner: {}", nam);
    if nam = "InSymmetricGroup" then
        Append(str, StringFormatted(" on {}>", r!.con.InSymmetricGroup.points));
    elif IsStabiliserConstraint(con) then
        Append(str, StringFormatted(" of {}>", SourceObject(con)));
    else
        Append(str, StringFormatted(" from {} to {}", SourceObject(con), ResultObject(con)));
    fi;
    return str;
end);
