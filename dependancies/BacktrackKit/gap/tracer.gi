##
##  This file defines tracers.
##

# Recording tracers

InstallGlobalFunction(RecordingTracer,
{} -> Objectify(RecordingTracerTypeMutable, rec(trace := []) ));

InstallMethod(AddEvent, [IsRecordingTracerRep and IsMutable, IsObject],
function(tracer, o)
    Add(tracer!.trace, o);
    return true;
end);

InstallMethod(TraceLength, [IsRecordingTracerRep],
{x} -> Length(x!.trace));
InstallMethod(TraceEvent, [IsRecordingTracerRep, IsPosInt],
{x,i} -> x!.trace[i]);

InstallMethod(ViewObj, [IsRecordingTracerRep],
function(t)
    PrintFormatted("<recording tracer of length {}>", TraceLength(t));
end);


# Following tracers

InstallGlobalFunction(FollowingTracer,
function(trace)
    if IsFollowingTracerRep(trace) then
        ErrorNoReturn("a following tracer cannot follow a following tracer,");
    fi;
    return Objectify(FollowingTracerTypeMutable,
        rec(existingTrace := trace, pos := 1) );
end);

InstallMethod(AddEvent, [IsFollowingTracerRep and IsMutable, IsObject],
function(tracer, o)
    if tracer!.pos > TraceLength(tracer!.existingTrace) then
        Info(InfoTrace, 1, "Too long!");
        return false;
    elif TraceEvent(tracer!.existingTrace, tracer!.pos) <> o then
        Info(InfoTrace, 1, StringFormatted("Trace violation {}:{}",
                            TraceEvent(tracer!.existingTrace, tracer!.pos), o));
        tracer!.pos := infinity;
        return false;
    fi;
    tracer!.pos := tracer!.pos + 1;
    return true;
end);

InstallMethod(TraceLength, [IsFollowingTracerRep],
{x} -> TraceLength(x!.existingTrace));
InstallMethod(TraceEvent, [IsFollowingTracerRep, IsPosInt],
{x,i} -> TraceEvent(x!.existingTrace, i));

InstallMethod(ViewObj, [IsFollowingTracerRep],
function(t)
    PrintFormatted("<following tracer of length {}>", TraceLength(t));
end);


# Canonicalising tracers

InstallGlobalFunction(CanonicalisingTracerFromTracer,
function(trace)
    if not IsCanonicalisingTracerRep(trace) then
        ErrorNoReturn("a canonicalising tracer must be based on another canonicalising tracer,");
    fi;
    return Objectify(CanonicalisingTracerTypeMutable,
        rec(trace := List(trace!.trace), pos := 1, improvedTrace := false));
end);

InstallGlobalFunction(EmptyCanonicalisingTracer,
function()
    return Objectify(CanonicalisingTracerTypeMutable,
        rec(trace := [], pos := 1, improvedTrace := false) );
end);

InstallMethod(AddEvent, [IsCanonicalisingTracerRep and IsMutable, IsObject],
    function(tracer, o)
        Assert(2, tracer!.pos >= 1 and tracer!.pos <= Length(tracer!.trace) + 1);
        # Extending trace (always fine)
        if tracer!.pos = Length(tracer!.trace) + 1 then
            Add(tracer!.trace, o);
            tracer!.pos := tracer!.pos + 1;

            # Record the fact we improved the trace, as this effects search
            tracer!.improvedTrace := true;
            return true;
        fi;

        # On the trace
        if tracer!.trace[tracer!.pos] = o then
            tracer!.pos := tracer!.pos + 1;
            return true;
        fi;

        # Trace beats us
        if tracer!.trace[tracer!.pos] < o then
            Info(InfoTrace, 2, "Trace beats: ", tracer!.pos, ":", tracer!.trace[tracer!.pos], ":", o);
            return false;
        fi;


        # Replacing previous trace
        Assert(2, tracer!.trace[tracer!.pos] > o);
        Info(InfoTrace, 2, "New best trace: ", tracer!.pos, ":", tracer!.trace[tracer!.pos], ":", o);
        tracer!.trace[tracer!.pos] := o;
        tracer!.trace := tracer!.trace{[1..tracer!.pos]};
        tracer!.pos := tracer!.pos + 1;
        
        # Record the fact we improved the trace, as this effects search
        tracer!.improvedTrace := true;
        return true;
    end);

InstallMethod(TraceLength, [IsCanonicalisingTracerRep],
{x} -> TraceLength(x!.trace));
InstallMethod(TraceEvent, [IsCanonicalisingTracerRep, IsPosInt],
{x,i} -> TraceEvent(x!.trace, i));

InstallMethod(GetEvents, [IsCanonicalisingTracerRep],
{x} -> x!.trace);

InstallMethod(ViewObj, [IsCanonicalisingTracerRep],
function(t)
    PrintFormatted("<canonicalising tracer of length {}>", TraceLength(t));
end);