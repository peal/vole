# Vole: Backtrack search in permutation groups with graphs
# A GAP package by Mun See Chang, Christopher Jefferson, and Wilf A. Wilson.
#
# SPDX-License-Identifier: MPL-2.0
#
# Declarations: Wrappers for Vole functions to emulate GAP/images.

#! @Chapter Emulating traditional interfaces with &Vole;


#! @Section The concept

# TODO improve this
#! &Vole; provides a number of reimplementations of built-in &GAP; functions.
#! These try to provide the same interface as the original &GAP; function. Note
#! that these functions always use graph backtracking, so may be significantly
#! slower than &GAP;'s built in functions when those functions can greatly
#! simplify solving using group properties.


#! @Section The <C>Vole</C> record
#! @SectionLabel VoleRec

#! @Description
#!
#! `Vole` is a record that contains...
#! The components of this record are functions that are named to coincide
#! with the corresponding &GAP; function.
#!
#! @BeginExampleSession
#! gap> LoadPackage("vole", false);;
#! gap> Set(RecNames(Vole));
#! [ "CanonicalImage", "CanonicalImagePerm", "CanonicalPerm", "Centraliser", 
#!   "Centralizer", "Intersection", "IsConjugate", "Normaliser", "Normalizer", 
#!   "RepresentativeAction", "Stabiliser", "Stabilizer" ]
#! @EndExampleSession
DeclareGlobalVariable("Vole");
# TODO When we require GAP >= 4.12, use GlobalName rather than GlobalVariable
InstallValue(Vole, rec());


#! @Section TEMPORARY

# TODO This should probably be in constraints.gd? And only referenced from here.
# TODO Or should it actually be a "Chunk" that I can insert in multiple places?
# TODO Also OnTuplesSets, OnTuplesTuples, etc?
#! The supported combinations of objects and actions are the same for all of the
#! functions in this chapter that require one or two objects and a corresponding
#! action. This applies here to:
#! * <Ref Func="Vole.Stabilizer"/>
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
#!     <Ref Func="Vole.Stabilizer"/>
#!   </Item>
#!   <Item>
#!     <Ref Oper="Stabilizer" BookName="Ref" Style="Number" />
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
#!     <Ref Func="Vole.Normalizer"/>
#!   </Item>
#!   <Item>
#!     <Ref Oper="Normalizer" BookName="Ref" Style="Number" />
#!   </Item>
#! </Row>
#! <Row>
#!   <Item>
#!     <Ref Func="Vole.Centralizer"/>
#!   </Item>
#!   <Item>
#!     <Ref Oper="Centralizer" BookName="Ref" Style="Number" />
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
#! @GroupTitle Stabilizer
#! @Arguments G, object[, action]
#! @Returns An permutation group
#! @Description
#! Text about this.
DeclareGlobalFunction("Vole.Stabilizer");
#! @EndGroup
#! @Arguments G, object[, action]
#! @Group Stab
#! @BeginExampleSession
#! gap> true;
#! true
#! @EndExampleSession
DeclareGlobalFunction("Vole.Stabiliser");


#! @BeginGroup RepAction
#! @GroupTitle RepresentativeAction
#! @Arguments G, object1, object2[, action]
#! @Description
#! Text about this.
#! @BeginExampleSession
#! gap> true;
#! true
#! @EndExampleSession
DeclareGlobalFunction("Vole.RepresentativeAction");
#! @EndGroup


#! @BeginGroup Norm
#! @GroupTitle Normalizer
#! @Arguments G, U
#! @Returns An permutation group
#! @Description
#! Text about this
DeclareGlobalFunction("Vole.Normalizer");
#! @EndGroup
#! @Arguments G, U
#! @Group Norm
#! @BeginExampleSession
#! gap> true;
#! true
#! @EndExampleSession
DeclareGlobalFunction("Vole.Normaliser");


#! @BeginGroup Cent
#! @GroupTitle Centralizer
#! @Arguments G, x
#! @Returns An permutation group
#! @Description
#! Text about this
DeclareGlobalFunction("Vole.Centralizer");
#! @EndGroup
#! @Arguments G, x
#! @Group Cent
#! @BeginExampleSession
#! gap> true;
#! true
#! @EndExampleSession
DeclareGlobalFunction("Vole.Centraliser");


#! @BeginGroup IsConj
#! @GroupTitle IsConjugate
#! @Arguments G, x, y
#! @Description
#! Text about this.
#! @BeginExampleSession
#! gap> true;
#! true
#! @EndExampleSession
DeclareGlobalFunction("Vole.IsConjugate");
#! @EndGroup


#! @Section &Vole; functions emulating the &images; package

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
#! This function emulates <Ref Func="CanonicalImagePerm" BookName="images" />
#! from the &images; package,
#! although it supports a wider range of objects and actions.
#!
#! Text about `Vole.CanonicalPerm`...
#!
#! `VoleFind.CanonicalImagePerm` is a synonym for `VoleFind.CanonicalPerm`.
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
#! This function emulates <Ref Func="CanonicalImage" BookName="images" />
#! from the &images; package,
#! although it supports a wider range of objects and actions.
#!
#! Text about `Vole.CanonicalImage`...
#! @BeginExampleSession
#! gap> true;
#! true
#! @EndExampleSession
DeclareGlobalFunction("Vole.CanonicalImage");
#! @EndGroup


#! @Section &Vole; functions emulating the &Digraphs; package

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
#! @BeginExampleSession
#! gap> true;
#! true
#! @EndExampleSession
DeclareGlobalFunction("Vole.DigraphCanonicalLabelling");
#! @EndGroup
