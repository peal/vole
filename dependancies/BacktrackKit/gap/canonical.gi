BTKit_GetCandidateCanonicalSolution := function(state, group)
    local preimage, postimage, image, i, ps, perm;
    ps := state!.ps;
    # When this is called, the current partition state of ps should be discrete.
    # The candidate solution is the perm that, for each i, maps the value in
    # cell i of the discrete partition of the RBase to the value in cell i of
    # the current (discrete) partition state of ps.
    preimage := List([1..PS_Points(ps)], {x} -> PS_CellSlice(ps,x)[1]);
    if group = false then
        postimage := [1..PS_Points(ps)];
    else
        postimage := MinimalImage(group, preimage, OnTuples);
    fi;

    image := [];
    for i in [1..PS_Points(ps)] do
        image[preimage[i]] := postimage[i];
    od;
    perm := PermList(image);

    Assert(2, group = false or perm in group);

    Info(InfoBTKit, 2, "Considering mapping: ", preimage, postimage, perm);
    return rec(perm := perm, image := List(state!.conlist, {x} -> ImageFunc(x!.constraint)(perm)));
    # TODO: Huh? I don't get why we are taking the image w.r.t. the GROUP!
end;

InstallGlobalFunction( CanonicalBacktrack,
    function(state, canonicaltraces, depth, canonical, branchselector, group)
    local p, found, saved, vals, branchCell, branchPos, v, tracer;

    Info(InfoBTKit, 2, "Partition: ", PS_AsPartition(state!.ps));

    if PS_Fixed(state!.ps) then
        p := BTKit_GetCandidateCanonicalSolution(state, group);
        Info(InfoBTKit, 2, "Maybe canonical solution? ", p);
        if not IsBound(canonical.image) or p.image < canonical.image then
            canonical.image := p.image;
            canonical.perms := [p.perm];
            Info(InfoBTKit, 2, "New best!");
        elif IsBound(canonical.image) and p.image = canonical.image then
            Add(canonical.perms, p.perm);
            Info(InfoBTKit, 2, "Equal");
        else
            Info(InfoBTKit, 2, "Beaten");
        fi;
        return false;
    fi;

    branchCell := branchselector(state!.ps);
    branchPos := Minimum(PS_CellSlice(state!.ps, branchCell));

    # <vals> is the cell of the current state with index <branchInfo.cell>. We
    # branch by splitting the search space up into those permutations that map
    # <branchInfo.branchPos> to <v>, for each <v> in <vals>.
    vals := Set(PS_CellSlice(state!.ps, branchCell));
    Info(InfoBTKit, 1,
         StringFormatted("Branching at depth {}: {}", depth, branchCell));
    Print("\>");


    for v in vals do
        Info(InfoBTKit, 2, StringFormatted("Branch: {}", v));
        if IsBound(canonicaltraces[depth]) then
            Info(InfoBTKit, 3, "Reusing previous trace at depth ", depth, " : ", GetEvents(canonicaltraces[depth]));
            tracer := CanonicalisingTracerFromTracer(canonicaltraces[depth]);
        else
            Info(InfoBTKit, 3, "Using new trace for depth ", depth);
            tracer := EmptyCanonicalisingTracer();
        fi;
        found := false;

        if not BTKit_Stats_AddNode() then
            return false;
        fi;

        # Split off point <v>, and then continue the backtrack search.
        saved := SaveState(state);

        if PS_SplitCellByFunction(state!.ps, tracer, branchCell, {x} -> x = v)
           and RefineConstraints(state, tracer, false) then
                if tracer!.improvedTrace = true then
                    # We improved the canonical image!
                    Info(InfoBTKit, 2, "Found new best trace, clearing old stuff");
                    canonicaltraces[depth] := tracer;
                    canonicaltraces := canonicaltraces{[1..depth]};
                    Unbind(canonical.image);
                    canonical.perms := [];
                fi;
                if CanonicalBacktrack(state, canonicaltraces, depth + 1, canonical, branchselector, group) then
                    found := true;
                fi;
        fi;
        RestoreState(state, saved);
    od;
    Print("\<");
    return false;
end);


_BTKit.SimpleCanonicalSearch :=
    function(state, group)
        local canonical, tracer;
        canonical := rec(perms := []);
        BTKit_ResetStats();

        tracer := EmptyCanonicalisingTracer();
        FirstFixedPoint(state, tracer, false);

        CanonicalBacktrack(state, [], 1, canonical, state!.config.cellSelector, group);
        return canonical;
    end;


BTKit_SimpleCanonicalSearch :=
    function(ps, conlist, conf...)
        local ret;
        ret := _BTKit.SimpleCanonicalSearch(_BTKit.BuildProblem(ps, conlist, conf), false);
        return ret;
end;


BTKit_SimpleCanonicalSearchInGroup :=
    function(ps, conlist, group, conf...)
        local ret;
        ret := _BTKit.SimpleCanonicalSearch(_BTKit.BuildProblem(ps, Concatenation(conlist, [BTKit_Refiner.InGroupSimple(group)]), conf), group);
        # Remove extra group we added
        Remove(ret.image);
        return ret;
end;

# Used in read.g
_BTKit.CheckReadg := true;