
GB_Con.NormaliserSimple := function(group)
    local orbList,getOrbits, orbMap, pointMap, r, invperm,minperm;

    getOrbits := function(pointlist, n)
        local G,orbs,graph,cols, orb;
        Info(InfoGB, 1, "Normaliser for pointlist", pointlist);
        G := Stabilizer(group, pointlist, OnTuples);

        orbs := Orbits(G, [1..n]);
        
        orbs := Filtered(orbs, o -> Length(o)>1);
        
        if Length(orbs) = 0 then
            return [];
        fi;

        if Length(orbs) = 1 then
            orb := Immutable(Set(orbs[1]));
            return [{x} -> x in orb];
        fi;

        graph := ListWithIdenticalEntries(n, []);
        cols := ListWithIdenticalEntries(n, 0);
        Append(graph, orbs);
        Append(cols, List(orbs, {x} -> Length(x)));
        Info(InfoGB, 2, "Made graph: ", Digraph(graph));
        return [rec( graph := Digraph(graph), vertlabels := cols)];
    end;

    r := rec(
        name := "NormaliserSimple",
        largest_required_point := LargestMovedPoint(group),
        constraint := Constraint.Stabilise(group, OnPoints),
        refine := rec(
            initialise := function(ps, buildingRBase)
                # Set 'seenDepth to -1 at the start. Note we always start searching at 'seenDepth + 1' which will be 0
                r!.btdata := rec(seenDepth := -1);
                return r!.refine.fixed(ps, buildingRBase);
            end,
            fixed := function(ps, buildingRBase)
                local fixedpoints, result;
                fixedpoints := PS_FixedPoints(ps);
                Assert(2, r!.btdata.seenDepth <= Length(fixedpoints));
                result := Concatenation(List([r!.btdata.seenDepth + 1..Length(fixedpoints)], x -> getOrbits(fixedpoints{[1..x]}, PS_Points(ps))));
                r!.btdata.seenDepth := Length(fixedpoints);
                return result;
            end)
        );
        return Objectify(GBRefinerType, r);
    end;

# A refiner based on Leon's Normaliser refiner (with added block structures)
GB_Con.GroupConjugacySimple2 := function(groupL, groupR)
    local orbList,getOrbits, buildGraph, orbMap, pointMap, r, invperm,minperm;

    buildGraph := function(G, n, outlist)
        local orbs, graph, cols, blocks, b, parts, curlength;

        orbs := Orbits(G, [1..n]);        
        orbs := Filtered(orbs, o -> Length(o)>1);

        if Length(orbs) = 1 then
            blocks := RepresentativesMinimalBlocks(G, orbs[1]);
            Info(InfoGB, 2, "Found blocks: ", blocks);
            graph := ListWithIdenticalEntries(n, []);
            for b in blocks do
                parts := Orbit(G, Set(b), OnSets);
                if Length(parts) > 1 then
                    curlength := Length(graph);
                    Append(graph, parts);
                    Add(graph, [curlength+1..curlength+Length(parts)]);
                fi;
            od;
            Info(InfoGB, 2, "Made block system graph: ", graph);
            Add(outlist, rec(graph := Digraph(graph)));
        else
            graph := ListWithIdenticalEntries(n, []);
            cols := ListWithIdenticalEntries(n, 0);
            Append(graph, orbs);
            Append(cols, List(orbs, {x} -> Length(x)));
            Info(InfoGB, 2, "Made graph: ", graph);
            Add(outlist, rec( graph := Digraph(graph), vertlabels := cols));
        fi;
    end;

    getOrbits := function(pointlist, n, group)
        local G,orbs,graph,cols, i, outlist;
        G := group;
        # Stop if the list is empty
        if IsEmpty(pointlist) then
            return [];
        fi;
        pointlist := Reversed(pointlist);
        # if the first point isn't moved, then we would just be repeating earlier work
        if ForAll(GeneratorsOfGroup(G), p -> pointlist[1]^p = pointlist[1]) then
            return [];
        fi;

        outlist := [];
        for i in pointlist do
            if ForAny(GeneratorsOfGroup(G), p -> i^p <> i) then
                G := Stabilizer(G, i);
                buildGraph(G, n, outlist);
            fi;
        od;
        return outlist;
    end;

    r := rec(
        name := "NormaliserSimpleLeon",
        largest_required_point := Maximum(LargestMovedPoint(groupL),LargestMovedPoint(groupR)),
        constraint := Constraint.Transport(groupL, groupR, OnPoints),
        refine := rec(
            initialise := function(ps, buildingRBase)
                # Set 'seenDepth to -1 at the start. Note we always start searching at 'seenDepth + 1' which will be 0
                r!.btdata := rec(seenDepth := -1);
                return r!.refine.fixed(ps, buildingRBase);
            end,
            fixed := function(ps, buildingRBase)
                local fixedpoints, result, group;
                if buildingRBase then
                    group := groupL;
                else
                    group := groupR;
                fi;
                fixedpoints := PS_FixedPoints(ps);
                Assert(2, r!.btdata.seenDepth <= Length(fixedpoints));
                result := Concatenation(List([r!.btdata.seenDepth + 1..Length(fixedpoints)], x -> getOrbits(fixedpoints{[1..x]}, PS_Points(ps), group)));
                
                # Handle first call
                if r!.btdata.seenDepth = -1 then
                    buildGraph(group, PS_Points(ps), result);
                fi;

                r!.btdata.seenDepth := Length(fixedpoints);
                return result;
            end)
        );
        return Objectify(GBRefinerType, r);
    end;

GB_Con.NormaliserSimple2 := {g} -> GB_Con.GroupConjugacySimple2(g,g);
