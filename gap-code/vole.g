LoadPackage("json");
LoadPackage("io");

IO_Pipe := function()
    local ret;
    ret := IO_pipe();
    ret.towriteRaw := ret.towrite;
    ret.toreadRaw := ret.toread;
    ret.towrite := IO_WrapFD(ret.towrite, false, IO.DefaultBufSize);
    ret.toread := IO_WrapFD(ret.toread, IO.DefaultBufSize, false);
    return ret;
end;


ExecuteVole := function(obj)
    local ret, rustpipe, gappipe,str, args;
    rustpipe := IO_Pipe();
    gappipe := IO_Pipe();
    Print("PreFork\n");
    ret := IO_fork();
    if ret = fail then
        Error("Fork failed");
    fi;
    Print("PostFork\n");
    if ret = 0 then
        # In the child
        IO_Close(rustpipe.towrite);
        IO_Close(gappipe.toread);
        Print("C: In child\n");
        args := ["echo", "hello", "world"];
        args :=  ["run", "-p", "vole", "--", "--inpipe", String(rustpipe.toreadRaw), "--outpipe", String(gappipe.towriteRaw)];
        Print("C:", args,"\n");
        IO_execvp("cargo", args);
        Print("Fatal error");
        QUIT_GAP();
    else
        # In the parent
        Print("P: In parent");
        IO_Close(rustpipe.toread);
        IO_Close(gappipe.towrite);
        IO_WriteLine(rustpipe.towrite, GapToJsonString(obj));
        IO_Flush(rustpipe.towrite);
        Print("Reading..\n");
        str := IO_ReadLine(gappipe.toread);
        Print("Read: '",str,"'\n");
        Print("P: Read:",JsonStringToGap(str),":\n");
        IO_Close(rustpipe.towrite);
        IO_Close(gappipe.toread);
        return JsonStringToGap(str);
    fi;
end;

Solve := function(points, findgens, constraints)
    return ExecuteVole(rec(config := rec(points := points, findgens := findgens),
                constraints := constraints,
                debug := true));
end;

Solve(5, true, []);