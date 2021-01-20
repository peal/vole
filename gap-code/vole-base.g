LoadPackage("json", false);
LoadPackage("io", false);
LoadPackage("digraphs", false);
LoadPackage("GraphBacktracking", false);

IO_Pipe := function()
    local ret;
    ret := IO_pipe();
    ret.towriteRaw := ret.towrite;
    ret.toreadRaw := ret.toread;
    ret.towrite := IO_WrapFD(ret.towrite, false, IO.DefaultBufSize);
    ret.toread := IO_WrapFD(ret.toread, IO.DefaultBufSize, false);
    return ret;
end;

if not IsBound(InfoVole) then
    InfoVole := NewInfoClass("InfoVole");
fi;

CallRefiner := function(state, type, args)
    local saved, tracer, is_left, indicator, c, i, retval;
    if type = "name" then
        return state!.conlist[1]!.name;
    elif type = "is_group" then
        return BTKit_CheckPermutation((), state!.conlist[1]);
    elif type = "check" then
        Info(InfoVole, 2, "Checking ", args[1]);
        return BTKit_CheckPermutation(PermList(List(args[1].values, x -> x+1)), state!.conlist[1]);
    else
        is_left := (args[1] = "left");
        saved := SaveState(state);
        tracer := RecordingTracer();
        PS_SplitCellsByFunction(state!.ps, tracer, x -> args[2][x]);
        if type = "begin" then
            InitialiseConstraints(state, tracer, is_left);
        else
            RefineConstraints(state, tracer, is_left);
        fi;
        indicator := [];
        for c in [1..PS_Cells(state!.ps)] do
            for i in PS_CellSlice(state!.ps, c) do
                indicator[i] := c;
            od;
        od;
        retval := rec(partition := indicator, digraphs := state!.graphs);
        RestoreState(state, saved);
        return retval;
    fi; 
end;


ExecuteVole := function(obj, refiners)
    local ret, rustpipe, gappipe,str, args, result;
    rustpipe := IO_Pipe();
    gappipe := IO_Pipe();
    Info(InfoVole, 2, "PreFork\n");
    ret := IO_fork();
    if ret = fail then
        Error("Fork failed");
    fi;
    Info(InfoVole, 2, "PostFork\n");
    if ret = 0 then
        # In the child
        IO_Close(rustpipe.towrite);
        IO_Close(gappipe.toread);
        Info(InfoVole, 2, "C: In child\n");
        args := ["echo", "hello", "world"];
        args :=  ["run", "-q", "--bin", "vole", "--", "--inpipe", String(rustpipe.toreadRaw), "--outpipe", String(gappipe.towriteRaw)];
        Info(InfoVole, 2, "C:", args,"\n");
        IO_execvp("cargo", args);
        Info(InfoVole, 2, "Fatal error");
        QUIT_GAP();
    else
        # In the parent
        Info(InfoVole, 2, "P: In parent");
        IO_Close(rustpipe.toread);
        IO_Close(gappipe.towrite);
        Info(InfoVole, 4, "Sending", GapToJsonString(obj));
        IO_WriteLine(rustpipe.towrite, GapToJsonString(obj));
        IO_Flush(rustpipe.towrite);
        while true do
            Info(InfoVole, 2, "Reading..\n");
            str := IO_ReadLine(gappipe.toread);
            Info(InfoVole, 2, "Read: '",str,"'\n");
            result := JsonStringToGap(str);
            if result[1] = "end" then
                IO_Close(rustpipe.towrite);
                IO_Close(gappipe.toread);
                return result[2];
            elif result[1] = "refiner" then
                result := CallRefiner(refiners[result[2]], result[3], result{[4..Length(result)]});
                Info(InfoVole, 2, "Refiner returned: ", result);
                IO_WriteLine(rustpipe.towrite, GapToJsonString(result)); 
            else
                ErrorNoReturn("Invalid return value from Vole: ", result);
            fi;
        od;
    fi;
end;

VoleSolve := function(points, findgens, constraints)
    local ret, gapcons,i;
    gapcons := [];
    constraints := ShallowCopy(constraints);
    for i in [1..Length(constraints)] do
        if IsRefiner(constraints[i]) then
            gapcons[i] := _GB.BuildProblem(PartitionStack(points), [constraints[i]], []);
            constraints[i] := rec(GapRefiner := rec(gap_id := i));
        fi;
    od;

    ret := ExecuteVole(rec(config := rec(points := points, findgens := findgens),
                constraints := constraints,
                debug := true), gapcons);
    return rec(raw := ret, group := Group(List(ret.sols, PermList)));
end;

con := rec(
    SetStab := {s} -> rec(SetStab := rec(points := s)),
    TupleStab := {s} -> rec(TupleStab := rec(points := s)),
    DigraphStab := {e} -> rec(DigraphStab := rec(edges := e))
);

GAPSolve := function(p, gens, l)
    local c, g, lmp;
    g := SymmetricGroup(p);
    for c in l do
        if IsRefiner(c) then
            g := GB_SimpleSearch(PartitionStack(p), [GB_Con.InGroup(p, g), c]);
        elif IsBound(c.SetStab) then
            g := Stabilizer(g, c.SetStab.points, OnSets);
        elif IsBound(c.TupleStab) then
            g := Stabilizer(g, c.TupleStab.points, OnTuples);
        elif IsBound(c.DigraphStab) then
            g := Intersection(g, AutomorphismGroup(Digraph(c.DigraphStab.edges)));
        else
            Error("Unknown Constraint", g);
        fi;
    od;
    return g;
end;


Comp := function(p,c)
    local ret1,ret2;
    ret1 := VoleSolve(p, true, c);
    ret2 := GAPSolve(p, true, c);
    if ret2 <> ret1.group then
        Error("\nError!!","\n",p,"\n",c,"\n",ret1,"\n",ret2,"!!\n");
    fi;
end;
