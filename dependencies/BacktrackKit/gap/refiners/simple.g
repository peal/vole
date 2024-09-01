# Any refiner which can be expressed as "stabilize an ordered partition"
# can be implemented easily and efficently, as we only need to handle
# the root node of search (as we never gain more information from such a
# constraint as search progresses).
# Therefore we have two general functions which implement:
#
# MakeFixlistStabilizer: Returns the constraint which implements
#                        fixlist[i] = fixlist[i^p]
#
# MakeFixListTransporter: Returns the constraint which implements
#                         fixlistL[i] = fixlistR[i^p]
#
# These are used to then implement refiners for sets, tuples
# and ordered partitions.

# Make a refiner which accepts permutations p
# such that fixlist[i] = fixlist[i^p]
BTKit_MakeFixlistStabilizer := function(name, fixlist, o, action, lrp)
    local filters;
    filters := {i} -> GetWithDefault(fixlist, i, 0);
    return Objectify(BTKitRefinerType, rec(
        name := name,
        largest_required_point := lrp,
        constraint := Constraint.Stabilise(o, action),
        refine := rec(
            initialise := function(ps, buildingRBase)
                return filters;
            end)
    ));
end;

# Make a refiner which accepts permutations p
# such that fixlistL[i] = fixlistR[i^p]
BTKit_MakeFixlistTransporter := function(name, fixlistL, fixlistR, oL, oR, action, lrp)
    local filtersL, filtersR;
    filtersL := {i} -> GetWithDefault(fixlistL, i, 0);
    filtersR := {i} -> GetWithDefault(fixlistR, i, 0);
    return Objectify(BTKitRefinerType, rec(
        name := name,
        largest_required_point := lrp,
        constraint := Constraint.Transport(oL, oR, action),
        refine := rec(
            initialise := function(ps, buildingRBase)
                if buildingRBase then
                    return filtersL;
                else
                    return filtersR;
                fi;
            end
        ),
    ));
end;

BTKit_Refiner.TupleStab := function(fixpoints)
    local fixlist, i, max;
    max := MaximumList(fixpoints, 1);
    fixlist := ListWithIdenticalEntries(max, 0);
    for i in [1..Length(fixpoints)] do
        fixlist[fixpoints[i]] := i;
    od;
    return BTKit_MakeFixlistStabilizer("TupleStab", fixlist, fixpoints, OnTuples, max);
end;

BTKit_Refiner.TupleTransporter := function(fixpointsL, fixpointsR)
    local fixlistL, fixlistR, i, max;
    max := Maximum(MaximumList(fixpointsL,1),MaximumList(fixpointsR,1));
    fixlistL := ListWithIdenticalEntries(max, 0);
    for i in [1..Length(fixpointsL)] do
        fixlistL[fixpointsL[i]] := i;
    od;
    fixlistR := ListWithIdenticalEntries(max, 0);
    for i in [1..Length(fixpointsR)] do
        fixlistR[fixpointsR[i]] := i;
    od;
    return BTKit_MakeFixlistTransporter("TupleTransport", fixlistL, fixlistR, fixpointsL, fixpointsR, OnTuples, max);
end;

BTKit_Refiner.SetStab := function(fixset)
    local fixlist, i, max;
    max := MaximumList(fixset, 1);
    fixlist := ListWithIdenticalEntries(max, 0);
    for i in [1..Length(fixset)] do
        fixlist[fixset[i]] := 1;
    od;
    return BTKit_MakeFixlistStabilizer("SetStab", fixlist, fixset, OnSets, max);
end;

BTKit_Refiner.SetTransporter := function(fixsetL, fixsetR)
    local fixlistL, fixlistR, i, max;
    max := Maximum(MaximumList(fixsetL,1),MaximumList(fixsetR,1));
    fixlistL := ListWithIdenticalEntries(max, 0);
    for i in [1..Length(fixsetL)] do
        fixlistL[fixsetL[i]] := 1;
    od;
    fixlistR := ListWithIdenticalEntries(max, 0);
    for i in [1..Length(fixsetR)] do
        fixlistR[fixsetR[i]] := 1;
    od;
    return BTKit_MakeFixlistTransporter("SetTransport", fixlistL, fixlistR, fixsetL, fixsetR, OnSets, max);
end;


# The following refiner is probably the most complex. It implements
# 'permutation is in group given by list of generators'.
#
# Exactly why this refiner works, and why we use 'RepresentativeAction',
# requires more explanation than fits in this comment. However, every
# other refiner we have ever seen does not need to worry about the values
# in the rBase, so don't use this as a model for another refiner, unless
# that one is also based around a group given as a list of generators.
BTKit_Refiner.InCoset := function(group, perm)
    local orbList,fillOrbits, orbMap, pointMap, r, invperm;
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

    # OrbMap is unused?
    orbMap := HashMap();
    pointMap := HashMap();

    r := rec(
        name := "InCoset-BTKit",
        largest_required_point := Maximum(LargestMovedPoint(group), LargestMovedPoint(perm)),
        constraint := Constraint.InCoset(group, perm),
        refine := rec(
            rBaseFinished := function(getRBase)
                r!.RBase := getRBase;
            end,
            initialise := function(ps, buildingRBase)
                local fixedpoints, mapval, points;
                return r!.refine.fixed(ps, buildingRBase);
            end,
            fixed := function(ps, buildingRBase)
                local fixedpoints, points, fixedps, fixedrbase, p;
                if buildingRBase then
                    fixedpoints := PS_FixedPoints(ps);
                    points := fillOrbits(fixedpoints, PS_Points(ps));
                    return {x} -> points[x];
                else
                    fixedps := PS_FixedPoints(ps);
                    fixedrbase := PS_FixedPoints(r!.RBase);
                    fixedrbase := fixedrbase{[1..Length(fixedps)]};

                    if perm <> () then
                        fixedps := OnTuples(fixedps, invperm);
                    fi;

                    p := RepresentativeAction(group, fixedps, fixedrbase, OnTuples);
                    Info(InfoBTKit, 1, "Find mapping (InGroup):\n"
                         , "    fixed points:   ", fixedps, "\n"
                         , "    fixed by rbase: ", fixedrbase, "\n"
                         , "    map:            ", p);
                    
                    
                    if p = fail then
                        return fail;
                    fi;

                    # this could as well call fillOrbits
                    points := pointMap[fixedrbase];
                    if perm = () then
                        return {x} -> points[x^p];
                    else
                        return {x} -> points[x^(invperm*p)];
                    fi;
                fi;
            end)
        );
        return Objectify(BTKitRefinerType, r);
    end;

BTKit_Refiner.InGroup := {group} -> BTKit_Refiner.InCoset(group, ());

#####
#####
#####

##### Code from here is only temporary and will eventually be rewritten or removed.

_BTKit.RefineGraphs := function(points, ps, graphlist)
        local graph, cellcount, hm, v, ret;
        cellcount := -1;
        ret := List([1..points], x -> []);
        for graph in graphlist do
            #Print(graph,"\n");
            for v in [1..points] do
                hm := [];
                hm := List(_BTKit.OutNeighboursSafe(graph, v), {x} -> PS_CellOfPoint(ps, x));
                # We negate to distinguish in and out neighbours ---------v
                Append(hm, List(_BTKit.InNeighboursSafe(graph, v), {x} -> -PS_CellOfPoint(ps, x)));
                #Print(v,":",hm[v],"\n");
                Sort(hm);
                Append(ret[v], hm);
            od;
        od;
        return ret;
end;

BTKit_Refiner.InCosetWithOrbitals := function(group, perm)
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
        name := "InCosetWithOrbitals-BTKit",
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
                local fixedpoints, points, fixedps, fixedrbase, p, graphs, refinedgraphs;
                if buildingRBase then
                    fixedpoints := PS_FixedPoints(ps);
                    points := fillOrbits(fixedpoints, PS_Points(ps));
                    graphs := fillOrbitals(fixedpoints, PS_Points(ps));
                    Info(InfoBTKit, 5, "Building RBase:", points);
                    refinedgraphs := _BTKit.RefineGraphs(PS_Points(ps), ps, graphs);
                    return {x} -> [points[x], refinedgraphs[x]];
                else
                    fixedps := PS_FixedPoints(ps);
                    Info(InfoBTKit, 1, "fixed: ", fixedps);
                    fixedrbase := PS_FixedPoints(r!.RBase);
                    fixedrbase := fixedrbase{[1..Length(fixedps)]};
                    Info(InfoBTKit, 1, "Initial rbase: ", fixedrbase);

                    if perm <> () then
                        fixedps := OnTuples(fixedps, invperm);
                        Info(InfoBTKit, 1, "fixed coset: ", fixedrbase);
                    fi;

                    p := RepresentativeAction(group, fixedps, fixedrbase, OnTuples);
                    Info(InfoBTKit, 1, "Find mapping (InGroup):\n"
                         , "    fixed points:   ", fixedps, "\n"
                         , "    fixed by rbase: ", fixedrbase, "\n"
                         , "    map:            ", p);

                    if p = fail then
                        return fail;
                    fi;

                    points := pointMap[fixedrbase];
                    graphs := orbitalMap[fixedrbase];
                    if perm = () then
                        refinedgraphs := _BTKit.RefineGraphs(PS_Points(ps), ps, List(graphs, {g} -> OnDigraphs(g, p^-1)));
                        return {x} -> [points[x^p], refinedgraphs[x]];
                    else
                        Info(InfoBTKit, 5, fixedps, fixedrbase, List([1..PS_Points(ps)], i -> points[i^(p*invperm)]));
                        refinedgraphs := _BTKit.RefineGraphs(PS_Points(ps), ps, List(graphs, {g} -> OnDigraphs(g, (invperm*p)^-1)));
                        return {x} -> [points[x^(invperm*p)], refinedgraphs[x]];
                    fi;
                fi;
            end)
        );
        return Objectify(BTKitRefinerType, r);
    end;

BTKit_Refiner.InGroupWithOrbitals := {group} -> BTKit_Refiner.InCosetWithOrbitals(group, ());

# Check if permutations are even (i.e. a subgroup of the natural alternating group)
BTKit_Refiner.IsEven := {} -> Objectify(BTKitRefinerType, rec(
        name := "IsEven",
        largest_required_point := 1,
        constraint := Constraint.IsEven,
        refine := rec(
            initialise := function(ps, buildingRBase)
                return {x} -> 1;
            end)
    ));

# Check if the permutations are odd (i.e. the single coset of the natural symmetric group)
BTKit_Refiner.IsOdd := {} -> Objectify(BTKitRefinerType, rec(
        name := "IsOdd",
        # Somehow needs to store that it needs two or more points...
        largest_required_point := 1,
        constraint := Constraint.IsOdd,
        refine := rec(
            initialise := function(ps, buildingRBase)
                return {x} -> 0;
            end)
    ));

BTKit_Refiner.Nothing := {} -> Objectify(BTKitRefinerType, rec(
        name := "RefinerForNothing",
        largest_required_point := 1,
        constraint := Constraint.Nothing,
        refine := rec(
            initialise := ReturnFail
        )
    ));

BTKit_Refiner.Nothing2 := {} -> Objectify(BTKitRefinerType, rec(
        name := "RefinerForNothing2",
        largest_required_point := 1,
        constraint := Constraint.Nothing,
        refine := rec(
            initialise := function(ps, buildingRBase)
                return {x} -> 1;
            end,
            fixed := ReturnFail
        )
    ));

BTKit_Refiner.IdentityForTesting := function(depth)
    local r;
    r :=  rec(
        name := "Identity",
        largest_required_point := 1,
        image := {p} -> p,
        result := {} -> (),
        check := {p} -> p=(),
        constraint :=  Constraint.InGroup(Group(())),
        refine := rec(
            rBaseFinished := function(getRBase)
                r!.RBase := getRBase;
            end,

            initialise := function(ps, buildingRBase)
                return {x} -> 1;
            end,

        fixed := function(ps, buildingRBase)
            local fixedpoints, fixedrbase;

            fixedpoints := PS_FixedPoints(ps);
            if not buildingRBase then
                fixedrbase := PS_FixedPoints(r!.RBase){[1..Length(fixedpoints)]};
                if fixedpoints <> fixedrbase and Length(fixedpoints) >= depth then
                    return fail;
                fi;
            fi;
            return {x} -> 1;
        end
        )
    );
    return Objectify(BTKitRefinerType,r);
end;

# Imposes no constraint, just prints out messages whenever functions are called
_BTKit.ChattyRefiner := {} -> Objectify(BTKitRefinerType, rec(
        name := "ChattyRefiner",
        largest_required_point := 1,
        constraint := Constraint.Everything,
        refine := rec(
            initialise := function(ps, buildingRBase)
                Print("initialise:", PS_Cells(ps), "\n");
                return {x}->1;
            end,
            fixed := function(ps, buildingRBase)
                Print("fixed:", PS_Cells(ps), "\n");
                return {x}->1;
            end,
            changed := function(ps, buildingRBase)
                Print("changed:", PS_Cells(ps), "\n");
                return {x}->1;
            end,
            rBaseFinished := function(getRBase)
                Print("rBaseFinished\n");
            end,
            solutionFound := function(perm)
                Print("solutionFound:", perm,"\n");
            end
            )
    ));