#
# Vole: Backtrack search in permutation groups with graphs
#

#! @Chapter Solving problems with &Vole;


#! @Section Constraints/refiners
#!
#! Constraints and refiners are kind of two names for the same things.
#! Well, depending on your definitions.

#! @Description
#!
#! <C>VoleCon</C> is a record that contains all of the constraints which &Vole; supports.
#! When solving a 'constraint' will be mapped into one or more low-level 'refiners'.
#! The choice of refiner(s) can vary depending on the input, and may be changed between
#! versions of Vole as better refiners are created.
#! @BeginExampleSession
#! gap> VoleCon;
#! rec( DigraphStab := function( e ) ... end,
#!   DigraphTransport := function( e, f ) ... end,
#!   SetSetStab := function( s ) ... end,
#!   SetSetTransport := function( s, t ) ... end,
#!   SetStab := function( s ) ... end, SetTransport := function( s, t ) ... end,
#!   SetTupleStab := function( s ) ... end,
#!   SetTupleTransport := function( s, t ) ... end,
#!   TupleStab := function( s ) ... end,
#!   TupleTransport := function( s, t ) ... end )
#! @EndExampleSession
# TODO When we require GAP >= 4.12, use GlobalName rather than GlobalVariable
DeclareGlobalVariable("VoleCon");

#! The currently-implemented constraints in &Vole; are:
#! * `SetStab`
#! * `SetTransport`
#! * `SetSetStab`
#! * `SetSetTransport`
#! * `SetTupleStab`
#! * `SetTupleTransport`
#! * `DigraphStab`
#! * `DigraphTransport`
#! These will be properly documented at some point.

#! @Description
#!
#! <C>VoleRefiners</C> is a record that contains all of the &Vole; refiners.
#! There can be multiple refiners implemented for the same mathematical property
#! with different tradeoffs, and also refiners implemented for special cases
#! (such as symmetric and alternating groups). In general most users will want to
#! use 'VoleCon', which provides a higher-level interface.
#! @BeginExampleSession
#! gap> VoleCon;
#! rec( DigraphStab := function( e ) ... end,
#!   DigraphTransport := function( e, f ) ... end,
#!   SetSetStab := function( s ) ... end,
#!   SetSetTransport := function( s, t ) ... end,
#!   SetStab := function( s ) ... end, SetTransport := function( s, t ) ... end,
#!   SetTupleStab := function( s ) ... end,
#!   SetTupleTransport := function( s, t ) ... end,
#!   TupleStab := function( s ) ... end,
#!   TupleTransport := function( s, t ) ... end )
#! @EndExampleSession
# TODO When we require GAP >= 4.12, use GlobalName rather than GlobalVariable
DeclareGlobalVariable("VoleRefiners");




#! @Section Functions to execute a search
#!
#! This section will say something about something.
#! We will talk about the things the following things have in common.

#! @Description
#! Need to write a description!
#!
#! @Arguments points, find_single, constraints
#! @Returns A record
DeclareGlobalFunction("VoleSolve");

#! @Description
#! Need to write a description!
#!
#! @Arguments points, constraints
#! @Returns A record
DeclareGlobalFunction("VoleGroupSolve");

#! @Description
#! Need to write a description!
#!
#! @Arguments points, constraints
#! @Returns A record
DeclareGlobalFunction("VoleCosetSolve");

#! @Description
#! Need to write a description!
#!
#! @Arguments points, group, constraints
#! @Returns A record
DeclareGlobalFunction("VoleCanonicalSolve");


# Undocumented (for now, anyway)
DeclareGlobalFunction("CallRefiner");
DeclareGlobalFunction("ForkVole");
DeclareGlobalFunction("ExecuteVole");
DeclareGlobalFunction("_VoleSolve");


#! @Chapter Technical stuff

#! @Description
#! <C>InfoVole</C> is the primary info class for &Vole;.
#! See <Ref Sect="Info Functions" BookName="ref"/> for a description of info
#! classes in &GAP;.
#!
#! The default info level is 0. Most info messages are given at
#! level 2, and additional messages are given at level 4.
DeclareInfoClass("InfoVole");
