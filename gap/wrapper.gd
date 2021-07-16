# Vole: Backtrack search in permutation groups with graphs
# A GAP package by Mun See Chang, Christopher Jefferson, and Wilf A. Wilson.
#
# SPDX-License-Identifier: MPL-2.0
#
# Declarations: Wrappers for Vole functions that emulate GAP/images/Digraphs

#! @Chapter Emulating traditional interfaces with &Vole;
#! @ChapterLabel wrapper


#! @Section The concept

#! The functionality of &Vole; overlaps with that of &GAP; and its
#! other packages, such as &images; and &Digraphs;.
#!
#! &Vole; has its own native interface, which is described in
#! Chapter&nbsp;<Ref Chap="Chapter_interface"/>, and which offers
#! highly configurable access to the underlying graph backtracking algorithm.
#! This is the recommended interface to &Vole;
#!
#! However, &Vole; also provides wrappers around its native
#! interface that allow &Vole; to emulate some existing interfaces.
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
#! return equal groups – the normaliser of <A>U</A> in <A>G</A> – for
#! all permutation groups <A>G</A> and <A>U</A>.
#!
#! The purpose of these wrappers is to make &Vole; easier to learn, and use, for
#! those who are already familiar with the existing &GAP;/package functions.
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
#! `Vole` is a record that contains...
#! The components of this record are functions that are named to coincide
#! with the corresponding &GAP;/&images;/&Digraphs; function.
#!
#! @BeginExampleSession
#! gap> LoadPackage("vole", false);;
#! gap> Set(RecNames(Vole));
#! [ "AutomorphismGroup", "CanonicalDigraph", "CanonicalImage", 
#!   "CanonicalImagePerm", "CanonicalPerm", "Centraliser", "Centralizer", 
#!   "DigraphCanonicalLabelling", "Intersection", "IsConjugate", "Normaliser", 
#!   "Normalizer", "RepresentativeAction", "Stabiliser", "Stabilizer" ]
#! @EndExampleSession
DeclareGlobalVariable("Vole");
# TODO When we require GAP >= 4.12, use GlobalName rather than GlobalVariable
InstallValue(Vole, rec());


#! @Section TEMPORARY

#! @BeginChunk DefaultAction
#! The default <A>action</A>, when the argument is not given, is
#! <Ref Oper="OnPoints" Style="Number" BookName="Ref" Style="Number"/>,
#! which is the name in &GAP; of the action that corresponds to
#! `<A>object</A>^g`, where `g` in <A>G</A>.
#! @EndChunk

#! @BeginChunk DefaultAction2
#! If the optional argument <A>action</A> is not given, then the action
#! <Ref Func="OnPoints" BookName="Ref"/> is used by default;
#! this is the action obtained by the `^` operator;
#! see <Ref Oper="\^" BookName="Ref"/>.
#! @EndChunk

# TODO This should probably be in constraints.gd? And only referenced from here.
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
#! <Table Align="ll">
#! <Row>
#!   <Item><B>Permitted action</B></Item>
#!   <Item><B>Corresponding permitted object(s)</B></Item>
#! </Row>
#! <HorLine/>
#! <Row>
#!   <Item>
#!     <Ref Func="OnPoints" Style="Number" BookName="Ref"/> [default]
#!   </Item>
#!   <Item>
#!     A point, or permutation, or perm group
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
#!     <Ref Func="OnTuplesSets" Style="Number" BookName="Ref"/>
#!   </Item>
#!   <Item>
#!     A list of sets of positive integers
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
#!     <Ref Oper="OnDigraphs" BookName="Digraphs" Style="Number" Label="for a digraph and a perm"/>
#!   </Item>
#!   <Item>
#!     A digraph
#!   </Item>
#! </Row>
#! </Table>


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
#! Can be permgroups and/or right cosets.
#!
#! Note that &Vole; is cool because it does all of the intersection
#! simultaneously in one search, rather than iteratively intersecting pairs of
#! things.
#!
#! &GAP; might have some clever special cases that we don't bother with.
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
#! Text about this.
#!
#! @InsertChunk DefaultAction
#!
#! <Ref Func="VoleFind.Group"/>
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
#! @Description
#! Text about this.
#!
#! @InsertChunk DefaultAction
#!
#! <Ref Func="VoleFind.Representative"/>
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
#! Text about this
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
#! Text about this.
#! @BeginExampleSession
#! gap> true;
#! true
#! @EndExampleSession
DeclareGlobalFunction("Vole.IsConjugate");
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
#! @InsertChunk DefaultAction
#!
#! <Ref Func="VoleFind.CanonicalPerm"/>
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
#! @InsertChunk DefaultAction
#!
#! <Ref Func="VoleFind.CanonicalPerm"/>

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
#! TODO
#!
#! <Ref Func="VoleFind.CanonicalPerm"/>

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
#! TODO
#!
#! <Ref Func="VoleFind.CanonicalPerm"/>

#! @BeginExampleSession
#! gap> true;
#! true
#! @EndExampleSession
DeclareGlobalFunction("Vole.DigraphCanonicalLabelling");
#! @EndGroup
