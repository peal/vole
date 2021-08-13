# Vole: Backtrack search in permutation groups with graphs
# A GAP package by Mun See Chang, Christopher Jefferson, and Wilf A. Wilson.
#
# SPDX-License-Identifier: MPL-2.0
#
# Declarations: Wrappers for Vole functions that emulate GAP/images/Digraphs

#! @Chunk better
#! It may be possible to obtain better performance from &Vole; by
#! specifying custom refiners with the native interface, see
#! @EndChunk

#! @Chunk refiner-chapref
#! and Chapter&nbsp;<Ref Chap="Chapter_Refiners"/>.
#! @EndChunk

#! @Chunk bettergroup
#! @InsertChunk better
#! <Ref Func="VoleFind.Group"/>
#! @InsertChunk refiner-chapref
#! @EndChunk

#! @Chunk betterrep
#! @InsertChunk better
#! <Ref Func="VoleFind.Rep"/>
#! @InsertChunk refiner-chapref
#! @EndChunk

#! @Chunk bettercanonical
#! @InsertChunk better
#! <Ref Func="VoleFind.Canonical"/>
#! @InsertChunk refiner-chapref
#! @EndChunk

#! @Chunk betterall
#! @InsertChunk better
#! Chapter&nbsp;<Ref Chap="Chapter_interface"/>
#! @InsertChunk refiner-chapref
#! @EndChunk

#! @BeginChunk DefaultAction
#! The default <A>action</A>, in the case that the argument is not given, is
#! <Ref Func="OnPoints" BookName="Ref"/>.
#! This is the name in &GAP; of the action given by the `^` operator,
#! i.e. it corresponds to `<A>object</A>^g`, where `g` in <A>G</A>.
#! See <Ref Oper="\^" BookName="Ref"/>.
#! @EndChunk

#! @BeginChunk gap-faster
#! There are many reasons why &GAP; may be faster than &Vole; for any
#! particular problem; see Section&nbsp;<Ref Sect="Section_performance"/>
#! for some discussion about this.
#! @EndChunk

#! @BeginChunk AvailableActions
#! The permitted combinations of objects and actions are given in the table
#! below.
#! @EndChunk

#! @BeginChunk ActionsTable
#! <Table Align="ll">
#! <Row>
#!   <Item><B>Permitted action</B></Item>
#!   <Item><B>Corresponding object/pair of objects</B></Item>
#! </Row>
#! <HorLine/>
#! <Row>
#!   <Item>
#!     <Ref Func="OnPoints" Style="Number" BookName="Ref"/> [default]
#!   </Item>
#!   <Item>
#!     A positive integer, permutation, or perm group
#!   </Item>
#! </Row>
#! <Row>
#!   <Item>
#!     <Ref Func="OnTuples" Style="Number" BookName="Ref"/>
#!   </Item>
#!   <Item>
#!     A list of positive integers
#!   </Item>
#! </Row>
#! <Row>
#!   <Item>
#!     <Ref Func="OnSets" Style="Number" BookName="Ref"/>
#!   </Item>
#!   <Item>
#!     A set of positive integers
#!   </Item>
#! </Row>
#! <Row>
#!   <Item>
#!     <Ref Func="OnSetsSets" Style="Number" BookName="Ref"/>
#!   </Item>
#!   <Item>
#!     A set of sets of positive integers
#!   </Item>
#! </Row>
#! <Row>
#!   <Item>
#!     <Ref Func="OnSetsTuples" Style="Number" BookName="Ref"/>
#!   </Item>
#!   <Item>
#!     A set of lists of positive integers
#!   </Item>
#! </Row>
#! <Row>
#!   <Item>
#!     <Ref Func="OnTuplesSets" Style="Number" BookName="Ref"/>
#!   </Item>
#!   <Item>
#!     A list of sets of positive integers
#!   </Item>
#! </Row>
#! <Row>
#!   <Item>
#!     <Ref Func="OnTuplesTuples" Style="Number" BookName="Ref"/>
#!   </Item>
#!   <Item>
#!     A list of lists of positive integers
#!   </Item>
#! </Row>
#! <Row>
#!   <Item>
#!     <Ref Oper="OnDigraphs" BookName="Digraphs" Style="Number" Label="for a digraph and a perm"/>
#!   </Item>
#!   <Item>
#!     A digraph object, or a list of adjacencies
#!   </Item>
#! </Row>
#! </Table>
#! @EndChunk


#! @Chapter Emulating traditional interfaces with &Vole;
#! @ChapterLabel wrapper


#! @Section The concept

#! The functionality of &Vole; overlaps with that of &GAP; and its
#! other packages, such as &images; and &Digraphs;.
#!
#! &Vole; has its own native interface, which is described in
#! Chapter&nbsp;<Ref Chap="Chapter_interface"/>, and which offers
#! highly configurable access to the underlying graph backtracking algorithm.
#! This is the recommended interface to &Vole; for most users.
#!
#! However, &Vole; also provides wrappers around its native
#! interface that allow &Vole; to emulate some existing interfaces.
#! The purpose of these wrappers is to lower the ‘barrier to entry’ of &Vole;,
#! so that users who are already familiar with the existing &GAP;/package
#! functions can quickly get started with &Vole;.
#!
#! Where we identify that &GAP;, or a package, provides a function whose result
#! could reasonably be computed with &Vole;,
#! we provide a wrapper function whose interface closely
#! matches that of the original function, but which uses &Vole;
#! to perform the computation.
#! <B>We do not claim that the</B>
#! &Vole;
#! <B>wrapper functions are necesarily faster than the original functions</B>;
#! see Section&nbsp;<Ref Sect="Subsection_warning"/>.
#!
#! For example,
#! the &GAP; function <Ref Oper="Normaliser" Style="Number" BookName="Ref"/> can
#! be used to compute normalisers of permutation groups.
#! Since &Vole; can also be used for such computations,
#! we provide the corresponding function
#! <Ref Func="Vole.Normaliser"/>, which can be used in the same way.
#! Thus `Normaliser(<A>G</A>,<A>U</A>)` and `Vole.Normaliser(<A>G</A>,<A>U</A>)`
#! will (barring bugs!)
#! return equal groups for
#! all permutation groups <A>G</A> and <A>U</A>.
#!
#! All such functions are contained in the
#! <Ref Var="Vole"/> record, which is documented
#! in Section&nbsp;<Ref Sect="Section_VoleRec"/>.
#! The functions themselves are individually documented in
#! Sections&nbsp;<Ref Sect="Section_gap_wrapper"/>–<Ref
#!   Sect="Section_digraphs_wrapper"/>.
#!
#! @Subsection A warning
#! @SubsectionLabel warning
#!
#! &Vole;'s emulated interfaces do not necessarily exhibit the full flexibility,
#! power, and speed of &Vole;.
#! This is especially for those users who are interesting in controlling and
#! specifying the refiners that are used in a given search,
#! for whom the native interface (Chapter&nbsp;<Ref Chap="Chapter_interface"/>)
#! is necessary.
#!
#! In addition, please note that the &Vole; wrapper functions
#! (almost) always use the graph backtracking algorithm,
#! and so they may be significantly slower than the
#! corresponding original functions when those functions can cleverly simplify
#! the problem (and perhaps even choose a completely different algorithm),
#! based on the properties of the groups and permutations that are involved.
#!
#! See Section&nbsp;<Ref Sect="Section_performance"/> for further
#! comments about the relative performance of &Vole; in comparison to other
#! tools.


#! @Section The <C>Vole</C> record
#! @SectionLabel VoleRec

#! @Description
#!
#! `Vole` is a record that contains all of the &Vole; wrapper functions
#! that are provided to emulate aspects of &GAP;, and its packages
#! &images; and &Digraphs;.
#! The components of this record are functions that are named to coincide
#! with the corresponding &GAP;/&images;/&Digraphs; functions.
#!
#! For example, 
#! <Ref Func="Vole.Normaliser"/>
#! emulates <Ref Oper="Normaliser" Style="Number" BookName="Ref"/>.
#!
#! @BeginExampleSession
#! gap> LoadPackage("vole", false);;
#! gap> Set(RecNames(Vole));
#! [ "AutomorphismGroup", "CanonicalDigraph", "CanonicalImage", 
#!   "CanonicalImagePerm", "CanonicalPerm", "Centraliser", "Centralizer", 
#!   "DigraphCanonicalLabelling", "Intersection", "IsConjugate", "Normaliser", 
#!   "Normalizer", "RepresentativeAction", "Stabiliser", "Stabilizer", 
#!   "TwoClosure" ]
#! @EndExampleSession
DeclareGlobalVariable("Vole");
# TODO When we require GAP >= 4.12, use GlobalName rather than GlobalVariable
InstallValue(Vole, rec());


#! @Section The group actions built into &Vole;

#! The supported combinations of objects and actions are the same for the
#! functions in this chapter that require one or two objects, and a
#! corresponding action.
#! This information is shown in the following table and applies, in particular,
#! to:
#! * <Ref Func="Vole.Stabiliser"/>
#! * <Ref Func="Vole.RepresentativeAction"/>
#! * <Ref Func="Vole.CanonicalPerm"/>
#! * <Ref Func="Vole.CanonicalImage"/>
#!
#! @InsertChunk ActionsTable


#! @Section &Vole; functions emulating built-in &GAP; functions
#! @SectionLabel gap_wrapper

#! The following table gives a summary of the
#! &Vole; wrapper functions and the corresponding &GAP; functions.

#! <Table Align="ll">
#! <Row>
#!   <Item>&Vole; function</Item>
#!   <Item>Built-in &GAP; function</Item>
#! </Row>
#! <HorLine/>
#! <Row>
#!   <Item>
#!     <Ref Func="Vole.Intersection"/>
#!   </Item>
#!   <Item>
#!     <Ref Oper="Intersection" BookName="Ref" Style="Number" />
#!   </Item>
#! </Row>
#! <Row>
#!   <Item>
#!     <Ref Func="Vole.Stabiliser"/>
#!   </Item>
#!   <Item>
#!     <Ref Oper="Stabiliser" BookName="Ref" Style="Number" />
#!   </Item>
#! </Row>
#! <Row>
#!   <Item>
#!     <Ref Func="Vole.RepresentativeAction"/>
#!   </Item>
#!   <Item>
#!     <Ref Oper="RepresentativeAction" BookName="Ref" Style="Number" />
#!   </Item>
#! </Row>
#! <Row>
#!   <Item>
#!     <Ref Func="Vole.Normaliser"/>
#!   </Item>
#!   <Item>
#!     <Ref Oper="Normaliser" BookName="Ref" Style="Number" />
#!   </Item>
#! </Row>
#! <Row>
#!   <Item>
#!     <Ref Func="Vole.Centraliser"/>
#!   </Item>
#!   <Item>
#!     <Ref Oper="Centraliser" BookName="Ref" Style="Number" />
#!   </Item>
#! </Row>
#! <Row>
#!   <Item>
#!     <Ref Func="Vole.IsConjugate"/>
#!   </Item>
#!   <Item>
#!     <Ref Oper="IsConjugate" BookName="Ref" Style="Number" />
#!   </Item>
#! </Row>
#! <Row>
#!   <Item>
#!     <Ref Func="Vole.TwoClosure"/>
#!   </Item>
#!   <Item>
#!     <Ref Attr="TwoClosure" BookName="Ref" Style="Number" />
#!   </Item>
#! </Row>
#! </Table>


#! @BeginGroup Intersection
#! @GroupTitle Intersection
#! @Arguments U1, U2, ..., Uk
#! @Returns A perm group, a right coset, or an empty list
#! @Description
#! <Ref Func="Vole.Intersection"/> emulates the built-in &GAP; operation
#! <Ref Oper="Intersection" BookName="Ref" Style="Number" />,
#! and returns the intersection of the groups and/or right coset arguments.
#!
#! If all of the arguments are groups, then <Ref Func="Vole.Intersection"/>
#! again returns a group.
#! Otherwise, if the result is nonempty, then <Ref Func="Vole.Intersection"/>
#! returns a &GAP; right coset object.
#! Note that this non-group case differs from &GAP;'s
#! <Ref Oper="Intersection" BookName="Ref" Style="Number" />,
#! which always returns a list.
#!
#! Note that &Vole; performs the whole intersection in one search,
#! rather than iteratively intersecting the arguments.
#!
#! @InsertChunk gap-faster
#! @InsertChunk betterall
#! @BeginExampleSession
#! gap> A6 := AlternatingGroup(6);;
#! gap> D12 := DihedralGroup(IsPermGroup, 12);;
#! gap> Vole.Intersection(A6, D12);
#! Group([ (2,6)(3,5), (1,3,5)(2,4,6) ])
#! gap> Vole.Intersection(A6 * (1,2), D12 * (3,4));
#! RightCoset(Group([ (2,6)(3,5), (1,3,5)(2,4,6) ]),(1,5)(2,3,4))
#! gap> Vole.Intersection(A6 * (1,2), D12 * (3,4), PSL(2,5));
#! [  ]
#! @EndExampleSession
DeclareGlobalFunction("Vole.Intersection");
#! @EndGroup


#! @BeginGroup Stab
#! @GroupTitle Stabiliser
#! @Arguments G, object[, action]
#! @Returns An permutation group
#! @Description
#! <Ref Func="Vole.Stabiliser"/> emulates the built-in &GAP; operation
#! <Ref Oper="Stabiliser" BookName="Ref" Style="Number"/>.
#!
#! The **stabiliser** of an <A>object</A> in a group <A>G</A>
#! under some group <A>action</A> is the subgroup of <A>G</A> of those
#! elements that fix <A>object</A> under <A>action</A>,
#! i.e. all permutations `g` in <A>G</A> such that
#! `<A>action</A>(<A>object</A>,g)=<A>object</A>`.
#!
#! @InsertChunk AvailableActions
#!
#! @InsertChunk DefaultAction
#!
#! @InsertChunk gap-faster
#! @InsertChunk bettergroup
DeclareGlobalFunction("Vole.Stabiliser");
#! @EndGroup
#! @Arguments G, object[, action]
#! @Group Stab
#! @BeginExampleSession
#! gap> Vole.Stabiliser(PGL(2,5), [1,2,3], OnSets);
#! Group([ (1,3)(5,6), (1,2,3)(4,5,6) ])
#! gap> D := JohnsonDigraph(4,2);;
#! gap> G := Stabiliser(PSL(2,5), D, OnDigraphs);;
#! gap> G = Group([ (1,4,5)(2,6,3), (1,4)(3,6) ]);
#! true
#! gap> Elements(G)
#! >  = SortedList(Filtered(PSL(2,5), g -> OnDigraphs(D, g) = D));
#! true
#! @EndExampleSession
#! @InsertChunk ActionsTable
DeclareGlobalFunction("Vole.Stabilizer");


#! @BeginGroup RepAction
#! @GroupTitle RepresentativeAction
#! @Arguments G, object1, object2[, action]
#! @Returns A permutation, or <K>fail</K>
#! @Description
#!
#! <Ref Func="Vole.RepresentativeAction"/> emulates the built-in &GAP; function
#! <Ref Oper="RepresentativeAction" BookName="Ref" Style="Number"/>.
#!
#! This function returns an element of the permutation group <A>G</A>
#! that maps <A>object1</A> to <A>object2</A> under the given group
#! <A>action</A>, if such an element exists,
#! and it returns <K>fail</K> otherwise.
#!
#! @InsertChunk AvailableActions
#!
#! @InsertChunk DefaultAction
#!
#! @InsertChunk gap-faster
#! @InsertChunk betterrep
#!
#! @BeginExampleSession
#! gap> Vole.RepresentativeAction(SymmetricGroup(4), (1,2,3), (1,2,4));
#! (1,4,3,2)
#! gap> RepresentativeAction(AlternatingGroup(4), (1,2,3), (1,2,4));
#! fail
#! gap> D := CycleDigraph(6);;
#! gap> Vole.RepresentativeAction(PGL(2,5), D, DigraphReverse(D), OnDigraphs);
#! (1,4)(2,3)(5,6)
#! @EndExampleSession
#! @InsertChunk ActionsTable
DeclareGlobalFunction("Vole.RepresentativeAction");
#! @EndGroup


#! @BeginGroup Norm
#! @GroupTitle Normaliser
#! @Arguments G, U
#! @Returns An permutation group
#! @Description
#! <Ref Func="Vole.Normaliser"/> emulates the built-in &GAP; operation
#! <Ref Oper="Normaliser" BookName="Ref" Style="Number"/>.
#!
#! If <A>G</A> and <A>U</A> are permutation groups, then
#! this function returns the **normaliser** of <A>U</A> in <A>G</A>,
#! $N_{G}(U)$,
#! which is the stabiliser of <A>U</A> under conjugation by <A>G</A>.
#! If <A>U</A> is instead a permutation, then
#! `Vole.Normalizer(<A>G</A>,<A>U</A>)` returns $N_{G}(\langle U \rangle)$.
#!
#! @InsertChunk gap-faster
#! @InsertChunk bettergroup
DeclareGlobalFunction("Vole.Normaliser");
#! @EndGroup
#! @Arguments G, U
#! @Group Norm
#! @BeginExampleSession
#! gap> Vole.Normaliser(SymmetricGroup(6), PSL(2,5)) = PGL(2,5);
#! true
#! gap> D12 := DihedralGroup(IsPermGroup, 12);;
#! gap> Vole.Normaliser(SymmetricGroup(6), (1,2,3,4,5,6)) = D12;
#! true
#! @EndExampleSession
DeclareGlobalFunction("Vole.Normalizer");


#! @BeginGroup Cent
#! @GroupTitle Centraliser
#! @Arguments G, x
#! @Returns An permutation group
#! @Description
#! <Ref Func="Vole.Centraliser"/> emulates the built-in &GAP; operation
#! <Ref Oper="Centraliser" BookName="Ref" Style="Number"/>.
#!
#! If <A>G</A> is a group and <A>x</A> is a permutation, then
#! this function returns the subgroup of <A>G</A> comprising its elements
#! that commute with <A>x</A>.
#!
#! If instead <A>x</A> is group, then this function returns the subgroup
#! of <A>G</A> comprising its elements that commute with all elements
#! of <A>x</A>.
DeclareGlobalFunction("Vole.Centraliser");
#! @EndGroup
#! @Arguments G, x
#! @Group Cent
#! @BeginExampleSession
#! gap> Vole.Centraliser(MathieuGroup(12), (1,11,9,4,3,2)(5,7,8,6,12,10));
#! Group([ (1,2,3,4,9,11)(5,10,12,6,8,7), (1,5,3,12,9,8)(2,10,4,6,11,7) ])
#! gap> Vole.Centraliser(Group((1,2,3,4,5,6)), DihedralGroup(IsPermGroup, 12));
#! Group([ (1,4)(2,5)(3,6) ])
#! @EndExampleSession
DeclareGlobalFunction("Vole.Centralizer");


#! @BeginGroup IsConj
#! @GroupTitle IsConjugate
#! @Arguments G, x, y
#! @Returns <K>true</K> or <K>false</K>
#! @Description
#! <Ref Func="Vole.IsConjugate"/> emulates the built-in &GAP; function
#! <Ref Oper="IsConjugate" BookName="Ref" Style="Number"/>.
#!
#! This function returns <K>true</K> if there exists an element
#! of the permutation group <A>G</A> that conjugates <A>x</A> to <A>y</A>,
#! and <K>false</K> otherwise,
#! where <A>x</A> and <A>y</A> are either both permutations,
#! or both permutation groups.
#! Note that <A>x</A> and <A>y</A> are not required to be contained in <A>G</A>.
#!
#! This function immediately delegates to
#! <Ref Func="Vole.RepresentativeAction"/>, which finds a representative
#! conjugating element, or proves that none exists.
#!
#! @InsertChunk gap-faster
#! @InsertChunk betterrep
#!
#! Conjugacy of permutations:
#! @BeginExampleSession
#! gap> # Conjugacy of permutations
#! gap> x := (1,2,3,4,5);; y := (1,2,3,4,6);;
#! gap> Vole.IsConjugate(SymmetricGroup(6), x, y);
#! true
#! gap> Vole.IsConjugate(AlternatingGroup(6), x, y);
#! false
#! gap> Vole.IsConjugate(Group([ (5,6) ]), x, y);
#! true
#! @EndExampleSession
#! Conjugacy of groups:
#! @BeginExampleSession
#! gap> x := Group([ (1,2,3,4,5) ]);;
#! gap> y := Group([ (1,2,3,4,6) ]);;
#! gap> Vole.IsConjugate(SymmetricGroup(6), x, y);
#! true
#! gap> Vole.IsConjugate(Group([ (1,2)(3,4) ]), x, y);
#! false
#! gap> Vole.IsConjugate(Group([ (5,6) ]), x, y);
#! true
#! @EndExampleSession
DeclareGlobalFunction("Vole.IsConjugate");
#! @EndGroup


#! @BeginGroup TwoClosure
#! @GroupTitle TwoClosure
#! @Arguments G
#! @Returns A permutation group
#! @Description
#! <Ref Func="Vole.TwoClosure"/> emulates the built-in &GAP; function
#! <Ref Attr="TwoClosure" BookName="Ref" Style="Number"/>
#! for a permutation group.
#!
#! The **2-closure** of a permutation group <A>G</A> is the largest group
#! whose orbitals (orbits on pairs of positive integers) coincide with those
#! of <A>G</A>;
#! equivalently, it is the intersection of the automorphism groups of the
#! orbital graphs of <A>G</A>.
#!
#! <B>Warning</B>: this function currently requires the &OrbitalGraphs;
#! package, and it will give an error if &OrbitalGraphs; is not yet loaded.
#! 
#! @BeginExampleSession
#! gap> LoadPackage("orbitalgraphs", false);;
#! gap> G := Group([ (1,4)(2,5), (1,3,5)(2,4,6) ]);;  # A4 on six points
#! gap> (3,6) in G;
#! false
#! gap> Vole.TwoClosure(G) = ClosureGroup(G, (3,6));
#! true
#! @EndExampleSession
DeclareGlobalFunction("Vole.TwoClosure");
#! @EndGroup


#! @Section &Vole; functions emulating the &images; package
#! @SectionLabel images_wrapper

#! The following table gives a summary of the correspondence between &Vole; and
#! the &images; package.

#! <Table Align="ll">
#! <Row>
#!   <Item>&Vole; function</Item>
#!   <Item>&images; package function</Item>
#! </Row>
#! <HorLine/>
#! <Row>
#!   <Item>
#!     <Ref Func="Vole.CanonicalPerm"/>
#!   </Item>
#!   <Item>
#!     <Ref Func="CanonicalImagePerm" BookName="images" Style="Number" />
#!   </Item>
#! </Row>
#! <Row>
#!   <Item>
#!     <Ref Func="Vole.CanonicalImage"/>
#!   </Item>
#!   <Item>
#!     <Ref Func="CanonicalImage" BookName="images" Style="Number" />
#!   </Item>
#! </Row>
#! </Table>


#! @BeginGroup CanonicalPerm
#! @GroupTitle CanonicalPerm
#! @Arguments G, object[, action]
#! @Returns A permutation
#! @Description
#! This function emulates <Ref Func="CanonicalImagePerm" BookName="images" Style="Number" />
#! from the &images; package,
#! although it supports a wider range of objects and actions.
#!
#! Text about `Vole.CanonicalPerm`...
#!
#! @InsertChunk AvailableActions
#!
#! @InsertChunk DefaultAction
#!
#! <Ref Func="VoleFind.CanonicalPerm"/>
#!
#! @InsertChunk canonical-warning-session
#! @EndGroup
DeclareGlobalFunction("Vole.CanonicalPerm");
#! @Arguments G, object[, action]
#! @Group CanonicalPerm

#! @BeginExampleSession
#! gap> true;
#! true
#! @EndExampleSession
#! @InsertChunk ActionsTable
DeclareGlobalFunction("Vole.CanonicalImagePerm");


#! @BeginGroup CanonicalImage
#! @GroupTitle CanonicalImage
#! @Arguments G, object[, action]
#! @Returns An image of <A>object</A>
#! @Description
#! This function emulates
#! <Ref Func="CanonicalImage" BookName="images" Style="Number" />
#! from the &images; package,
#! although it supports a wider range of objects and actions.
#!
#! Text about `Vole.CanonicalImage`...
#!
#! @InsertChunk AvailableActions
#!
#! @InsertChunk DefaultAction
#!
#! <Ref Func="VoleFind.CanonicalPerm"/>
#!
#! @InsertChunk canonical-warning-session

#! @BeginExampleSession
#! gap> true;
#! true
#! @EndExampleSession
#! @InsertChunk ActionsTable
DeclareGlobalFunction("Vole.CanonicalImage");
#! @EndGroup


#! @Section &Vole; functions emulating the &Digraphs; package
#! @SectionLabel digraphs_wrapper

#! The following table gives a summary of the correspondence between &Vole; and
#! the &Digraphs; package.

#! <Table Align="ll">
#! <Row>
#!   <Item>&Vole; function</Item>
#!   <Item>&Digraphs; package function</Item>
#! </Row>
#! <HorLine/>
#! <Row>
#!   <Item>
#!     <Ref Func="Vole.AutomorphismGroup"/>
#!   </Item>
#!   <Item>
#!     <Ref Func="AutomorphismGroup" BookName="Digraphs" Style="Number" />
#!
#!     <Ref Attr="NautyAutomorphismGroup" BookName="Digraphs" Style="Number" />
#!
#!     <Ref Attr="BlissAutomorphismGroup" BookName="Digraphs" Style="Number" />
#!   </Item>
#! </Row>
#! <Row>
#!   <Item>
#!     <Ref Func="Vole.CanonicalDigraph"/>
#!   </Item>
#!   <Item>
#!     <Ref Attr="NautyCanonicalDigraph" BookName="Digraphs" Style="Number" />
#!
#!     <Ref Attr="BlissCanonicalDigraph" BookName="Digraphs" Style="Number" />
#!   </Item>
#! </Row>
#! <Row>
#!   <Item>
#!     <Ref Func="Vole.DigraphCanonicalLabelling"/>
#!   </Item>
#!   <Item>
#!     <Ref Attr="NautyCanonicalLabelling" BookName="Digraphs" Style="Number" />
#!
#!     <Ref Attr="BlissCanonicalLabelling" BookName="Digraphs" Style="Number" />
#!   </Item>
#! </Row>
#! </Table>


#! @BeginGroup AutomorphismGroup
#! @GroupTitle AutomorphismGroup
#! @Arguments D[, vert_colours[, edge_colours]]
#! @Returns A permutation group
#! @Description
#! <Ref Func="AutomorphismGroup" BookName="Digraphs" Style="Number" />
#!
#! <Ref Attr="NautyAutomorphismGroup" BookName="Digraphs" Style="Number" />
#!
#! <Ref Attr="BlissAutomorphismGroup" BookName="Digraphs" Style="Number" />
#!
#! TODO
#!
#! <Ref Func="VoleFind.Group"/>
#!
#! @BeginExampleSession
#! gap> true;
#! true
#! @EndExampleSession
DeclareGlobalFunction("Vole.AutomorphismGroup");
#! @EndGroup


#! @BeginGroup CanonicalDigraph
#! @GroupTitle CanonicalDigraph
#! @Arguments D
#! @Returns A digraph
#! @Description
#! <Ref Oper="BlissCanonicalDigraph" BookName="Digraphs" Style="Number" />
#! and
#! <Ref Oper="NautyCanonicalDigraph" BookName="Digraphs" Style="Number" />
#!
#! TODO
#!
#! <Ref Func="VoleFind.CanonicalPerm"/>
#!
#! @InsertChunk canonical-warning-session

#! @BeginExampleSession
#! gap> true;
#! true
#! @EndExampleSession
DeclareGlobalFunction("Vole.CanonicalDigraph");
#! @EndGroup


#! @BeginGroup DigraphCanonicalLabelling
#! @GroupTitle DigraphCanonicalLabelling
#! @Arguments D[, colours]
#! @Returns A permutation
#! @Description
#! <Ref Attr="BlissCanonicalLabelling" BookName="Digraphs" Style="Number" />
#!
#! <Ref Attr="NautyCanonicalLabelling" BookName="Digraphs" Style="Number" />
#!
#! TODO
#!
#! <Ref Func="VoleFind.CanonicalPerm"/>
#!
#! @InsertChunk canonical-warning-session

#! @BeginExampleSession
#! gap> true;
#! true
#! @EndExampleSession
DeclareGlobalFunction("Vole.DigraphCanonicalLabelling");
#! @EndGroup

# TODO warning: canonical images and perms can change!
