# Vole: Backtrack search in permutation groups with graphs
# A GAP package by Mun See Chang, Christopher Jefferson, and Wilf A. Wilson.
#
# SPDX-License-Identifier: MPL-2.0
#
# Declarations: Wrappers for Vole functions that emulate GAP/images/Digraphs

#! @Chunk better
#! Note that it may be possible to obtain better performance from &Vole; with
#! the native interface, see
#! @EndChunk

#! @Chunk bettergroup
#! @InsertChunk better
#! <Ref Func="VoleFind.Group"/>.
#! @EndChunk

#! @Chunk betterrep
#! @InsertChunk better
#! <Ref Func="VoleFind.Rep"/>.
#! @EndChunk

#! @Chunk bettercanonical
#! @InsertChunk better
#! <Ref Func="VoleFind.Canonical"/>.
#! @EndChunk

#! @Chunk betterall
#! @InsertChunk better
#! Chapter&nbsp;<Ref Chap="Chapter_Constraints"/>.
#! @EndChunk

#! @BeginChunk DefaultAction
#! The default <A>action</A>, in the case that the argument is not given, is
#! <Ref Func="OnPoints" BookName="Ref"/>.
#! This is the name in &GAP; of the action given by the `^` operator,
#! i.e. it corresponds to `<A>object</A>^g`, where `g` in <A>G</A>.
#! See <Ref Oper="\^" BookName="Ref"/>.
#! @EndChunk

#! @BeginChunk AvailableActions
#! TODO: some text about which actions &Vole; supports.
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
#! functions can quickly get started.
#!
#! Where we identify that &GAP;, or a package, provides a function whose result
#! could reasonably be computed with &Vole;,
#! we provide a function in &Vole; whose interface closely
#! matches that of the original function, and which uses &Vole; to perform the
#! computation.
#! All such functions are contained in the
#! <Ref Var="Vole"/> record, which is documented
#! in Section&nbsp;<Ref Sect="Section_VoleRec"/>.
#! The functions themselves are individually documented in
#! Sections&nbsp;<Ref Sect="Section_gap_wrapper"/>–<Ref
#!   Sect="Section_digraphs_wrapper"/>.
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
#! <B>A warning</B>
#!
#! These emulated interfaces are not necessarily the best way to use &Vole; for
#! those users who are interesting in obtaining the best performance,
#! and in exploiting the full flexibility of &Vole;.
#!
#! &Vole; has to guess refiners.
#!
#!
#! The built-in &GAP; function is aware of this and it attempts to deal with
#! special case appropriately (and quickly)
#!
#! Note that these functions always use graph backtracking, so may be significantly
#! slower than &GAP;'s built in functions when those functions can greatly
#! simplify solving using group properties.
#!
#! ...perhaps even without seach.
#!
#! See also Section&nbsp;<Ref Sect="Section_performance"/> for further
#! comments about the performance of &Vole;


#! @Section The <C>Vole</C> record
#! @SectionLabel VoleRec

#! @Description
#!
#! `Vole` is a record that contains all of the &Vole; wrapper functions
#! that are provided to emulate aspects of &GAP;, and its packages
#! &images; and &Digraphs;.
#! The components of this record are functions that are named to coincide
#! with the corresponding &GAP;/&images;/&Digraphs; function.
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

# TODO Or should it actually be a "Chunk" that I can insert in multiple places?
# TODO Also OnTuplesSets, OnTuplesTuples, etc?
#! The supported combinations of objects and actions are the same for all of the
#! functions in this chapter that require one or two objects and a corresponding
#! action. This applies here to:
#! * <Ref Func="Vole.Stabiliser"/>
#! * <Ref Func="Vole.RepresentativeAction"/>
#! * <Ref Func="Vole.CanonicalPerm"/>
#! * <Ref Func="Vole.CanonicalImage"/>
#!
#! @InsertChunk ActionsTable


#! @Section &Vole; functions emulating built-in &GAP; functions
#! @SectionLabel gap_wrapper

#! The following table gives a summary of the correspondence between &Vole; and
#! &GAP; functions

#! Some more text, explaining the following table.

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
#! </Table>


#! @BeginGroup Intersection
#! @GroupTitle Intersection
#! @Arguments U1, U2, ..., Uk
#! @Returns A perm group, a right coset, or an empty list
#! @Description
#! <Ref Func="Vole.Intersection"/> emulates the built-in &GAP; operation
#! <Ref Oper="Intersection" BookName="Ref" Style="Number" />.
#!
#! Can be permgroups and/or right cosets.
#!
#! Note that &Vole; is cool because it does all of the intersection
#! simultaneously in one search, rather than iteratively intersecting pairs of
#! things.
#!
#! &GAP; might have some clever special cases that we don't bother with.
#!
#! @InsertChunk betterall
#! @BeginExampleSession
#! gap> true;
#! true
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
#! Text about this.
#!
#! @InsertChunk AvailableActions
#! @InsertChunk DefaultAction
#!
#! @InsertChunk bettergroup
DeclareGlobalFunction("Vole.Stabiliser");
#! @EndGroup
#! @Arguments G, object[, action]
#! @Group Stab
#! @BeginExampleSession
#! gap> true;
#! true
#! @EndExampleSession
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
#! This function returns an element
#! of the permutation group <A>G</A> that maps <A>object1</A> to <A>object2</A>
#! under the given group <A>action</A>, if such an element exists,
#! and it returns <K>fail</K> otherwise.
#!
#! @InsertChunk AvailableActions
#! @InsertChunk DefaultAction
#!
#! @InsertChunk betterrep
#!
#! @BeginExampleSession
#! gap> true;
#! true
#! @EndExampleSession
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
#! this function returns the **normaliser** $N_{G}(U)$ of <A>U</A> in
#! <A>G</A>, which is the stabiliser of <A>U</A> under conjugation by <A>G</A>.
#! If <A>U</A> is instead a permutation, then
#! `Vole.Normalizer(<A>G</A>,<A>U</A>)` returns $N_{G}(\langle U \rangle)$.
#!
#! @InsertChunk bettergroup
DeclareGlobalFunction("Vole.Normaliser");
#! @EndGroup
#! @Arguments G, U
#! @Group Norm
#! @BeginExampleSession
#! gap> true;
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
#! Text about this
DeclareGlobalFunction("Vole.Centraliser");
#! @EndGroup
#! @Arguments G, x
#! @Group Cent
#! @BeginExampleSession
#! gap> true;
#! true
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
#! @InsertChunk betterrep

#! @BeginExampleSession
#! gap> # Conjugacy of permutations
#! gap> x := (1,2,3,4,5);; y := (1,2,3,4,6);;
#! gap> IsConjugate(SymmetricGroup(6), x, y);
#! true
#! gap> IsConjugate(AlternatingGroup(6), x, y);
#! false
#! gap> IsConjugate(Group([ (5,6) ]), x, y);
#! true
#! gap> # Conjugacy of groups
#! @EndExampleSession
DeclareGlobalFunction("Vole.IsConjugate");
#! @EndGroup


# TODO: Also, does it apply to all groups or (like GAP) only to transitive ones?
#! @BeginGroup TwoClosure
#! @GroupTitle TwoClosure
#! @Arguments G
#! @Returns A permutation group
#! @Description
#! <Ref Func="Vole.TwoClosure"/> emulates the built-in &GAP; function
#! <Ref Attr="TwoClosure" BookName="Ref" Style="Number"/>.
#!
#! The <E>2-closure</E> of a permutation group <A>G</A> is the largest group
#! whose orbitals (orbits on pairs of positive integers) coincide with those
#! of <A>G</A>;
#! equivalently, it is the intersection of the automorphism groups of the
#! orbital graphs of <A>G</A>.
#!
#! <B>Warning</B>: this function currently requires the &OrbitalGraphs;
#! package.
#! 
#! @BeginLogSession
#! gap> LoadPackage("OrbitalGraphs", false);;
#! gap> G := Group([ (1,4)(2,5), (1,3,5)(2,4,6) ]);;
#! gap> (3,6) in G;
#! false
#! gap> Vole.TwoClosure(G) = ClosureGroup(G, (3,6));
#! true
#! @EndLogSession
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
#! @InsertChunk DefaultAction
#!
#! <Ref Func="VoleFind.CanonicalPerm"/>
#!
#! @InsertChunk canonical-warning-session

#! @BeginExampleSession
#! gap> true;
#! true
#! @EndExampleSession
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
