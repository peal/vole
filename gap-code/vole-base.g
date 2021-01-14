LoadPackage("json", false);
LoadPackage("io", false);
LoadPackage("digraphs", false);

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


ExecuteVole := function(obj, callbacks)
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
                result := CallFuncList(callbacks[2], callbacks{[3..Length(callbacks)]});
                Info(InfoVole, 2, "Refiner returned: ", result);
                IO_WriteLine(rustpipe.towrite, GapToJsonString(result)); 
            else
                ErrorNoReturn("Invalid return value from Vole: ", result);
            fi;
        od;
    fi;
end;

Solve := function(points, findgens, constraints)
    local ret;
    ret := ExecuteVole(rec(config := rec(points := points, findgens := findgens),
                constraints := constraints,
                debug := true), []);
    return rec(raw := ret, group := Group(List(ret.sols, PermList)));
end;

con := rec(
    SetStab := {s} -> rec(SetStab := rec(points := s)),
    TupleStab := {s} -> rec(TupleStab := rec(points := s)),
    DigraphStab := {e} -> rec(DigraphStab := rec(edges := e))
);

GAPSolve := function(p, gens, l)
    local c, g;
    g := SymmetricGroup(p);
    for c in l do
        if IsBound(c.SetStab) then
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
    ret1 := Solve(p, true, c);
    ret2 := GAPSolve(p, true, c);
    if ret2 <> ret1.group then
        Error("\nError!!",p,c,ret1,ret2,"!!\n");
    fi;
end;
