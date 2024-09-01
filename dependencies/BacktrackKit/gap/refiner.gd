#
# BacktrackKit: An extensible, easy to understand backtracking framework
#
# Declarations for refiner objects
#
#! @Chapter Refiners
#!
#! @Section Introduction to refiners
#!
#! In &BacktrackKit;, a refiner is implemented as a record that must contain:
#!
#! * A member called `name`, which is a string giving the name of the
#!   constraint;
#! * A member called `largest_required_point`, which is an integer
#!   which gives the smallest size partition this refiner will work on.
#!   For example, given a set we would expect this to be the largest element
#!   of the set.
#! * A member called `constraint`, which is a constraint object, such that the
#!   refiner is refining for the permutations that satisfy the constraint.
#! * A member called `refine`, which is a record; more information is
#!   given below.
#!
#! A constraint may also optionally contain any of the following members:
#!
#! * A member called `btdata`. The data in this member
#!   will be automatically saved and restored on backtrack.
#!
#! @Section The record <C>refine</C>
#!
#! The `refine` member of a constraint is a record that contains
#! functions which, if present, will be called to inform the constraint
#! of behaviour as search progresses, and to give the constraint the
#! opportunity to influence the search. The permissible functions are given
#! described below.
#!
#! These functions will always be passed at least two arguments: firstly the
#! constraint itself, and then the partition stack. Details of any further
#! arguments are described with the relevant function, below.
#!
#TODO: the return value of `initialise` seems to be important.
#! * `initialise` __(required)__. This is called when search begins.
#!   Note that, since the `refine.initialise` function is called for all
#!   relevant constraints at the beginning of search, the partition may have
#!   already been split by some earlier constraint by the time that
#!   `refine.initialise` is called for a later constraint.
#!
#TODO: this is incomplete
#! At most one of the following two functions will generally be implemented.

#! * `changed` - Will be called after one or more splits in the partition occur.
#! * `fixed` - Will be called after one or more points in the partition became fixed.
#!
#! * `rBaseFinished` - The rBase has been created -- this is passed the partition
#!   which was generated down the first branch of search.
#!   Constraints which care about this can use this to remember the rBase
#!   construction is finished.
#! * `solutionFound` - A solution to the problem has been found. This function
#!   is passed a permutation. This function is rarely needed.

DeclareCategory("IsRefiner", IsBacktrackableState);
BindGlobal("RefinerFamily", NewFamily("RefinerFamily", IsRefiner));

DeclareRepresentation("IsBTKitRefiner", IsRefiner, ["name", "check", "refine"]);
BindGlobal("BTKitRefinerType", NewType(RefinerFamily, IsBTKitRefiner));


#! @Section Constructing refiners


#! @Arguments constraint
#! @Description
#! This wraps a constraint in a refiner that doesn't do any refining.
DeclareAttribute("DummyRefiner", IsConstraint);

DeclareGlobalFunction("BTKit_RefinerFromConstraint");
