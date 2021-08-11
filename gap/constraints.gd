# Vole: Backtrack search in permutation groups with graphs
# A GAP package by Mun See Chang, Christopher Jefferson, and Wilf A. Wilson.
#
# SPDX-License-Identifier: MPL-2.0
#
# Declarations: Vole constraints


################################################################################
## Chunks

#! @BeginChunk maybeinfinite
#! Note that the set of such permutations may be infinite.
#! @EndChunk

#! @BeginChunk isinfinite
#! Note that the set of such permutations is infinite.
#! @EndChunk

## End chunks
################################################################################


#! @Chapter Constraints

#! @Section The concept of constraints in &Vole;
#! @SectionLabel concept

#! At its core, &Vole; searches for permutations that satisfy a collection
#! of constraints.
#! A <E>constraint</E> is a property, such that for any given permutation,
#! it is easy to check whether that permutation has the property or not.
#! In addition, if the set of permutations that satisfy a property is nonempty,
#! then that set must be a (possibly infinite) permutation group,
#! or a coset thereof.
#!
#! For example:
#! * “is even”,
#! * “commutes with the permutation $x$”,
#! * “conjugates the group $G = \langle X \rangle$ to the group
#!   $H = \langle Y \rangle$”,
#! * “is an automorphism of the graph $\Gamma$”, and
#! * “is a member of the group $G = \langle X \rangle$”
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
#! computer science, with which backtrack search algorithms are very closely
#! linked.
#!
#! To use &Vole; via its native interface
#! (Chapter&nbsp;<Ref Chap="Chapter_interface"/>),
#! it is necessary to choose a selection of constraints that, in conjunction,
#! define the permutation(s) for which you wish to search.
#! &Vole; provides a number of built-in constraints. These can be created with
#! the functions contained in the <Ref Var="VoleCon"/> record,
#! which are documented individually in
#! Section&nbsp;<Ref Sect="Section_providedcons"/>.
#! While the included constraints are not exhaustive,
#! they do cover a wide range of problems in computational group theory,
#! and we welcome suggestions of additional constraints that we could implement.
#!
#! Internally, a constraint is eventually converted into one or more refiners
#! by that the time that the search takes place. Refiners are introduced in
#! Chapter&nbsp;<Ref Chap="Chapter_Refiners"/>.
#! We do not explicitly document the conversion of &Vole;
#! constraints into refiners;
#! the conversion may change in future versions of &Vole;
#! as we introduce improve our refiners and introduce new ones.
#! In addition, we do not explicitly document the kind of object that a
#! &Vole; constraint is. Currently, constraints may be
#! &Vole; refiners,
#! &GraphBacktracking; refiners,
#! &BacktrackKit; refiners,
#! records, lists, or the value <K>fail</K>.


#! @Section The <C>VoleCon</C> record
#! @SectionLabel VoleCon

#! @Description
#!
#! <Ref Var="VoleCon"/> is a record that contains functions for producing
#! all of the constraints that &Vole; provides.
#!
#! The members of <Ref Var="VoleCon"/> are documented individually in
#! Section&nbsp;<Ref Sect="Section_providedcons"/>.
#!
#! The members whose names differ only by their “-ise” and “-ize” endings
#! are synonyms, included to accommodate different spellings in English.
#! @BeginExampleSession
#! gap> LoadPackage("vole", false);;
#! gap> Set(RecNames(VoleCon));
#! [ "Centralise", "Centralize", "Conjugate", "InCoset", "InGroup", 
#!   "InLeftCoset", "InRightCoset", "LargestMovedPoint", "MovedPoints", "None", 
#!   "Normalise", "Normalize", "Stabilise", "Stabilize", "Transport" ]
#!  @EndExampleSession
DeclareGlobalVariable("VoleCon");
# TODO When we require GAP >= 4.12, use GlobalName rather than GlobalVariable
InstallValue(VoleCon, rec());


#! @Section &Vole; constraints via the <C>VoleCon</C> record
#! @SectionLabel providedcons

#! In this section, we individually document the functions of the
#! <Ref Var="VoleCon"/> record, which can be used to create the
#! built-in constraints provided by &Vole;
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
#!   <Item><Ref Func="VoleCon.InGroup"/></Item>
#!   <Item>
#!     <Ref Func="VoleCon.InCoset"/>
#!     <P/>
#!     <Ref Func="VoleCon.InRightCoset"/>
#!     <P/>
#!     <Ref Func="VoleCon.InLeftCoset"/>
#!   </Item>
#! </Row>
#! <Row>
#!   <Item>
#!     <Ref Func="VoleCon.Stabilise"/>
#!   </Item>
#!   <Item><Ref Func="VoleCon.Transport"/></Item>
#! </Row>
#! <Row>
#!   <Item>
#!     <Ref Func="VoleCon.Normalise"/>
#!   </Item>
#!   <Item>
#!     <Ref Func="VoleCon.Conjugate"/>
#!   </Item>
#! </Row>
#! <Row>
#!   <Item>
#!     <Ref Func="VoleCon.Centralise"/>
#!   </Item>
#!   <Item>
#!     <Ref Func="VoleCon.Conjugate"/>
#!   </Item>
#! </Row>
#! <Row>
#!   <Item><Ref Func="VoleCon.MovedPoints"/></Item>
#!   <Item>N/A</Item>
#! </Row>
#! <Row>
#!   <Item><Ref Func="VoleCon.LargestMovedPoint"/></Item>
#!   <Item>N/A</Item>
#! </Row>
#! <Row>
#!   <Item>N/A</Item>
#!   <Item><Ref Func="VoleCon.None"/></Item>
#! </Row>
#! </Table>


#! @Arguments G
#! @Returns A constraint
#! @Description
#! This constraint is satisfied by precisely those permutations in the
#! permutation group <A>G</A>.
#! @BeginExampleSession
#! gap> con1 := VoleCon.InGroup(DihedralGroup(IsPermGroup, 8));;
#! gap> con2 := VoleCon.InGroup(AlternatingGroup(4));;
#! gap> VoleFind.Group(con1, con2) = Group([(1,3)(2,4), (1,4)(2,3)]);
#! true
#! @EndExampleSession
DeclareGlobalFunction("VoleCon.InGroup");


#! @Arguments U
#! @Returns A constraint
#! @Description
#! This constraint is satisfied by precisely those permutations in the &GAP;
#! right coset object <A>U</A>.
#!
#! See also <Ref Func="VoleCon.InLeftCoset"/>
#! and <Ref Func="VoleCon.InRightCoset"/>, which allow a coset to be specifed
#! by a subgroup and a representative element.
#! @BeginExampleSession
#! gap> U := PSL(2,5) * (3,4,6);
#! RightCoset(Group([ (3,5)(4,6), (1,2,5)(3,4,6) ]),(3,4,6))
#! gap> x := VoleFind.Coset(VoleCon.InCoset(U), AlternatingGroup(6));
#! RightCoset(Group([ (3,5)(4,6), (2,4)(5,6), (1,2,6,5,4) ]),(1,5)(2,3,4,6))
#! gap> x = Intersection(U, AlternatingGroup(6));
#! true
#! @EndExampleSession
DeclareGlobalFunction("VoleCon.InCoset");


#! @Arguments G, x
#! @Returns A constraint
#! @Description
#! This constraint is satisfied by precisely those permutations in the right
#! coset of the group <A>G</A> determined by the permutation <A>x</A>.
#!
#! See also <Ref Func="VoleCon.InLeftCoset"/> for the left-hand version,
#! and <Ref Func="VoleCon.InCoset"/> for a &GAP; right coset object.
#! @BeginExampleSession
#! gap> x := VoleFind.Coset(VoleCon.InRightCoset(PSL(2,5), (3,4,6)),
#! >                        VoleCon.InGroup(AlternatingGroup(6)));
#! RightCoset(Group([ (3,5)(4,6), (2,4)(5,6), (1,2,6,5,4) ]),(1,5)(2,3,4,6))
#! gap> x = Intersection(PSL(2,5) * (3,4,6), AlternatingGroup(6));
#! true
#! @EndExampleSession
DeclareGlobalFunction("VoleCon.InRightCoset");


#! @Arguments G, x
#! @Returns A constraint
#! @Description
#! This constraint is satisfied by precisely those permutations in the left
#! coset of the group <A>G</A> determined by the permutation <A>x</A>.
#! 
#! See also <Ref Func="VoleCon.InRightCoset"/> for the right-hand version,
#! and <Ref Func="VoleCon.InCoset"/> for a &GAP; right coset object.
#! @BeginExampleSession
#! gap> x := VoleFind.Rep(VoleCon.InLeftCoset(PSL(2,5), (3,4,6)),
#! >                      VoleCon.InGroup(AlternatingGroup(6)));
#! (1,6,2,3,4)
#! gap> SignPerm(x) = 1 and ForAny(PSL(2,5), g -> x = (3,4,6) * g);
#! true
#! @EndExampleSession
DeclareGlobalFunction("VoleCon.InLeftCoset");


#! @BeginGroup StabiliseDoc
#! @Arguments object[, action]
#! @Returns A constraint
#! @Description
#! This constraint is satisfied by precisely those permutations that fix
#! <A>object</A> under <A>action</A>,
#! i.e. all permutations `g` such that
#! `<A>action</A>(<A>object</A>,g)=<A>object</A>`.
#! @InsertChunk maybeinfinite
#!
#! The combinations of objects and actions that are supported by
#! `VoleCon.Stabilise` are given in the table below.
#!
#! @InsertChunk DefaultAction
#!
#! @InsertChunk ActionsTable
DeclareGlobalFunction("VoleCon.Stabilise");
#! @EndGroup
#! @Arguments object[, action]
#! @Group StabiliseDoc
#! @BeginExampleSession
#! gap> con1 := VoleCon.Stabilise(CycleDigraph(6), OnDigraphs);;
#! gap> con2 := VoleCon.Stabilise([2,4,6], OnSets);;
#! gap> VoleFind.Group(con1, 6);
#! Group([ (1,2,3,4,5,6) ])
#! gap> VoleFind.Group(con2, 6);
#! Group([ (4,6), (2,4,6), (3,5)(4,6), (1,3,5)(2,4,6) ])
#! gap> VoleFind.Group(con1, con2, 6);
#! Group([ (1,3,5)(2,4,6) ])
#! @EndExampleSession
DeclareGlobalFunction("VoleCon.Stabilize");


#! @Arguments object1, object2[, action]
#! @Returns A constraint
#! @Description
#! This constraint is satisfied by precisely those permutations that map
#! <A>object1</A> to <A>object2</A> under <A>action</A>,
#! i.e. all permutations `g` such that
#! `<A>action</A>(<A>object1</A>,g)=<A>object2</A>`.
#! @InsertChunk maybeinfinite
#!
#! The combinations of objects and actions that are supported by
#! `VoleCon.Transport` are given in the table below.
#!
#! @InsertChunk DefaultAction
#!
#! @InsertChunk ActionsTable
#! @BeginExampleSession
#! gap> setofsets1 := [[1, 3, 6], [2, 3, 6], [2, 4, 7], [4, 5, 7]];;
#! gap> setofsets2 := [[1, 2, 5], [1, 5, 7], [3, 4, 6], [4, 6, 7]];;
#! gap> con := VoleCon.Transport(setofsets1, setofsets2, OnSetsSets);;
#! gap> VoleFind.Rep(con);
#! (1,2,7,6)(3,5)
#! gap> VoleFind.Rep(con, AlternatingGroup(7) * (1,2));
#! (1,2,7,6,5,3)
#! gap> VoleFind.Rep(con, DihedralGroup(IsPermGroup, 14));
#! fail
#! @EndExampleSession
DeclareGlobalFunction("VoleCon.Transport");


#! @BeginGroup NormaliseDoc
#! @Arguments G
#! @Returns A constraint
#! @Description
#! This constraint is satisfied by precisely those permutations that
#! normalise the permutation group <A>G</A>,
#! i.e. that preserve <A>G</A> under conjugation.
#!
#! @InsertChunk isinfinite
DeclareGlobalFunction("VoleCon.Normalise");
#! @EndGroup
#! @Arguments G
#! @Group NormaliseDoc
#! @BeginExampleSession
#! gap> con := VoleCon.Normalise(PSL(2,5));;
#! gap> N := VoleFind.Group(con, SymmetricGroup(6));
#! Group([ (3,4,5,6), (2,3,5,6), (1,2,4,3,6) ])
#! gap> (3,4,5,6) in N and not (3,4,5,6) in PSL(2,5);
#! true
#! gap> Index(N, PSL(2,5));
#! 2
#! gap> PSL(2,5) = VoleFind.Group(con, AlternatingGroup(6));
#! true
#! @EndExampleSession
DeclareGlobalFunction("VoleCon.Normalize");


#! @BeginGroup CentraliseDoc
#! @Arguments G
#! @Returns A constraint
#! @Description
#! This constraint is satisfied by precisely those permutations that
#! commute with <A>G</A>, if <A>G</A> is a permutation, or that
#! commute with every element of <A>G</A>, if <A>G</A> is a permutation group.
#!
#! @InsertChunk isinfinite
DeclareGlobalFunction("VoleCon.Centralise");
#! @EndGroup
#! @Arguments G
#! @Group CentraliseDoc
#! @BeginExampleSession
#! gap> D12 := DihedralGroup(IsPermGroup, 12);;
#! gap> VoleFind.Group(6, VoleCon.Centralise(D12));
#! Group([ (1,4)(2,5)(3,6) ])
#! gap> x := (1,6)(2,5)(3,4);;
#! gap> G := VoleFind.Group(AlternatingGroup(6), VoleCon.Centralise(x));
#! Group([ (2,3)(4,5), (2,4)(3,5), (1,2,3)(4,6,5) ])
#! gap> ForAll(G, g -> SignPerm(g) = 1 and g * x = x * g);
#! true
#! @EndExampleSession
DeclareGlobalFunction("VoleCon.Centralize");


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
#! `VoleCon.Transport(<A>x</A>,<A>y</A>,OnPoints)`.
#!
#! **Warning**: this is not yet implemented for permutation groups, sorry.
#! @BeginExampleSession
#! gap> con := VoleCon.Conjugate((3,4)(2,5,1), (1,2,3)(4,5));;
#! gap> VoleFind.Rep(con);
#! (1,2,3,5)
#! gap> VoleFind.Rep(con, PSL(2,5));
#! (1,3,4,5,2)
#! @EndExampleSession
DeclareGlobalFunction("VoleCon.Conjugate");


#! @Arguments pointlist
#! @Returns A constraint
#! @Description
#! This constraint is a shorthand for
#! `VoleCon.InGroup(SymmetricGroup(<A>pointlist</A>))`.
#! See <Ref Func="VoleCon.InGroup"/>.
#! @BeginExampleSession
#! gap> con1 := VoleCon.MovedPoints([1..5]);;
#! gap> con2 := VoleCon.MovedPoints([2,6,4,5]);;
#! gap> VoleFind.Group(con1, con2) = SymmetricGroup([2,4,5]);
#! true
#! @EndExampleSession
DeclareGlobalFunction("VoleCon.MovedPoints");


#! @Arguments point
#! @Returns A constraint
#! @Description
#! This constraint is a shorthand for
#! `VoleCon.InGroup(SymmetricGroup(<A>point</A>))`.
#! See <Ref Func="VoleCon.InGroup"/>.
#! @BeginExampleSession
#! gap> con := VoleCon.LargestMovedPoint(5);;
#! gap> VoleFind.Group(con) = SymmetricGroup(5);
#! true
#! @EndExampleSession
DeclareGlobalFunction("VoleCon.LargestMovedPoint");


#! @Arguments
#! @Returns <K>fail</K>
#! @Description
#! This constraint is satisfied by no permutations.
#!
#! This constraint will typically not be required by the typical user.
#! @BeginExampleSession
#! gap> VoleFind.Rep(VoleCon.None());
#! fail
#! @EndExampleSession
DeclareGlobalFunction("VoleCon.None");


#! @Section Bounds associated with a constraint or refiner
#! @SectionLabel bounds

#! In &GAP;, permutations are defined on the set of all positive
#! integers (although each permutation may only move a finite set of points,
#! and there is a system-dependent maximum point that is allowed to be moved).
#!
#! &Vole; can only search within a concrete finite symmetric group.
#! Therefore, when giving &Vole; a collection of constraints that define a
#! search problem, the search space must be bounded.
#! More specifically, &Vole; must be easily able to deduce a positive integer
#! `k` such that the whole search can take place within `Sym([1..k])`.
#! This guarantees that &Vole; will terminate (given sufficient resources).
#!
#! To help &Vole; make such a deduction, each constraint and refiner,
#! is associated with the following values:
#! a **largest moved point**, and a **largest required point**.
#!
#! Any call to <Ref Func="VoleFind.Group"/> or <Ref Func="VoleFind.Coset"/>
#! requires at least one constraint that defines a **finite** largest moved
#! point, and any call to <Ref Func="VoleFind.Representative"/> requires at
#! least one constraint that defines a finite largest required point
#! or a finite largest moved point.
#!
#! <B>Largest moved point</B>
#!
#! The largest **moved** point of a constraint is either <K>infinity</K>,
#! or a positive integer `k` for
#! which it is known a priori that any permutation satisfying the
#! constraint fixes all points strictly greater than `k`.
#!
#! For example, the largest moved point of the constraint
#! `VoleCon.InGroup(G)` is `LargestMovedPoint(G)`, see
#! <Ref Attr="LargestMovedPoint" BookName="Ref" Style="Number"
#!      Label="for a list or collection of permutations"/>.
#! On the other hand, for any point `k`,
#! the hypothetical constraint “is an even permutation”
#! can be satisfied by some permutation that moves `k+1`, and so the largest
#! moved point of such a constraint would have to be <K>infinity</K>.
#!
#! <B>Largest required point</B>
#!
#! The largest **required** point of a constraint is either
#! <K>infinity</K>, or a positive integer `k` such that there exists a
#! permutation satisfying the constraint if and only if there exists a
#! permutation in `Sym([1..k])` satisfying the constraint.
#!
#! For example, if `set` is a set of positive integers, then the largest
#! required point of the constraint `VoleCon.Stabilise(set, OnSets)` is
#! `Maximum(set)`.
