#
# BacktrackKit: An extensible, easy to understand backtracking framework
#
# Declarations for constraint objects
#
#! @Chapter Constraints
#! @ChapterLabel Constraints

################################################################################
## Chunks

#! @BeginChunk maybeinfinite
#! Note that the set of such permutations may be infinite.
#! @EndChunk

#! @BeginChunk isinfinite
#! Note that the set of such permutations is infinite.
#! @EndChunk

#! @BeginChunk nonuser
#! This constraint will typically not be required by the user.
#! @EndChunk

## End chunks
################################################################################


#! @Section The concept of constraints
#! @SectionLabel concept


#! Fundamentally, the partition backtrack algorithm (and its generalisations)
#! performs a search for permutations that satisfy a collection of constraints.
#!
#! A **constraint** is a <K>true</K>/<K>false</K> mathematical
#! property of permutations, such that if the set of permutations
#! satisfying the property is nonempty, then that set must be a
#! (possibly infinite) permutation group, or a coset thereof.
#! For constraints to be useful in practice, it should be ‘easy’ to test whether
#! any given permutation satisfies the property.
#!
#! For example:
#! * “is a member of the group $G = \langle X \rangle$”,
#! * “transports the set A to the set B”,
#! * “commutes with the permutation $x$”,
#! * “conjugates the group $G = \langle X \rangle$ to the group
#!   $H = \langle Y \rangle$”,
#! * “is an automorphism of the graph $\Gamma$”, and
#! * “is even”
#!
#! are all examples of constraints.
#! On the other hand:
#! * “is a member of the socle of the group $G$”, and
#! * “is a member of a largest maximal subgroup of the group $G$”
#!
#! do not qualify, unless generating sets for the socle and the largest
#! maximal subgroups of $G$ are **already** known,  and there is a unique such
#! maximal subgroup
#! (in which case these properties become instances of the constraint
#! “is a member of the group defined by the generating set...”).
#!
#! The term ‘constraint’ comes from the computer science field of constraint
#! satisfaction problems, constraint programming, and constraint solvers,
#! with which backtrack search algorithms are very closely linked.
#!
#! A number of built in constraints, and the functions to create them, are contained in the
#! <Ref Var="Constraint"/> record. The members of this record are documented
#! individually in Section&nbsp;<Ref Sect="Section_providedcons"/>.
#!
#! To perform a search, it is necessary to
#! (at least implicitly) specify constraints that, in conjunction,
#! define the permutation(s) that you wish to find.
#! A constraint will typically be converted into one or more
#! **refiners** by that the time that a search takes place.
#! Refiners are introduced in
#! Chapter&nbsp;<Ref Chap="Chapter_Refiners"/>, which are the low-level code
#! which implement constraints. We do not explicitly document the conversion of
#! constraints into refiners; the conversion may change in the future.


#! @Section The <C>Constraints</C> record
#! @SectionLabel ConstraintsRec

#! @Description
#!
#! <Ref Var="Constraint"/> is a record that contains functions for producing
#! all of the constraints provided by default.
#!
#! The members of <Ref Var="Constraint"/> are documented individually in
#! Section&nbsp;<Ref Sect="Section_providedcons"/>.
#!
#! The members whose names differ only by their “-ise” and “-ize” endings
#! are synonyms, included to accommodate different spellings in English.
#! @BeginExampleSession
#! gap> LoadPackage("BacktrackKit", false);;
#! gap> for c in Set(RecNames(Constraint)) do Print(c,"\n"); od;
#! Centralise
#! Centralize
#! Conjugate
#! Everything
#! InCoset
#! InGroup
#! InLeftCoset
#! InRightCoset
#! IsEven
#! IsOdd
#! IsTrivial
#! LargestMovedPoint
#! MovedPoints
#! None
#! Normalise
#! Normalize
#! Nothing
#! Stabilise
#! Stabilize
#! Transport
#!  @EndExampleSession
DeclareGlobalVariable("Constraint");
# TODO When we require GAP >= 4.12, use GlobalName rather than GlobalVariable
InstallValue(Constraint, AtomicRecord(rec()));


################################################################################

if not IsBoundGlobal("IsConstraint") then
    # Declare `IsConstraint` if Ferret has not already done so
    DeclareCategory("IsConstraint", IsObject);
fi;
DeclareCategoryCollections("IsConstraint");
BindGlobal(
    "ConstraintFamily",
    NewFamily("ConstraintFamily", IsConstraint)
);
DeclareRepresentation(
    "IsConstraintRep",
    IsConstraint and IsComponentObjectRep and IsAttributeStoringRep, []
);
BindGlobal(
    "ConstraintType",
    NewType(ConstraintFamily, IsConstraintRep)
);

DeclareCategory("IsTransporterConstraint", IsConstraint);
DeclareCategory("IsInCosetByGensConstraint", IsConstraint);

# Any constraint must be for a group, a coset of a group, or the empty set
DeclareProperty("IsCosetConstraint", IsConstraint);
DeclareProperty("IsGroupConstraint", IsConstraint);
DeclareProperty("IsEmptyConstraint", IsConstraint);
InstallTrueMethod(HasIsEmptyConstraint, IsCosetConstraint);
InstallTrueMethod(IsCosetConstraint, IsGroupConstraint);

DeclareSynonym("IsStabiliserConstraint", IsTransporterConstraint and IsGroupConstraint);
DeclareSynonym("IsStabilizerConstraint", IsStabiliserConstraint);
DeclareSynonym("IsInGroupByGensConstraint", IsInCosetByGensConstraint and IsGroupConstraint);

# Attributes of all constraints
DeclareAttribute("Representative", IsConstraint);
DeclareAttribute("LargestMovedPoint", IsConstraint);
DeclareAttribute("LargestRelevantPoint", IsConstraint);
DeclareAttribute("ImageFunc", IsConstraint);
DeclareAttribute("Check", IsConstraint);

# Things set at creation for transporter constraints
DeclareAttribute("ActionFunc", IsTransporterConstraint);
DeclareAttribute("SourceObject", IsTransporterConstraint);
DeclareSynonymAttr("LeftObject", SourceObject);
DeclareAttribute("ResultObject", IsTransporterConstraint);
DeclareSynonymAttr("RightObject", ResultObject);

# Things set at creation for in-coset constraints
DeclareAttribute("UnderlyingGroup", IsConstraint);

# A record to contain all constraint creator functions and one-off constraints




#! @Section Constraints via the <C>Constraint</C> record
#! @SectionLabel providedcons

#! In this section, we individually document the functions of the
#! <Ref Var="Constraint"/> record, which can be used to create the
#! built-in constraints provided by &BacktrackKit;.
#!
#! Many of these constraints come in pairs, with a “group” version,
#! and a corresponding “coset” version.
#! These relationships are given in the following table.

#! <Table Align="ll">
#! <Row>
#!   <Item>Group version</Item>
#!   <Item>Coset version</Item>
#! </Row>
#! <HorLine/>
#! <Row>
#!   <Item><Ref Func="Constraint.InGroup"/></Item>
#!   <Item>
#!     <Ref Func="Constraint.InCoset"/>
#!     <P/>
#!     <Ref Func="Constraint.InRightCoset"/>
#!     <P/>
#!     <Ref Func="Constraint.InLeftCoset"/>
#!   </Item>
#! </Row>
#! <Row>
#!   <Item>
#!     <Ref Func="Constraint.Stabilise"/>
#!   </Item>
#!   <Item><Ref Func="Constraint.Transport"/></Item>
#! </Row>
#! <Row>
#!   <Item>
#!     <Ref Func="Constraint.Normalise"/>
#!   </Item>
#!   <Item>
#!     <Ref Func="Constraint.Conjugate"/>
#!   </Item>
#! </Row>
#! <Row>
#!   <Item>
#!     <Ref Func="Constraint.Centralise"/>
#!   </Item>
#!   <Item>
#!     <Ref Func="Constraint.Conjugate"/>
#!   </Item>
#! </Row>
#! <Row>
#!   <Item><Ref Func="Constraint.MovedPoints"/></Item>
#!   <Item>N/A</Item>
#! </Row>
#! <Row>
#!   <Item><Ref Func="Constraint.LargestMovedPoint"/></Item>
#!   <Item>N/A</Item>
#! </Row>
#! <Row>
#!   <Item><Ref Var="Constraint.IsEven"/></Item>
#!   <Item><Ref Var="Constraint.IsOdd"/></Item>
#! </Row>
#! <Row>
#!   <Item><Ref Var="Constraint.IsTrivial"/></Item>
#!   <Item>N/A</Item>
#! </Row>
#! <Row>
#!   <Item>N/A</Item>
#!   <Item><Ref Var="Constraint.None"/></Item>
#! </Row>
#! </Table>



#! @Arguments G
#! @Returns A constraint
#! @Description
#! This constraint is satisfied by precisely those permutations in the
#! permutation group <A>G</A>.
#! @BeginExampleSession
#! gap> con1 := Constraint.InGroup(DihedralGroup(IsPermGroup, 8));
#! <constraint: in group: Group( [ (1,2,3,4), (2,4) ] )>
#! gap> con2 := Constraint.InGroup(AlternatingGroup(4));
#! <constraint: in group: AlternatingGroup( [ 1 .. 4 ] )>
#! @EndExampleSession
DeclareGlobalFunction("Constraint.InGroup");

#! @Arguments U
#! @Returns A constraint
#! @Description
#! This constraint is satisfied by precisely those permutations in the &GAP;
#! right coset object <A>U</A>.
#!
#! See also <Ref Func="Constraint.InLeftCoset"/>
#! and <Ref Func="Constraint.InRightCoset"/>, which allow a coset to be specifed
#! by a subgroup and a representative element.
#! @BeginExampleSession
#! gap> U := PSL(2,5) * (3,4,6);
#! RightCoset(Group([ (3,5)(4,6), (1,2,5)(3,4,6) ]),(3,4,6))
#! gap> Constraint.InCoset(U);
#! <constraint: in coset: Group( [ (3,5)(4,6), (1,2,5)(3,4,6) ] ) * (3,4,6)
#! @EndExampleSession
DeclareGlobalFunction("Constraint.InCoset");

#! @Arguments G, x
#! @Returns A constraint
#! @Description
#! This constraint is satisfied by precisely those permutations in the right
#! coset of the group <A>G</A> determined by the permutation <A>x</A>.
#!
#! See also <Ref Func="Constraint.InLeftCoset"/> for the left-hand version,
#! and <Ref Func="Constraint.InCoset"/> for a &GAP; right coset object.
#! @BeginExampleSession
#! gap> Constraint.InRightCoset(PSL(2,5), (3,4,6));
#! <constraint: in coset: Group( [ (3,5)(4,6), (1,2,5)(3,4,6) ] ) * (3,4,6)
#! @EndExampleSession
DeclareGlobalFunction("Constraint.InRightCoset");

#! @Arguments G, x
#! @Returns A constraint
#! @Description
#! This constraint is satisfied by precisely those permutations in the left
#! coset of the group <A>G</A> determined by the permutation <A>x</A>.
#!
#! See also <Ref Func="Constraint.InRightCoset"/> for the right-hand version,
#! and <Ref Func="Constraint.InCoset"/> for a &GAP; right coset object.
#! @BeginExampleSession
#! gap> Constraint.InLeftCoset(PSL(2,5), (3,4,6));
#! <constraint: in coset: Group( [ (3,6)(4,5), (1,2,5)(3,4,6) ] ) * (3,4,6)
#! @EndExampleSession
DeclareGlobalFunction("Constraint.InLeftCoset");


#! @Arguments object1, object2[, action]
#! @Returns A constraint
#! @Description
#! This constraint is satisfied by precisely those permutations that map
#! <A>object1</A> to <A>object2</A> under the given group <A>action</A>,
#! i.e. all permutations `g` such that
#! `<A>action</A>(<A>object1</A>,g)=<A>object2</A>`.
#! @InsertChunk maybeinfinite
#!
#! The combinations of objects and actions that are supported by
#! `Constraint.Transport` are given in the table below.
#!
#! @InsertChunk DefaultAction
#!
#! @InsertChunk ActionsTable
#! @BeginExampleSession
#! gap> setofsets1 := [[1, 3, 6], [2, 3, 6]];;
#! gap> setofsets2 := [[1, 2, 5], [1, 5, 7]];;
#! gap> con := Constraint.Transport(setofsets1, setofsets2, OnSetsSets);
#! <constraint: transporter of <matrix object of dimensions 2x3 over Rationals> t\
#! o <matrix object of dimensions 2x3 over Rationals> under OnSetsSets>
#! @EndExampleSession
DeclareGlobalFunction("Constraint.Transport");


#! @BeginGroup StabiliseDoc
#! @Arguments object[, action]
#! @Returns A constraint
#! @Description
#! This constraint is satisfied by precisely those permutations that fix
#! <A>object</A> under the given group <A>action</A>,
#! i.e. all permutations `g` such that
#! `<A>action</A>(<A>object</A>,g)=<A>object</A>`.
#! @InsertChunk maybeinfinite
#!
#! The combinations of objects and actions that are supported by
#! `Constraint.Stabilise` are given in the table below.
#!
#! @InsertChunk DefaultAction
#!
#! @InsertChunk ActionsTable
DeclareGlobalFunction("Constraint.Stabilise");
#! @EndGroup
#! @Arguments object[, action]
#! @Group StabiliseDoc
#! @BeginExampleSession
#! gap> con1 := Constraint.Stabilise(CycleDigraph(6), OnDigraphs);
#! <constraint: stabiliser of <immutable cycle digraph with 6 vertices> under OnD\
#! igraphs>
#! gap> con2 := Constraint.Stabilise([2,4,6], OnSets);
#! <constraint: stabiliser of [ 2, 4, 6 ] under OnSets>
#! @EndExampleSession
DeclareGlobalFunction("Constraint.Stabilize");

#! @BeginGroup NormaliseDoc
#! @Arguments G
#! @Returns A constraint
#! @Description
#! This constraint is satisfied by precisely those permutations that
#! normalise the permutation group <A>G</A>,
#! i.e. that preserve <A>G</A> under conjugation.
#!
#! @InsertChunk isinfinite
DeclareGlobalFunction("Constraint.Normalise");
#! @EndGroup
#! @Arguments G
#! @Group NormaliseDoc
#! @BeginExampleSession
#! gap> Constraint.Normalise(PSL(2,5));
#! <constraint: normalise Group( [ (3,5)(4,6), (1,2,5)(3,4,6) ] )>
#! @EndExampleSession
DeclareGlobalFunction("Constraint.Normalize");


#! @BeginGroup CentraliseDoc
#! @Arguments G
#! @Returns A constraint
#! @Description
#! This constraint is satisfied by precisely those permutations that
#! commute with <A>G</A>, if <A>G</A> is a permutation, or that
#! commute with every element of <A>G</A>, if <A>G</A> is a permutation group.
#!
#! @InsertChunk isinfinite
DeclareGlobalFunction("Constraint.Centralise");
#! @EndGroup
#! @Arguments G
#! @Group CentraliseDoc
#! @BeginExampleSession
#! gap> D12 := DihedralGroup(IsPermGroup, 12);;
#! gap> Constraint.Centralise(D12);
#! <constraint: centralise group Group( [ (1,2,3,4,5,6), (2,6)(3,5) ] )>
#! gap> x := (1,6)(2,5)(3,4);;
#! gap> Constraint.Centralise(x);
#! <constraint: centralise perm (1,6)(2,5)(3,4)>
#! @EndExampleSession
DeclareGlobalFunction("Constraint.Centralize");


#! @Arguments x, y
#! @Returns A constraint
#! @Description
#! This constraint is satisfied by precisely those permutations that
#! conjugate <A>x</A> to <A>y</A>, where <A>x</A> and <A>y</A> are either
#! both permutations, or both permutation groups.
#!
#! @InsertChunk maybeinfinite
#!
#! This constraint is equivalent to
#! `Constraint.Transport(<A>x</A>,<A>y</A>,OnPoints)`.
#!
#! @BeginExampleSession
#! gap> Constraint.Conjugate((3,4)(2,5,1), (1,2,3)(4,5));
#! <constraint: conjugate perm (1,2,5)(3,4) to (1,2,3)(4,5)>
#! @EndExampleSession
DeclareGlobalFunction("Constraint.Conjugate");


#! @Arguments pointlist
#! @Returns A constraint
#! @Description
#! This constraint is a shorthand for
#! `Constraint.InGroup(SymmetricGroup(<A>pointlist</A>))`.
#! See <Ref Func="Constraint.InGroup"/>.
#! @BeginExampleSession
#! gap> con1 := Constraint.MovedPoints([1..5]);
#! <constraint: moved points: [ 1 .. 5 ]>
#! gap> con2 := Constraint.MovedPoints([2,6,4,5]);
#! <constraint: moved points: [ 2, 6, 4, 5 ]>
#! @EndExampleSession
DeclareGlobalFunction("Constraint.MovedPoints");

#! @Arguments point
#! @Returns A constraint
#! @Description
#! This constraint is a shorthand for
#! `Constraint.InGroup(SymmetricGroup(<A>point</A>))`,
#! where <A>point</A> is a nonnegative integer.
#! See <Ref Func="Constraint.InGroup"/>.
#! @BeginExampleSession
#! gap> con := Constraint.LargestMovedPoint(5);
#! <constraint: largest moved point: 5>
#! @EndExampleSession
DeclareGlobalFunction("Constraint.LargestMovedPoint");


#! @Description
#! This constraint is satisfied by the even permutations,
#! i.e. those permutations with sign `1`.
#! In other words, this constraint restricts a search to some alternating
#! group.
#!
#! @InsertChunk isinfinite
#! @BeginExampleSession
#! gap> Constraint.IsEven;
#! <constraint: is even permutation>
#! gap> Representative(Constraint.IsEven);
#! ()
#! @EndExampleSession
DeclareGlobalVariable("Constraint.IsEven");

#! @Description
#! This constraint is satisfied by the odd permutations,
#! i.e. those permutations with sign `-1`.
#! In other words, this constraint restricts a search to the unique coset of
#! some alternating group.
#!
#! @InsertChunk isinfinite
#! @BeginExampleSession
#! gap> Constraint.IsOdd;
#! <constraint: is odd permutation>
#! gap> Representative(Constraint.IsOdd);
#! (1,2)
#! @EndExampleSession
DeclareGlobalVariable("Constraint.IsOdd");

#! @Description
#! This constraint is satisfied by the identity permutation and no others.
#!
#! @InsertChunk nonuser
#! @BeginExampleSession
#! gap> Constraint.IsTrivial;
#! <trivial constraint: is identity permutation>
#! gap> Representative(Constraint.IsTrivial);
#! ()
#! @EndExampleSession
DeclareGlobalVariable("Constraint.IsTrivial");

#! @Description
#! This constraint is satisfied by no permutations.
#!
#! @InsertChunk nonuser
#! @BeginExampleSession
#! gap> Constraint.None;
#! <empty constraint: satisfied by no permutations>
#! gap> Representative(Constraint.None);
#! fail
#! @EndExampleSession
DeclareGlobalVariable("Constraint.None");

#! @Description
#! This constraint is satisfied by all permutations.
#!
#! @InsertChunk nonuser
#! @BeginExampleSession
#! gap> Constraint.Everything;
#! <constraint: satisfied by all permutations>
#! gap> Representative(Constraint.Everything);
#! ()
#! @EndExampleSession
DeclareGlobalVariable("Constraint.Everything");
