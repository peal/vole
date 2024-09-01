InstallGlobalFunction( GB_SimpleSearch,
    {ps, conlist, conf...} -> _BTKit.SimpleSearch(_GB.BuildProblem(ps, conlist, conf)));

InstallGlobalFunction( GB_SimpleSinglePermSearch,
  function(ps, conlist, conf...)
    local ret;
    ret := _BTKit.SimpleSinglePermSearch(_GB.BuildProblem(ps, conlist, conf), true);
    if IsEmpty(ret) then
        return fail;
    else
        return ret[1];
    fi;
end);

InstallGlobalFunction( GB_SimpleAllPermSearch,
    {ps, conlist, conf...} -> _BTKit.SimpleSinglePermSearch(_GB.BuildProblem(ps, conlist, conf), false));

#! Build the initial graph stack, and return the automorphisms
#! of this graph stack. second argument is if this is the solution
#! (if not it will be a super-group of the solutions).
InstallGlobalFunction( GB_CheckInitialGroup,
    function(ps, conlist)
        local state, tracer, sols, saved, gens, ret;
        state := _GB.BuildProblem(ps, conlist,[]);
        tracer := RecordingTracer();
        saved := SaveState(state);
        InitialiseConstraints(state, tracer, true);

        sols := _GB.AutoAndCanonical(state!.ps, state!.graphs);
        gens := GeneratorsOfGroup(sols.grp);
        gens := List(gens, x -> PermList(ListPerm(x, PS_Points(state!.ps))));

        ret := ForAll(gens, p -> BTKit_CheckSolution(p, state!.conlist));

        RestoreState(state, saved);
        return rec(gens := gens, answer := ret);
end);


InstallGlobalFunction( GB_CheckInitialCoset,
    function(ps, conlist)
        local state, tracer, rbase, sols1, sols2, saved, autgraph1, autgraph2;
        state := _GB.BuildProblem(ps, conlist,[]);
        tracer := RecordingTracer();
        saved := SaveState(state);
        InitialiseConstraints(state, tracer, true);

        sols1 := _GB.AutoAndCanonical(state!.ps, state!.graphs);

        RestoreState(state, saved);

        rbase := BuildRBase(state, state!.config.cellSelector);
        FinaliseRBaseForConstraints(state, rbase);

        tracer := RecordingTracer();
        saved := SaveState(state);
        InitialiseConstraints(state, tracer, false);

        sols2 := _GB.AutoAndCanonical(state!.ps, state!.graphs);

        RestoreState(state, saved);

        autgraph1 := [OnDigraphs(sols1.graph[1], sols1.canonicalperm), List(sols1.graph[2], x -> OnSets(x, sols1.canonicalperm))];
        autgraph2 := [OnDigraphs(sols2.graph[1], sols2.canonicalperm), List(sols2.graph[2], x -> OnSets(x, sols2.canonicalperm))];
        return rec(graph1 := autgraph1, graph2 := autgraph2, equal := autgraph1 = autgraph2);
end);

# For read.g
_BTKit.ReadInterfaceGB := true;
