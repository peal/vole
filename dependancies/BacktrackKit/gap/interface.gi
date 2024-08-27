_BTKit.BuildProblem :=
   {ps, conlist, conf} -> Objectify(BTKitStateType, rec(ps := ps, conlist := conlist,
                            config := _BTKit.FillConfig(conf, _BTKit.DefaultConfig)));

_BTKit.SimpleSearch :=
  function(state)
        local rbase, perms, saved, tracer;

        BTKit_ResetStats();

        saved := SaveState(state);
        rbase := BuildRBase(state, state!.config.cellSelector);

        FinaliseRBaseForConstraints(state, rbase);
        perms := [ Group(()), [] ];

        tracer := FollowingTracer(rbase.root.tracer);
        if FirstFixedPoint(state, tracer, false) then
            Backtrack(state, rbase, 1, perms, true, false, true);
        fi;
        RestoreState(state, saved);
        return perms[1];
end;

InstallGlobalFunction( BTKit_SimpleSearch,
    {ps, conlist, conf...} -> _BTKit.SimpleSearch(_BTKit.BuildProblem(ps, conlist, conf)));


_BTKit.SimpleSinglePermSearch :=
    function(state, find_single)
        local rbase, perms, saved, tracer;

        BTKit_ResetStats();

        saved := SaveState(state);
        rbase := BuildRBase(state, state!.config.cellSelector);
        FinaliseRBaseForConstraints(state, rbase);
        perms := [ Group(()), [] ];

        tracer := FollowingTracer(rbase.root.tracer);
        if FirstFixedPoint(state, tracer, false) then
            Backtrack(state, rbase, 1, perms, true, find_single, false);
        fi;

        RestoreState(state, saved);

        return perms[2];
end;

InstallGlobalFunction( BTKit_SimpleSinglePermSearch,
    function(ps, conlist, conf...)
    local ret;
    ret := _BTKit.SimpleSinglePermSearch(_BTKit.BuildProblem(ps, conlist, conf), true);
    if IsEmpty(ret) then
        return fail;
    else
        return ret[1];
    fi;
end);

InstallGlobalFunction( BTKit_SimpleAllPermSearch,
    {ps, conlist, conf...} -> _BTKit.SimpleSearch(_BTKit.BuildProblem(ps, conlist, conf)));



# Used in read.g
_BTKit.CheckReadgInterface := true;