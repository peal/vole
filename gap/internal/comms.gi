# Vole: Backtrack search in permutation groups with graphs
# A GAP package by Mun See Chang, Christopher Jefferson, and Wilf A. Wilson.
#
# SPDX-License-Identifier: MPL-2.0
#
# Implementations: All code to call Vole from GAP (and GAP from Vole)


# Simple high level wrapper around IO_pipe -- could be moved to the IO package.
_Vole.IO_Pipe :=
function()
    local ret;
    ret := IO_pipe();
    ret.towriteRaw := ret.towrite;
    ret.toreadRaw := ret.toread;
    ret.towrite := IO_WrapFD(ret.towrite, false, IO.DefaultBufSize);
    ret.toread := IO_WrapFD(ret.toread, IO.DefaultBufSize, false);
    return ret;
end;

_Vole.TCP_Pipe :=
function()
    local s, made_connection, attempts, port;
    s := IO_socket(IO.PF_INET,IO.SOCK_STREAM,"tcp");
    made_connection := fail;
    attempts := 0;
    while attempts < 1000 and made_connection = fail do
        port := Random([20000..30000]);
        made_connection := IO_bind(s,IO_MakeIPAddressPort("127.0.0.1",port));
    od;
    if made_connection = fail then
        Error("Failed to open a TCP socket to communicate with vole");
    fi;
    return rec( socket := s, port := port);
end;


#####################################################################################################
# Wrapper around GraphBacktracking, allowing a refiner to be queried
# First argument should be a GraphBacktracking state, second argument is
# operation, final argument is input to the operations.
# Valid operations are:
#   "name": Return name of refiner
#   "is_group": Does this refiner represent a group (as opposed to a coset)
#   "check": Check if a permutation satisfies the refiner (given as a 0-indexed list)
#   "begin" or "refine": Run the refiner. "begin" runs the 'initialise' function, 'refine' runs the 'changed' function.
#     Here, args is:
#     args[1]: "Left" or "Right", for if refiner is being run in 'Left' or 'Right' mode.
#     args[2]: Current state of partition (where values in the same cell have the same value)
# FIXME What is savedvals?
_Vole.CallRefiner :=
function(savedvals, state, type, args)
    local saved, tracer, is_left, indicator, c, i, retval, filters, val;
    if type = "name" then
        return state!.conlist[1]!.name;
    elif type = "is_group" then
        return BTKit_CheckPermutation((), state!.conlist[1]);
    elif type = "check" then
        Info(InfoVole,2, "Checking ", args[1]);
        return BTKit_CheckPermutation(PermList(List(args[1].values, x -> x+1)), state!.conlist[1]);
    elif type = "solutionFound" then
        Info(InfoVole, 2, "Informing refiner that solution has been found");
        if IsBound(state!.conlist[1]!.refine.solutionFound) then
            state!.conlist[1]!.refine.solutionFound(PermList(List(args[1].values, x -> x+1)));
        fi;
        return true;
    elif type = "image" then
        Info(InfoVole, 2, "Generating image", args[1]);
        Assert(2, args[1] in ["Left", "Right"]);
        if args[1] = "Left" then
            val := ImageFunc(state!.conlist[1]!.constraint)(PermList(List(args[2].values, x -> x+1)));
        else
            Assert(2, args[2].values = []);
            val := ResultObject(state!.conlist[1]!.constraint);
        fi;
        savedvals.map[savedvals.count] := val;
        Info(InfoVole, 2, "Saving: ", val , " as ", savedvals.count);
        retval := rec(id := savedvals.count);
        savedvals.count := savedvals.count + 1;
        return retval;
    elif type = "compare" then
        Info(InfoVole, 2, "Comparing", args[1], args[2], savedvals.map[args[1].id], savedvals.map[args[2].id]);
        if savedvals.map[args[1].id] < savedvals.map[args[2].id] then
            return -1;
        elif savedvals.map[args[1].id] = savedvals.map[args[2].id] then
            return 0;
        else
            return 1;
        fi;
    elif type = "save_state" then
        Add(state!.saved_stack, SaveState(state));
        return true;
    elif type = "restore_state" then
        RestoreState(state, Remove(state!.saved_stack));
        return true;
    else
        Assert(2, type in ["begin", "fixed", "changed", "rBaseFinished", "solutionFound"]);
        Assert(2, args[1] = "Left" or args[1] = "Right");
        is_left := (args[1] = "Left");
        tracer := RecordingTracer();
        PS_SplitCellsByFunction(state!.ps, tracer, x -> args[2][x]);
        
        Assert(2, Length(state!.conlist) = 1);
        filters := [];
        if type = "begin" then
            if IsBound(state!.conlist[1]!.refine.initialise) then
                filters := state!.conlist[1]!.refine.initialise(state!.ps, is_left);
            fi;
        elif type = "fixed" then
            if IsBound(state!.conlist[1]!.refine.fixed) then
                filters := state!.conlist[1]!.refine.fixed(state!.ps, is_left);
            fi;
        elif type = "rBaseFinished" then
            if IsBound(state!.conlist[1]!.refine.rBaseFinished) then
                # No return value
                # The call to 'Immutable' creates a copy
                state!.conlist[1]!.refine.rBaseFinished(Immutable(state!.ps));
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
            # Can't convert 'fail' to JSON. Make an object we can clearly identify later
            if filters[i] = fail then
                filters[i] := rec(failed := true);
            elif IsFunction(filters[i]) then
                # Call these 'vertlabels' just for consistency, to make it easier to read in GAP
                filters[i] := rec(vertlabels := List([1..PS_Points(state!.ps)], {x} -> HashBasic(filters[i](x))));
            else
                if IsBound(filters[i].graph) then
                    filters[i].graph := OutNeighbours(filters[i].graph);
                fi;
            fi;
        od;

        retval := filters;
        return retval;
    fi; 
end;

# Choose how vole is run:
# "opt-first": Run as optimised as possible, rebuild on first use in any GAP session
# "opt-nobuild": Run as optimised as possible, do not build the executable
# "opt": Run as optimised as possible
# "trace": Output a trace in "trace.log"
# "flamegraph": Output a flamegraph of where CPU is used in "flamegraph.svg"
# "debug": Run inside the debugger

# if 'cargo' exists, we will automatically build vole
if Filename(DirectoriesSystemPrograms(), "cargo") <> fail then
    VOLE_MODE := "opt-first";
else
    VOLE_MODE := "opt-nobuild";
fi;

# On Cygwin we need to use TCP rather than pipes
if PositionSublist(GAPInfo.Architecture, "cygwin") <> fail then
    _Vole.UsePipe := false;
else
    _Vole.UsePipe := true;
fi;

_Vole.ForkVole := function(extraargs...)
    local rustpipe, gappipe, bind, args, ret, prog, firsttime, t, f, pipe, dirs, child;
    firsttime := false;
    if VOLE_MODE = "opt-first" then
        firsttime := true;
        VOLE_MODE := "opt-nobuild";
        dirs := DirectoriesPackageLibrary("vole", "rust/target/release");
        if not (Length(dirs) >= 1 and ForAny(["vole", "vole.exe"], f -> f in DirectoryContents(dirs[1])) ) then
            Info(InfoVole, 1, "Vole executable missing -- trying to build (please wait)");
        fi;
    fi;

    pipe := _Vole.UsePipe;

    # Prepare program we will run
    prog := "cargo";

    if VOLE_MODE = "opt" or firsttime then
        args :=  ["run", "--release", "-q", "--bin", "vole", "--", "--quiet"];
    elif VOLE_MODE = "opt-nobuild" then
        dirs := DirectoriesPackageLibrary("vole", "rust/target/release");
        # Check for windows-style executable
        if Length(dirs) >= 1 and "vole.exe" in DirectoryContents(dirs[1]) then
            prog := "target/release/vole.exe";
        elif Length(dirs) >= 1 and  "vole" in DirectoryContents(dirs[1]) then
            prog := "target/release/vole";
        else
            ErrorNoReturn("'vole' external program not built");
        fi;
        args :=  [];
    elif VOLE_MODE = "trace" then
        args :=  ["run",  "-q", "--bin", "vole", "--", "--trace", ];
    elif VOLE_MODE = "flamegraph" then
        args :=  ["flamegraph", "--bin", "vole", "--"];
    elif VOLE_MODE = "valgrind" then
        args := ["--tool=callgrind", "target/release/vole"];
        prog := "valgrind";
    elif VOLE_MODE = "debug" then
        args :=  ["with", "rust-gdb --args {bin} {args}", "--", "run" ,"--bin", "vole" ,"--", "--trace"];
    else
        Error("Invalid VOLE_MODE");
    fi;

    Append(args, extraargs);
    
    Info(InfoVole, 2, "Preparing to fork vole");
    if pipe then
        rustpipe :=_Vole.IO_Pipe();
        gappipe :=_Vole.IO_Pipe();
    else
        bind := _Vole.TCP_Pipe();
        IO_listen(bind.socket, 1);
    fi;

    if pipe then
        Append(args, [ "--inpipe", String(rustpipe.toreadRaw), "--outpipe", String(gappipe.towriteRaw)]);
    else
        Append(args, [ "--port", String(bind.port)]);
    fi;

    Info(InfoVole, 2, "PreFork\n");


    if pipe then
        ret := IO_fork();
        if ret = fail then
            Error("Fork failed");
        fi;
        Info(InfoVole, 2, "PostFork\n");
        if ret = 0 then
            # In the child
            Info(InfoVole, 2, "C: In child\n");
            IO_Close(rustpipe.towrite);
            IO_Close(gappipe.toread);

            Info(InfoVole, 2, "C:", args,"\n");
            ChangeDirectoryCurrent(DirectoriesPackageLibrary("vole", "rust")[1]![1]);

            IO_execvp(prog, args);
            if prog = "cargo" then
                Print("#I Vole: Fatal Error - 'cargo' is not installed\n");
            else
                Print("#I Vole: Fatal Error - Package has not been built\n");
            fi;
            ForceQuitGap();
        fi;
    else
        child := InputOutputLocalProcess(DirectoriesPackageLibrary("vole", "rust"[1]![1]),
                                         prog, args);
    fi;

    # In the parent / original GAP
    Info(InfoVole, 2, "P: In parent / original GAP");
    if pipe then
        IO_Close(rustpipe.toread);
        IO_Close(gappipe.towrite);
        return rec(write := rustpipe.towrite, read := gappipe.toread, pid := ret);
    else
        t := IO_accept(bind.socket, IO_MakeIPAddressPort("127.0.0.1", 0));
        f := IO_WrapFD(t,IO.DefaultBufSize,IO.DefaultBufSize);
        return rec(write := f, read := f, child := child, socket := bind.socket, port := bind.port);
    fi;
end;

# Run vole
# obj contains the problem to run. 'refiners' is an optional list of GraphBacktracking refiners, which vole can "call back"
# and query
_Vole.ExecuteVole := function(obj, refiners, canonicalgroup)
    local pipe,str, st, result, preimage, postimage, gapcallbacks, savedvals, flush, time, pwd;
    gapcallbacks := rec(name := 0, is_group := 0, check := 0, begin := 0,
      fixed := 0, changed := 0, rBaseFinished := 0, solutionFound := 0, image := 0,
      compare := 0, refiner_time := 0, canonicalmin_time := 0,
      save_state := 0, restore_state := 0);

    pipe := _Vole.ForkVole();

    # Set up cache
    savedvals := rec(map := HashMap(), count := 1);

    Info(InfoVole, 4, "Sending", GapToJsonString(obj));
    IO_WriteLine(pipe.write, GapToJsonString(obj));
    IO_Flush(pipe.write);
    while true do
        Info(InfoVole, 2, "Reading..\n");
        str := IO_ReadLine(pipe.read);
        Info(InfoVole, 2, "Read: '",str,"'\n");
        if IsEmpty(str) then
            ErrorNoReturn("No return value from 'vole'");
        fi;
        result := JsonStringToGap(str);
        if result[1] = "end" then
            # This is just here to make sure we have read all output from Vole before it closes
            IO_WriteLine(pipe.write, "goodbye");
            IO_Flush(pipe.write);
            if _Vole.UsePipe then
                IO_Close(pipe.write);
                IO_Close(pipe.read);
            else
                # read + write the same when using TCP
                IO_Close(pipe.read);
                IO_close(pipe.socket);
            fi;

            if IsBound(pipe.pid) then
                IO_WaitPid(pipe.pid, true);
            else
                CloseStream(pipe.child);
            fi;
            result[2].stats.gap_callbacks := gapcallbacks;
            return result[2];
        elif result[1] = "error" then
            # This is just here to make sure we have read all output from Vole before it closes
            IO_WriteLine(pipe.write, "goodbye");
            IO_Flush(pipe.write);
            if _Vole.UsePipe then
                IO_Close(pipe.write);
                IO_Close(pipe.read);
            else
                # read + write the same when using TCP
                IO_Close(pipe.read);
                IO_close(pipe.socket);
            fi;
            ErrorNoReturn("There was a fatal error in vole: ", result[2]);
        elif result[1] = "canonicalmin" then
            time := NanosecondsSinceEpoch();
            if canonicalgroup = false then
                IO_WriteLine(pipe.write, GapToJsonString([1..Length(result[2])]));
            else
                st := StabTreeStabilizer(canonicalgroup, result[2]);
                postimage := st.minimage;
                Assert(2, MinimalImage(canonicalgroup, result[2], OnTuples) = postimage);
                IO_WriteLine(pipe.write, GapToJsonString(postimage));
            fi;
            gapcallbacks.canonicalmin_time := gapcallbacks.canonicalmin_time + Int((NanosecondsSinceEpoch() - time)/1000000);
        elif result[1] = "refiner" then
            time := NanosecondsSinceEpoch();
            gapcallbacks.(result[3]) := gapcallbacks.(result[3]) + 1;
            result := _Vole.CallRefiner(savedvals, refiners[result[2]], result[3], result{[4..Length(result)]});
            Info(InfoVole, 2, "Refiner returned: ", GapToJsonString(result));
            IO_WriteLine(pipe.write, GapToJsonString(result));
            gapcallbacks.refiner_time := gapcallbacks.refiner_time + Int((NanosecondsSinceEpoch() - time)/1000000);
        elif result[1] = "stringGapRef" then
            Info(InfoVole, 2, "Print cached object: ", result);
            IO_WriteLine(pipe.write, Concatenation("\"",String(savedvals.map[result[2].id]),"\""));
        elif result[1] = "dropGapRef" then
            Info(InfoVole, 2, "Dropping cached object: ", result);
            Assert(2, IsBound(savedvals.map[result[2].id]));
            Unbind(savedvals.map[result[2].id]);
            # Need to still send something, as Rust expects a response
            IO_WriteLine(pipe.write, "[]");
        else
            IO_Close(pipe.write);
            IO_Close(pipe.read);
            if IsBound(pipe.pid) then
                IO_WaitPid(pipe.pid, true);
            else
                CloseStream(pipe.child);
            fi;
            ErrorNoReturn("Invalid return value from Vole: ", result);
        fi;
        flush := IO_Flush(pipe.write);
        Assert(2, flush <> fail);
    od;
end;


# Solve a problem using Vole
# 'points': Search will be done in the set [1..points]
# 'find_single': Find a single solution (only really makes sense when looking for a coset)
# 'find_coset': The solution may be a coset (note: This will still find groups, but if false,
#                and the solution is not a group, the wrong answer will be produced)
# 'constraints': List of constraints to solve
# 'canonical_group':
# TODO: Add Canonical group
_Vole.Solve :=
function(points, find_single, find_coset, find_canonical, constraints, canonical_group, root_search)
    local ret, gapcons, i, sc, gens, group, result, start_time,cosetrep, grprefiner;

    start_time := NanosecondsSinceEpoch();

    # Get rid of trivial cases
    points := Maximum(2, points);

    if canonical_group <> false then
        if IsNaturalSymmetricGroup(canonical_group) then
            grprefiner := VoleRefiner.InSymmetricGroup(MovedPoints(canonical_group));
        else
            grprefiner := GB_Con.InGroupSimple(canonical_group);
        fi;
        # TODO: Allow the refiner for the canonical group to be user-specified
        constraints := Concatenation([grprefiner], constraints);
    fi;

    gapcons := [];
    constraints := ShallowCopy(constraints);
    for i in [1 .. Length(constraints)] do
        if IsVoleRefiner(constraints[i]) then
            constraints[i] := constraints[i]!.con;
        elif IsRefiner(constraints[i]) then
            gapcons[i] := _GB.BuildProblem(PartitionStack(points), [constraints[i]], []);
            # We need somewhere to store the saved states for Vole
            gapcons[i]!.saved_stack := [];
            constraints[i] := rec(GapRefiner := rec(gap_id := i));
        fi;
    od;

    ret := _Vole.ExecuteVole(
              rec(
                  config := rec(
                      points         := points,
                      find_coset     := find_coset,
                      find_canonical := find_canonical,
                      root_search    := root_search,
                      search_config  := rec(full_graph_refine := false, find_single:= find_single),
                  ),
                  constraints := constraints),
              gapcons,
              canonical_group
          );

    result := rec(raw := ret, time := Int((NanosecondsSinceEpoch() - start_time)/1000000));

    if find_single then
        result.sol := List(ret.sols, PermList);
    else
        gens := List(ret.sols, PermList);
        result.sols := List(ret.sols, PermList);
        if IsEmpty(gens) then
            cosetrep := fail;
        else
            cosetrep := gens[1];
            if find_coset then
                gens := List(gens, x -> x*(cosetrep^-1));
            else
                Assert(0, gens[1] = (), "Invalid group");
            fi;
            Remove(gens, 1);
        fi;
        group := Group(gens, ());
        if not IsEmpty(ret.rbase_branches) then
            sc := StabChainBaseStrongGenerators(ret.rbase_branches, gens, ());
            # Knock out unneeded elements
            ReduceStabChain(sc);
            SetStabChainMutable(group, sc);
        fi;
        #Assert(0, SizeStabChain(sc) = Size(Group(gens)));

        result.group := group;
        result.cosetrep := cosetrep;
    fi;

    if find_canonical then
        result.canonical := PermList(ret.canonical);
    fi;

    return result;
end;

_Vole.GroupSolve :=
{points, constraints} -> _Vole.Solve(points, false, false, false, constraints, false, false);

_Vole.CosetSolve :=
{points, constraints} -> _Vole.Solve(points, false, true, false, constraints, false, false);

_Vole.CosetSingleSolve :=
{points, constraints} -> _Vole.Solve(points, true, true, false, constraints, false, false);

_Vole.CanonicalSolve :=
{points, group, constraints} -> _Vole.Solve(points, false, false, true, constraints, group, false);

_Vole.RootSolve := {points, constraints} -> _Vole.Solve(points, false, false, false, constraints, false, true);
