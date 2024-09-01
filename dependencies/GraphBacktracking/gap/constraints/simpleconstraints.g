GB_Con := rec();


# Import BacktrackKit constraints

DeclareRepresentation("IsGBRefiner", IsRefiner, ["name", "check", "refine"]);
BindGlobal("GBRefinerType", NewType(BacktrackableStateFamily,
                                       IsGBRefiner));

InstallMethod(SaveState, [IsGBRefiner],
    function(con)
        if IsBound(con!.btdata) then
            return StructuralCopy(con!.btdata);
        else
            return fail;
        fi;
    end);

InstallMethod(RestoreState, [IsGBRefiner, IsObject],
    function(con, state)
        if state <> fail then
            con!.btdata := StructuralCopy(state);
        fi;
    end);

GB_Con.InCoset := function(group, perm)
    local orbList,fillOrbits, fillOrbitals, orbMap, orbitalMap, pointMap, r, invperm;
    invperm := perm^-1;
fillOrbits := function(pointlist, n)
        local orbs, array, i, j;
        # caching
        if IsBound(pointMap[pointlist]) then
            return pointMap[pointlist];
        fi;

        orbs := Orbits(Stabilizer(group, pointlist, OnTuples), [1..n]);
        orbMap[pointlist] := Set(orbs, Set);
        array := [];
        for i in [1..Length(orbs)] do
            for j in orbs[i] do
                array[j] := i;
            od;
        od;
        pointMap[pointlist] := array;
        return array;
    end;

    fillOrbitals := function(pointlist, n)
        local orbs, array, i, j;
        if IsBound(orbitalMap[pointlist]) then
            return orbitalMap[pointlist];
        fi;

        orbs := _BTKit.getOrbitalList(Stabilizer(group, pointlist, OnTuples), n);
        orbitalMap[pointlist] := orbs;
        return orbs;
    end;

    orbMap := HashMap();
    pointMap := HashMap();
    orbitalMap := HashMap();

    r := rec(
        name := "InGroup-GB",
        largest_required_point := Maximum(LargestMovedPoint(group), LargestMovedPoint(perm)),
        constraint := Constraint.InCoset(group, perm),
        refine := rec(
            rBaseFinished := function(getRBase)
                r!.RBase := getRBase;
            end,

            initialise := function(ps, buildingRBase)
                return r!.refine.fixed(ps, buildingRBase);
            end,

            fixed := function(ps, buildingRBase)
                local fixedpoints, points, fixedps, fixedrbase, p, graphs;
                if buildingRBase then
                    fixedpoints := PS_FixedPoints(ps);
                    points := fillOrbits(fixedpoints, PS_Points(ps));
                    graphs := fillOrbitals(fixedpoints, PS_Points(ps));
                    Info(InfoGB, 5, "Building RBase:", points);
                    return Concatenation([{x} -> points[x]]
                                        ,List(graphs, g -> rec(graph := g)));
                else
                    fixedps := PS_FixedPoints(ps);
                    Info(InfoGB, 1, "fixed: ", fixedps);
                    fixedrbase := PS_FixedPoints(r!.RBase);
                    fixedrbase := fixedrbase{[1..Length(fixedps)]};
                    Info(InfoGB, 1, "Initial rbase: ", fixedrbase);

                    if perm <> () then
                        fixedps := OnTuples(fixedps, invperm);
                        Info(InfoGB, 1, "fixed coset: ", fixedrbase);
                    fi;

                    p := RepresentativeAction(group, fixedps, fixedrbase, OnTuples);
                    Info(InfoGB, 1, "Find mapping (InGroup):\n"
                         , "    fixed points:   ", fixedps, "\n"
                         , "    fixed by rbase: ", fixedrbase, "\n"
                         , "    map:            ", p);

                    if p = fail then
                        return fail;
                    fi;

                    points := pointMap[fixedrbase];
                    graphs := orbitalMap[fixedrbase];
                    if perm = () then
                        return Concatenation([{x} -> points[x^p]],
                         List(graphs, {g} -> rec(graph := OnDigraphs(g, p^-1))));
                    else
                        Info(InfoGB, 5, fixedps, fixedrbase, List([1..PS_Points(ps)], i -> points[i^(p*invperm)]));
                        return Concatenation([{x} -> points[x^(invperm*p)]],
                          List(graphs, {g} -> rec(graph := OnDigraphs(g, (invperm*p)^-1))));
                    fi;
                fi;
            end)
        );
        return Objectify(GBRefinerType, r);
    end;

GB_Con.InGroup := {group} -> GB_Con.InCoset(group, ());
