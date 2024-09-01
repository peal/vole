#
# BacktrackKit: An extensible, easy to understand backtracking framework
#
#! @Chapter Ordered tracers
#!
#! An __ordered tracer__ is...
# TODO complete the description of an ordered tracer.


#! @Section API
#!
#! @Description
#! Constructor for recording tracers.
#! @Arguments
#! @Returns A recording tracer
DeclareGlobalFunction("RecordingTracer");

#! @Description
#! If the argument <A>t</A> is a tracer, then this constructs a tracer that
#! follows <A>t</A>.
#! @Arguments t
#! @Returns A following tracer
DeclareGlobalFunction("FollowingTracer");

#! @Description
#! Constructor for canonicalising tracers.
#! @Arguments
#! @Returns A canonicalising tracer
DeclareGlobalFunction("CanonicalisingTracerFromTracer");
DeclareGlobalFunction("EmptyCanonicalisingTracer");


#! @Description
#! The category of tracers.
#!
#! @Arguments t
#! @Returns <K>true</K> or <K>false</K>
DeclareCategory("IsTracer", IsObject);
BindGlobal( "TracerFamily", NewFamily("TracerFamily") );


DeclareRepresentation( "IsRecordingTracerRep",
                       IsTracer and IsComponentObjectRep, []);
BindGlobal( "RecordingTracerType", NewType(TracerFamily, IsRecordingTracerRep));
BindGlobal( "RecordingTracerTypeMutable",
            NewType(TracerFamily, IsRecordingTracerRep and IsMutable));

DeclareRepresentation( "IsFollowingTracerRep",
                       IsTracer and IsComponentObjectRep, []);
BindGlobal( "FollowingTracerType", NewType(TracerFamily, IsFollowingTracerRep));
BindGlobal( "FollowingTracerTypeMutable",
            NewType(TracerFamily, IsFollowingTracerRep and IsMutable));

DeclareRepresentation( "IsCanonicalisingTracerRep",
                       IsTracer and IsComponentObjectRep, []);
BindGlobal( "CanonicalisingTracerType",
            NewType(TracerFamily, IsCanonicalisingTracerRep));
BindGlobal( "CanonicalisingTracerTypeMutable",
            NewType(TracerFamily, IsCanonicalisingTracerRep and IsMutable));

#! @Description
#! Add the arbitrary GAP object <A>o</A> as an event to the tracer <A>t</A>.
#! This returns <K>true</K> if the event is accepted by the tracer, and
#! <K>false</K> if not. Events are always accepted by recording tracers.
#!
#! @Returns <K>true</K> or <K>false</K>
#! @Arguments t, o
DeclareOperation("AddEvent", [IsTracer, IsObject]);

#! @Description
#! Get the number of events in the tracer <A>t</A>.
#!
#! @Returns An integer
#! @Arguments t
DeclareOperation("TraceLength", [IsTracer]);

#! @Description
#! Get the event at position <A>i</A> in the tracer <A>t</A>.
#! The argument <A>i</A> must lie in the range
#! <C>[1..TraceLength(<A>t</A>)]</C>.
#!
#! @Returns A GAP object
#! @Arguments t, i
DeclareOperation("TraceEvent", [IsTracer, IsPosInt]);

#! @Description
#! Get a list of all events in the tracer.
#!
#! @Returns A GAP list
#! @Arguments t
DeclareOperation("GetEvents", [IsTracer]);

DeclareInfoClass("InfoTrace");
SetInfoLevel(InfoTrace, 0);

# This adds a horribly hacky "customisation point", for me to play with.
MaybeAddEvent := function(t, o) return AddEvent(t, o); end;
