

InstallMethod(GB_MakeEquitableNone, [IsPartitionStack, IsTracer, IsList],
    function(ps, tracer, graphlist)
        return true;
end);


InstallMethod(GB_MakeEquitableWeak, [IsPartitionStack, IsTracer, IsList],
    function(ps, tracer, graphlist)
        local graph, cellcount, hm, v;
        cellcount := -1;
        while cellcount <> PS_Cells(ps) and PS_Cells(ps) <> PS_ExtendedPoints(ps) do
            cellcount := PS_Cells(ps);
            for graph in graphlist do
                #Print(graph,"\n");
                hm := [];
                for v in [1..PS_ExtendedPoints(ps)] do
                    hm[v] := List(_BTKit.OutNeighboursSafe(graph, v), {x} -> PS_CellOfPoint(ps, x));
                    # We negate to distinguish in and out neighbours ---------v
                    Append(hm[v], List(_BTKit.InNeighboursSafe(graph, v), {x} -> -PS_CellOfPoint(ps, x)));
                    #Print(v,":",hm[v],"\n");
                    Sort(hm[v]);
                od;
                #Print(hm,"\n");
                if not PS_SplitCellsByFunction(ps, tracer, {x} -> hm[x]) then
                    Info(InfoGB, 2, "EquitableWeak trace violation");
                    return false;
                fi;
            od;
            #Print(hm,"\n");
        od;
        return true;
end);

InstallMethod(GB_MakeEquitableStrong, [IsPartitionStack, IsTracer, IsList],
    function(ps, tracer, graphlist)
        local graph, gnum, cellcount, hm, v, n, hmsetset;
        cellcount := -1;
        while cellcount <> PS_Cells(ps) and PS_Cells(ps) <> PS_ExtendedPoints(ps) do
            cellcount := PS_Cells(ps);
            hm := List([1..PS_ExtendedPoints(ps)], {x} -> HashMap());
            for gnum in [1..Length(graphlist)] do
                graph := graphlist[gnum];
                for v in [1..PS_ExtendedPoints(ps)] do
                    for n in _BTKit.OutNeighboursSafe(graph, v) do
                        if not IsBound(hm[v][n]) then
                            hm[v][n] := [];
                        fi;
                        Add(hm[v][n], [gnum, PS_CellOfPoint(ps, n), true]);
                    od;
                    for n in _BTKit.InNeighboursSafe(graph, v) do
                        if not IsBound(hm[v][n]) then
                            hm[v][n] := [];
                        fi;
                        Add(hm[v][n], [gnum, PS_CellOfPoint(ps, n), false]);
                    od;
                od;
            od;
            hmsetset := List([1..PS_ExtendedPoints(ps)], {x} -> SortedList(List(Values(hm[x]), SortedList)) );
            if not PS_ExtendedSplitCellsByFunction(ps, tracer, {x} -> hmsetset[x]) then
                Info(InfoGB, 2, "EquitableStrong trace violation");
                return false;
            fi;
            #Print(hm,"\n");
        od;
        return true;
end);


_GB.StateToDigraph := function(ps, graphlist)
    local edges, n,i,j, colours;
    n := PS_ExtendedPoints(ps);

    if IsEmpty(graphlist) then
        edges := ListWithIdenticalEntries(PS_ExtendedPoints(ps), []);
    else
        # All edges will point to the bottom layer, but that's fine
        edges := Concatenation(
            List(graphlist, {g} -> List(g!.OutNeighbours, List)));
    fi;

    for i in [0..Length(graphlist)-2] do
        for j in [1..n] do
            Add(edges[i*n+j], (i+1)*n+j);
        od;
    od;

    colours := PS_AsPartition(ps);
    for i in [1..Length(graphlist)-1] do
        Add(colours, [i*n+1..(i+1)*n]);
    od;
    Info(InfoGB, 3, edges, colours);
    return [Digraph(edges), colours];
end;

_GB.AutoAndCanonical := function(ps, graphlist)
    local ret;
    ret := _GB.StateToDigraph(ps, graphlist);
    return rec(
        graph := ret,
        canonicalperm := BlissCanonicalLabelling(ret[1], ret[2]),
        grp := AutomorphismGroup(ret[1], ret[2])
    );
end;

InstallMethod(GB_MakeEquitableFull, [IsPartitionStack, IsTracer, IsList],
    function(ps, tracer, graphlist)
        local ret, canonical, grp, conjgrp, orblist, orbs, i, o;
        if IsEmpty(graphlist) then
            return true;
        fi;
        if not GB_MakeEquitableStrong(ps, tracer, graphlist) then
            return false;
        fi;
        ret := _GB.AutoAndCanonical(ps, graphlist);
        canonical := ret.canonicalperm;
        grp := ret.grp;
        conjgrp := grp^canonical;
        orbs := Orbits(conjgrp, [1..PS_Points(ps)]);
        orbs := Set(orbs, Set);
        orbs := OnTuplesSets(orbs, canonical^-1);
        orblist := [];
        for i in [1..Length(orbs)] do
            for o in orbs[i] do
                orblist[o] := i;
            od;
        od;
        Info(InfoGB, 2, "SplitWith:", ret, orblist);
        if not PS_SplitCellsByFunction(ps, tracer, {x} -> orblist[x]) then
                Info(InfoGB, 2, "EquitableFull trace violation");
                return false;
        fi;
        return true;
end);
