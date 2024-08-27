#
# GraphBacktracking
#
# Implementations
#

DeclareRepresentation("IsGBState", IsBacktrackableState and IsBTKitState, []);
BindGlobal("GBStateType", NewType(BacktrackableStateFamily,
                                       IsGBState));

InstallMethod(SaveState, [IsGBState],
 function(state)
    return rec(depth := PS_Cells(state!.ps),
               refiners := List(state!.conlist, SaveState),
               graphs := ShallowCopy(state!.graphs),
               raw_graphs := ShallowCopy(state!.raw_graphs));
end);

InstallMethod(RestoreState, [IsGBState, IsObject],
 function(state, saved)
    local c;
    PS_RevertToCellCount(state!.ps, saved.depth);
    for c in [1..Length(saved.refiners)] do
        RestoreState(state!.conlist[c], saved.refiners[c]);
    od;
    state!.graphs := ShallowCopy(saved.graphs);
    state!.raw_graphs := ShallowCopy(saved.raw_graphs);
end);

_GB.ShiftGraph := function(ps, f, state, tracer)
    local extra_pnts, old_max, vert_map, new_graph, new_cell, shift_size;

    extra_pnts := DigraphNrVertices(f.graph) - PS_Points(ps);
    if not AddEvent(tracer, rec(type := "NewVertices", pos := extra_pnts)) then
        Info(InfoGB, 1, "number of extra vertices not consistent");
        return false;
    fi;

    old_max := PS_ExtendedPoints(ps);
    shift_size := old_max - PS_Points(ps);
    new_cell := PS_Extend(ps, extra_pnts);

    if IsBound(f.vertlabels) then
        # Split the new cells by vertex colour (only worry about the new vertices here)
        if not PS_SplitCellByFunction(state!.ps, tracer, new_cell, {x} -> f.vertlabels[x-shift_size]) then
            return false;
        fi;
    fi;

    vert_map := Concatenation([1..PS_Points(ps)], [old_max+1..old_max+extra_pnts]);

    new_graph := List(DigraphEdges(f.graph), {x} -> [vert_map[x[1]], vert_map[x[2]]]);

    return DigraphByEdges(new_graph);
end;

InstallMethod(ApplyFilters, [IsGBState, IsTracer, IsObject],
  function(state, tracer, filters)
    local f, ret, applyFilter, g, pos;
    if filters = fail then
        Info(InfoGB, 1, "Failed filter");
        return false;
    fi;

    if not IsList(filters) then
        filters := [filters];
    fi;

    for f in filters do
        Assert(2, IsFunction(f) or IsSubset(["graph", "vertlabels"], RecNames(f)));
        if IsFunction(f) then
            if not PS_SplitCellsByFunction(state!.ps, tracer, f) then
                Info(InfoGB, 1, "Trace violation");
                return false;
            fi;
        else
            if not IsRecord(f) then
                ErrorNoReturn("Refiner must be a function or record: ", filters);
            fi;
            if IsBound(f.vertlabels) then
                # Note that this only covers the 'basic' vertices, any extended ones
                # are handled later in 'ShiftGraph'
                if not PS_SplitCellsByFunction(state!.ps, tracer, {x} -> f.vertlabels[x]) then
                    Info(InfoGB, 1, "Trace violation (vertex colouring)");
                    return false;
                fi;
            fi;
            if IsBound(f.graph) then
                # TODO (maybe) -- this skipping of merged graphs ignores
                # vertex colourings.
                pos := fail; # This isn't valid for normalisers (and others): Position(state!.raw_graphs, f.graph);
                if pos = fail then
                    Add(state!.raw_graphs, f.graph);
                    if PS_Points(state!.ps) < DigraphNrVertices(f.graph) then
                        g := _GB.ShiftGraph(state!.ps, f, state, tracer);
                        if g = false then
                            # Refining extra colours of new graph failed
                            return false;
                        fi;
                    else
                        g := f.graph;
                    fi;
                    Add(state!.graphs, g);
                else
                    if not AddEvent(tracer, rec(type := "SkipGraph", pos := pos)) then
                        Info(InfoGB, 1, "Failed graph merge");
                        return false;
                    fi;
                fi;
            fi;
        fi;
    od;
    return true;
end);




_GB.DefaultConfig :=
    rec(cellSelector := BranchSelector_MinSizeCell, consolidator := GB_MakeEquitableStrong);

InstallMethod(ConsolidateState, [IsGBState, IsTracer],
    function(state, tracer)
        return state!.config.consolidator(state!.ps, tracer, state!.graphs);
    end);

_GB.BuildProblem :=
    {ps, conlist, conf} -> Objectify(GBStateType, rec(ps := ps, conlist := conlist, graphs := [], raw_graphs := [],
                            config := _BTKit.FillConfig(conf, _GB.DefaultConfig)));

# For read.g
_BTKit.FilesReadGB := true;
