
# Filters a partition stack by a graph, a single step
# The graph should be in the following format:
# graph[i] is the neighbours of vertex i.
# A neighbour should be a list [colour, neighbour],
# where neighbour is another vertex and colour is the 'colour' of the edge.
# For undirected graphs be sure to put the edge in, in both directions.
# For directed graphs, make the 'colour' of the edge in both directions different
# (for example 1 in the forward direction, -1 in the backward direction)
BTKit_FilterGraph := function(ps, graph)
    local list, points, i, v;
    points := PS_Points(ps);
    list := [];
    for i in [1..points] do
        list[i] := List(_BTKit.OutNeighboursSafe(graph, i), {x} -> PS_CellOfPoint(ps, x));
        # We negate to distinguish in and out neighbours ---------v
        Append(list[i], List(_BTKit.InNeighboursSafe(graph, i), {x} -> -PS_CellOfPoint(ps, x)));
        #Print(v,":",hm[v],"\n");
        Sort(list[i]);
    od;
    return list;
end;

# Make a refiner which accepts permutations p
# such that graphL = OnDigraphs(graphR, p)
BTKit_Refiner.GraphTrans := function(graphL, graphR)
    local filter;
    # Give an initial sort
    filter := function(ps, buildingRBase)
        local filt;
        if buildingRBase then
            filt := BTKit_FilterGraph(ps, graphL);
        else
            filt := BTKit_FilterGraph(ps, graphR);
        fi;
        return {x} -> filt[x];
    end;
    return Objectify(BTKitRefinerType, rec(
        name := "GraphTrans",
        largest_required_point := Maximum(Maximum(DigraphVertices(graphL), Maximum(DigraphVertices(graphR)))),
        constraint := Constraint.Transport(graphL, graphR, OnDigraphs),
        refine := rec(
            initialise := filter, 
            changed := filter
        )
    ));
end;

BTKit_Refiner.GraphStab := {graph} -> BTKit_Refiner.GraphTrans(graph, graph);
