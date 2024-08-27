GB_Con.InCosetSimple := function(group, perm)
    local orbList,getStructures, r, invperm,minperm;
    invperm := perm^-1;

    getStructures := function(pointlist, n)
        local orbs, array, i, j, graphs;

        orbs := StabTreeStabilizerOrbits(group, pointlist, [1..n]);
        graphs := StabTreeStabilizerReducedOrbitalGraphs(group, pointlist, [1..n]);
        
        array := [];

        for i in [1..Length(orbs)] do
            for j in orbs[i] do
                array[j] := i;
            od;
        od;
        #Print(group, pointlist, orbs, array, "\n");
        return rec(points := array, graphs := graphs);
    end;

    r := rec(
        name := "InGroupSimple",
        largest_required_point := Maximum(LargestMovedPoint(group), LargestMovedPoint(perm)),
        constraint := Constraint.InCoset(group, perm),
        refine := rec(
            initialise := function(ps, buildingRBase)
                return r!.refine.fixed(ps, buildingRBase);
            end,
            fixed := function(ps, buildingRBase)
                local fixedpoints, points, p, ret;
                fixedpoints := PS_FixedPoints(ps);
                
                if buildingRBase then
                    p := ();
                else
                    p := invperm;
                fi;

                fixedpoints := OnTuples(fixedpoints, p);
                ret := getStructures(fixedpoints, PS_Points(ps));

                return Concatenation([{x} -> ret.points[x^p]],
                    List(ret.graphs, {g} -> rec(graph := OnDigraphs(g, p^-1))));
            end)
        );
        return Objectify(GBRefinerType, r);
    end;

GB_Con.InGroupSimple := {group} -> GB_Con.InCosetSimple(group, ());
