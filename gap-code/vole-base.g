LoadPackage("json", false);
LoadPackage("io", false);
LoadPackage("digraphs", false);
LoadPackage("GraphBacktracking", false);

# Simple high level wrapper around IO_pipe -- this could be moved to IO.
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

#####################################################################################################
# Wrapper around GraphBacktracking, allowing a refiner to be queried
# First argument should be a GraphBacktrack state, second argument is operation, final argument is
# input to the operations.
# Valid operations are:
#   "name": Return name of refiner
#   "is_group": Does this refiner represent a group (as opposed to a coset)
#   "check": Check if a permutation satisfies the refiner (given as a 0-indexed list)
#   "begin" or "refine": Run the refiner. "begin" reuns the 'initialise' function, 'refine' runs the 'changed' function.
#     Here, args is:
#     args[1]: "Left" or "Right", for if refiner is being run in 'Left' or 'Right' mode.
#     args[2]: Current state of partition (where values in the same cell have the same value)
CallRefiner := function(state, type, args)
    local saved, tracer, is_left, indicator, c, i, retval, filters;
    if type = "name" then
        return state!.conlist[1]!.name;
    elif type = "is_group" then
        return BTKit_CheckPermutation((), state!.conlist[1]);
    elif type = "check" then
        Info(InfoVole, 2, "Checking ", args[1]);
        return BTKit_CheckPermutation(PermList(List(args[1].values, x -> x+1)), state!.conlist[1]);
    else
        Assert(2, args[1] = "Left" or args[1] = "Right");
        is_left := (args[1] = "Left");
        saved := SaveState(state);
        tracer := RecordingTracer();
        PS_SplitCellsByFunction(state!.ps, tracer, x -> args[2][x]);
        
        Assert(2, Length(state!.conlist) = 1);
        filters := [];
        if type = "begin" then
            if IsBound(state!.conlist[1]!.refine.initialise) then
                filters := state!.conlist[1]!.refine.initialise(state!.ps, is_left);
            fi;
        else
            if IsBound(state!.conlist[1]!.refine.changed) then
                filters := state!.conlist[1]!.refine.changed(state!.ps, is_left);
            fi;
        fi;

        if not IsList(filters) then
            filters := [filters];
        fi;

        for i in [1..Length(filters)] do
            if IsFunction(filters[i]) then
                # Call these 'vertlabels' just for consistency, to make it easier to read in GAP
                filters[i] := rec(vertlabels := List([1..PS_Points(state!.ps)], {x} -> HashBasic(filters[i](x))));
            else
                if IsBound(filters[i].graph) then
                    filters[i].graph := OutNeighbours(filters[i].graph);
                fi;
                if IsBound(filters[i].vertlabels) then
                    filters[i].vertlabels := List([1..Length(filters[i].graph)], {x} -> HashBasic(filters[i].vertlabels(x)));
                fi;
            fi;
        od;

        retval := filters;
        RestoreState(state, saved);
        return retval;
    fi; 
end;

# Choose how vole is run:
# "opt": Run as optimised as possible
# "trace": Output a trace in "trace.log"
# "flamegraph": Output a flamegraph of where CPU is used in "flamegraph.svg"
VOLE_MODE := "opt";

# Run vole
# obj contains the problem to run. 'refiners' is an optional list of GraphBacktracking refiners, which vole can "call back"
# and query
ExecuteVole := function(obj, refiners)
    local ret, rustpipe, gappipe,str, args, result, prog;
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
        prog := "cargo";
        if VOLE_MODE = "trace" then
            args :=  ["run", "--release", "-q", "--bin", "vole", "--", "--trace", "--inpipe", String(rustpipe.toreadRaw), "--outpipe", String(gappipe.towriteRaw)];
        elif VOLE_MODE = "opt" then
            args :=  ["run", "--release", "-q", "--bin", "vole", "--", "--inpipe", String(rustpipe.toreadRaw), "--outpipe", String(gappipe.towriteRaw)];
        elif VOLE_MODE = "flamegraph" then
            args :=  ["flamegraph", "--bin", "vole", "--", "--inpipe", String(rustpipe.toreadRaw), "--outpipe", String(gappipe.towriteRaw)];
        elif VOLE_MODE = "valgrind" then
            args := ["--tool=callgrind", "target/debug/vole", "--inpipe", String(rustpipe.toreadRaw), "--outpipe", String(gappipe.towriteRaw)];
            prog := "valgrind";
        else
            Error("Invalid VOLE_MODE");
        fi;
        Info(InfoVole, 2, "C:", args,"\n");
        IO_execvp(prog, args);
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

# The list of constraints which vole understands (not including GraphBacktracking refiners)
con := rec(
    SetStab := {s} -> rec(SetStab := rec(points := s)),
    SetTransport := {s,t} -> rec(SetTransport := rec(left_points := s, right_points := t)),
    TupleStab := {s} -> rec(TupleStab := rec(points := s)),
    TupleTransport := {s,t} -> rec(TupleTransport :=  rec(left_points := s, right_points := t)),
    DigraphStab := {e} -> rec(DigraphStab := rec(edges := e)),
    DigraphTransport := {e,f} -> rec(DigraphStab := rec(left_edges := e, right_edges := f))
);


# Solve a problem using vole
# 'points': Search will be done in the set [1..points]
# 'find_single': Find a single solution (equivalent to 'this is a coset problem')
# 'constraints': List of constraints to solve
VoleSolve := function(points, find_single, constraints)
    local ret, gapcons,i;
    gapcons := [];
    constraints := ShallowCopy(constraints);
    for i in [1..Length(constraints)] do
        if IsRefiner(constraints[i]) then
            gapcons[i] := _GB.BuildProblem(PartitionStack(points), [constraints[i]], []);
            constraints[i] := rec(GapRefiner := rec(gap_id := i));
        fi;
    od;

    ret := ExecuteVole(rec(config := rec(points := points, find_single := find_single),
                constraints := constraints), gapcons);
    if find_single then
        return rec(raw := ret, sol := List(ret.sols, PermList));
    else
        return rec(raw := ret, group := Group(List(ret.sols, PermList)));
    fi;
end;


# Simple GAP wrapper which implements the same interface as VoleSolve, for problems
# which return a group
GAPSolve := function(p, l)
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
            if g = SymmetricGroup(p) then
                g := AutomorphismGroup(Digraph(c.DigraphStab.edges));
            else
                g := Intersection(g, AutomorphismGroup(Digraph(c.DigraphStab.edges)));
            fi;
        else
            Error("Unknown Constraint", g);
        fi;
    od;
    return g;
end;

# Check (and simply benchmark) that VoleSolve(p,false,c) and GAPSolve(p,c) produce the
# same answer
Comp := function(p,c)
    local ret1,ret2, time1, time2;
    time1 := NanosecondsSinceEpoch();
    ret1 := VoleSolve(p, false, c);
    time1 := NanosecondsSinceEpoch() - time1;
    time2 := NanosecondsSinceEpoch();
    ret2 := GAPSolve(p, c);
    time2 := NanosecondsSinceEpoch() - time2;
    if ret2 <> ret1.group then
        Error("\nError!!","\n",p,"\n",c,"\n",ret1,"\n",ret2,"!!\n");
    fi;
    return rec(voletime := time1, gaptime := time2);
end;

