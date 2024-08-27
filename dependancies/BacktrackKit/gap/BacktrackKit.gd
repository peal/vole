
#! @Chapter Executing a search

#! @Section Extra information and stats


#! @Description
#! Information about backtrack search.
DeclareInfoClass( "InfoBTKit" );
SetInfoLevel(InfoBTKit, 0);

#! @Arguments
DeclareGlobalFunction( "BTKit_ResetStats" );

DeclareGlobalFunction( "BTKit_Stats_AddNode" );


#! @Chapter Implementation


#! @Section State


#!
DeclareCategory("IsBacktrackableState", IsObject);

#!
DeclareRepresentation("IsBTKitState", IsBacktrackableState, []);

#!
#DeclareGlobalVariable("BacktrackableStateFamily");
BindGlobal("BacktrackableStateFamily",
           NewFamily("BacktrackableStateFamily", IsBacktrackableState));

#!
#DeclareGlobalVariable("BTKitStateType");
BindGlobal("BTKitStateType", NewType(BacktrackableStateFamily, IsBTKitState));

#! @Description
#! Return a small object which allows one to revert to this state from later
#! the search.
#!
#! @Returns The saved state
DeclareOperation("SaveState", [IsBacktrackableState]);

#! @Description
#! Revert to a saved state from later in the search. The first argument
#! <A>state</A> must be the current state object, and the second argument
#! <A>saved</A> must be one of the objects produced by
#! <Ref Oper="SaveState" Label="for IsBacktrackableState"/>
#! from earlier in the search.
#!
#! @Arguments state, saved
#! @Returns Nothing
DeclareOperation("RestoreState", [IsBacktrackableState, IsObject]);

#! @Description
#! Some implementations of `BacktrackableState` can perform simplifications.
#! This function gives a well-defined point for such operations to be
#! performed. It can be ignored by implementations without such simplifications.
DeclareOperation("ConsolidateState", [IsBacktrackableState, IsTracer]);


#! @Section Applying refiners


#! @Description
#! Set up the list of constraints in <C><A>state</A>.conlist</C>, using their
#! <C>refine.initialise</C> members. This should be called once at the start of
#! RBase creation, and once at the start of search. During search, if the branch
#! of search becomes inconsistent with the RBase, then this function returns
#! <K>false</K>. Otherwise, this function returns <K>true</K>.
#!
#! The second and third arguments <A>tracer</A> and <A>rbase</A> should be as in
#! <Ref Func="RefineConstraints"/>.
#!
#! @Arguments state, tracer, rbase
#! @Returns <K>true</K> or <K>false</K>
DeclareGlobalFunction( "InitialiseConstraints" );

#! @Description
#! Refine the partition stack <C><A>state</A>.ps</C> according to the list of
#! constraints in <C><A>state</A>.conlist</C>, until it is not possible to use
#! them to refine the current partition stack any further, or until the branch
#! of search becomes inconsistent with the RBase. In the former case, this
#! function returns <K>true</K>, and in the latter case, this function returns
#! <K>false</K>.
#!
#! During RBase creation, the second argument <A>tracer</A> must be
#! a recording tracer, and the third argument <A>rbase</A> must be <K>true</K>.
#! During search, the second argument should be a tracer following the
#! corresponding RBase tracer, and the third argument <A>rbase</A> should be
#! <K>false</K>.
#!
#! @Arguments state, tracer, rbase
#! @Returns <K>true</K> or <K>false</K>
DeclareGlobalFunction( "RefineConstraints" );

#! @Description
#! Set up a list of constraints. This should be called once, at
#! the start of search after all constraints have been created.
DeclareGlobalFunction( "FinaliseRBaseForConstraints" );

#! @Description
#! Split the cells of the partition stack <A>ps</A>, if possible, according
#! to a given <A>filter</A>. If the filter is <K>fail</K>, or if the split is
#! rejected by the <A>tracer</A>, then this function returns <K>false</K>.
#! Otherwise, the split is applied and is consistent with the <A>tracer</A>,
#! and this function returns <K>true</K>.
#!
#! @Arguments ps, tracer, filter
#! @Returns <K>true</K> or <K>false</K>
DeclareOperation("ApplyFilters", [IsBTKitState, IsTracer, IsObject]);


#! @Section Currently unorganised stuff

#! @Description
#! Takes a partition stack and a list of constraints and builds a 'Problem',
#! Which can then be solved by passing the 'Problem'
#! to <Ref Func="BTKit_SimpleSearch"/>
#! or <Ref Func="BTKit_SimpleSinglePermSearch"/>.
DeclareGlobalFunction( "BTKit_BuildProblem" );

#!
DeclareGlobalFunction( "FirstFixedPoint" );

#!
DeclareGlobalFunction( "BuildRBase" );

#!
DeclareGlobalFunction( "Backtrack" );

# From init.g
_BTKit.CheckInitg := true;