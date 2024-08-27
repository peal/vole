if not IsBound(OnSetsDigraphs) then
    OnSetsDigraphs := {set, p} -> Set(set, D -> OnDigraphs(D, p));
fi;

GB_Con.SetDigraphs := function(setL, setR)
    local setGraphsToGraph;

    setGraphsToGraph := function(ps, set)
        local n, k, D, offset, anchor, i, v, cols;

        n := PS_Points(ps);
        k := Length(set);
        D := EmptyDigraph(IsMutableDigraph, n);
        DigraphDisjointUnion(Concatenation([D], set, [EmptyDigraph(k)]));
        cols := Concatenation(
            ListWithIdenticalEntries(n, 0),
            ListWithIdenticalEntries(Sum(set, DigraphNrVertices), 1),
            ListWithIdenticalEntries(k, 2)
        );

        offset := n;
        anchor := n + Sum(set, DigraphNrVertices);
        for i in [1 .. k] do
          anchor := anchor + 1;
          for v in DigraphVertices(set[i]) do
            DigraphAddEdge(D, v + offset, v);
            DigraphAddEdge(D, v + offset, anchor);
          od;
          offset := offset + DigraphNrVertices(set[i]);
        od;

        return rec(graph := MakeImmutable(D), vertlabels := cols);
    end;

    return Objectify(
        GBRefinerType,
        rec(
            name := "GB_SetDigraphs",
            largest_required_point := Maximum(
                MaximumList(List(setL, DigraphNrVertices), 0),
                MaximumList(List(setR, DigraphNrVertices), 0)
            ),
            constraint := Constraint.Transport(setL, setR, OnSetsDigraphs),
            refine := rec(
                initialise := function(ps, buildingRBase)
                    if buildingRBase then
                        return setGraphsToGraph(ps, setL);
                    else
                        return setGraphsToGraph(ps, setR);
                    fi;
                end
            ),
        )
    );
end;
