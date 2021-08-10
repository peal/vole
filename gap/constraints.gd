# Vole: Backtrack search in permutation groups with graphs
# A GAP package by Mun See Chang, Christopher Jefferson, and Wilf A. Wilson.
#
# SPDX-License-Identifier: MPL-2.0
#
# Declarations: Vole constraints


#! @BeginChunk maybeinfinite
#! Note that the set of such permutations may be infinite.
#! @EndChunk

#! @BeginChunk isinfinite
#! Note that the set of such permutations is infinite.
#! @EndChunk


#! @Chapter Constraints

#! @Section The concept of constraints
#! @SectionLabel concept

#! A <E>constraint</E> is a property of individual permutations.
#!
#! such that for any individual permutation, it is possible to answer
#!
#! Constraints and refiners are kind of two names for the same things.
#! Well, depending on your definitions.
#!
#! When solving a problem, a 'constraint' will be mapped into one or more
#! low-level 'refiners'.
#!
#! The choice of refiner(s) can vary depending on the
#! input, and may be changed between versions of Vole as better refiners are
#! created.
#!
#! A constraint is a property that you can say whether or not any individual
#! given permutation has that property.


#! @Section The <C>VoleCon</C> record
#! @SectionLabel VoleCon

#! @Description
#!
#! `VoleCon` is a record that contains all of the constraints that &Vole;
#! provides.
#!
#! These constraints are documented in
#! Section&nbsp;<Ref Sect="Section_providedcons"/>.
#! @BeginExampleSession
#! gap> LoadPackage("vole", false);;
#! gap> Set(RecNames(VoleCon));
#! [ "Centralise", "Centralize", "InCoset", "InGroup", "InLeftCoset", 
#!   "InRightCoset", "LargestMovedPoint", "MovedPoints", "Normalise", 
#!   "Normalize", "Stabilise", "Stabilize", "Transport" ]
#!  @EndExampleSession
DeclareGlobalVariable("VoleCon");
# TODO When we require GAP >= 4.12, use GlobalName rather than GlobalVariable
InstallValue(VoleCon, rec());


#! @Section Constraints provided in the <C>VoleCon</C> record
#! @SectionLabel providedcons

#! Some text, explaining the following table.

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
#!     <Ref Func="VoleCon.InLeftCoset"/>
#!     <P/>
#!     <Ref Func="VoleCon.InRightCoset"/>
#!   </Item>
#! </Row>
#! <Row>
#!   <Item>
#!     <Ref Func="VoleCon.Stabilize"/>
#!   </Item>
#!   <Item><Ref Func="VoleCon.Transport"/></Item>
#! </Row>
#! <Row>
#!   <Item>
#!     <Ref Func="VoleCon.Normalize"/>
#!   </Item>
#!   <Item>
#!     <Ref Func="VoleCon.Conjugate"/>
#!   </Item>
#! </Row>
#! <Row>
#!   <Item>
#!     <Ref Func="VoleCon.Centralize"/>
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
#! </Table>

#! Perhaps some final text?


#! @Arguments G
#! @Returns A constraint
#! @Description
#! This constraint is satisfied by precisely those permutations in the
#! group <A>G</A>.
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
#! gap> true;
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
#! gap> true;
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
#! gap> true;
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
#! gap> true;
#! true
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
#! gap> true;
#! true
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
#! gap> true;
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
#! gap> true;
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
#! @BeginExampleSession
#! gap> true;
#! true
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


#! @Section Bounds associated with a constraint or refiner
#! @SectionLabel bounds

#! In &GAP;, all permutations are implicitly defined on the set of all positive
#! integers, although there are limits on the points that can be involved that
#! are prescribed by the computer and the laws of physics.
#! Finite support.
#!
#! But there's a potential for danger here with (nearly) infinite stuff.
#! So we need to bound the search somehow.
#! We want to be doing stuff with finite groups.
#! We actually want to do a search in Sym([1..k]) for some posint `k`,
#! or even in Sym(C) for some finite subset of `PositiveIntegers`.
#!
#! <B>Largest required point</B>
#!
#! The largest required point of a 'constraint' is either
#! <K>infinity</K>, or a positive integer `k` such that for any permutation `x`:
#! * `x` satisfies the constraint if and only if
#!   `x` preserves `[1..k]` as a set, and the restriction of `x` to `[1..k]`
#!   satisfies the constraint.
#!
#! The constraint only concerns (at most) the points [1..k], and that the action
#! of a permutation on the points greater than `k` is irrelevant to whether the
#! constraint is satisfied.
#!
#! In particular, there exists some permutation that satisfies the constraint
#! if and only if there exists a permutation in Sym([1..k]) that satisfies
#! the constraint. This also a search for a representative
#!
#! <B>Largest moved point</B>
#!
#! The largest moved point is either <K>infinity</K>,
#! or a positive integer `m` for
#! which it is known a priori that any permutation satisfying the
#! 'constraint' fixes all points > `m`.
#! For many 'constraints' there is no such bound, or at least none can be easily
#! deduced. For instance, the constraint "is even" can be satisfied by
#! some permutation that moves any given point.
