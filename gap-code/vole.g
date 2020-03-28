LoadPackage("json");
LoadPackage("io");

IO_Pipe := function()
    local ret;
    ret := IO_pipe();
    ret.towrite := IO_WrapFD(ret.towrite, false, IO.DefaultBufSize);
    ret.toread := IO_WrapFD(ret.toread, IO.DefaultBufSize, false);
    return ret;
end;

ExecuteVole := function(obj)
    local ret, rustpipe, gappipe,str;
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
        str := IO_ReadLine(rustpipe.toread);
        Print("C: Read :",JsonStringToGap(str),":\n");
        IO_WriteLine(gappipe.towrite, "\"Reply\"");
        QUIT_GAP();
    else
        # In the parent
        Print("P: In parent");
        IO_Close(rustpipe.toread);
        IO_Close(gappipe.towrite);
        IO_WriteLine(rustpipe.towrite, GapToJsonString(obj));
        str := IO_ReadLine(gappipe.toread);
        Print("P: Read:",JsonStringToGap(str),":\n");
        IO_Close(rustpipe.towrite);
        IO_Close(gappipe.toread);
        return JsonStringToGap(str);
    fi;
end;