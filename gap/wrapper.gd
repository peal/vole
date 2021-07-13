# Vole: Backtrack search in permutation groups with graphs
# A GAP package by Mun See Chang, Christopher Jefferson, and Wilf A. Wilson.
#
# SPDX-License-Identifier: MPL-2.0
#
# Declarations: Wrappers for Vole functions to emulate the GAP interface.

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
#!
#! @BeginExampleSession
#! gap> Difference(RecNames(Vole), ["FindOne", "FindGroup"]);
#! @EndExampleSession
DeclareGlobalVariable("Vole");
# TODO When we require GAP >= 4.12, use GlobalName rather than GlobalVariable
InstallValue(Vole, rec());


#! @Section Summary of the correspondence between &Vole; and &GAP; functions
#!
#! Some text.

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
#!     <Ref Oper="Intersection" BookName="Ref" />
#!   </Item>
#! </Row>
#! <Row>
#!   <Item>
#!     <Ref Func="Vole.Stabilizer"/>
#!   </Item>
#!   <Item>
#!     <Ref Oper="Stabilizer" BookName="Ref" />
#!   </Item>
#! </Row>
#! <Row>
#!   <Item>
#!     <Ref Func="Vole.RepresentativeAction"/>
#!   </Item>
#!   <Item>
#!     <Ref Oper="RepresentativeAction" BookName="Ref" />
#!   </Item>
#! </Row>
#! <Row>
#!   <Item>
#!     <Ref Func="Vole.Normalizer"/>
#!   </Item>
#!   <Item>
#!     <Ref Oper="Normalizer" BookName="Ref" />
#!   </Item>
#! </Row>
#! <Row>
#!   <Item>
#!     <Ref Func="Vole.Centralizer"/>
#!   </Item>
#!   <Item>
#!     <Ref Oper="Centralizer" BookName="Ref" />
#!   </Item>
#! </Row>
#! <Row>
#!   <Item>
#!     <Ref Func="Vole.IsConjugate"/>
#!   </Item>
#!   <Item>
#!     <Ref Oper="IsConjugate" BookName="Ref" />
#!   </Item>
#! </Row>
#! </Table>


#! @Section Summary of the correspondence between &Vole; and &images; functions
#!
#! Some text.

#! Some more text, explaining the following table.

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
#!     <Ref Func="CanonicalImagePerm" BookName="images" />
#!   </Item>
#! </Row>
#! <Row>
#!   <Item>
#!     <Ref Func="Vole.CanonicalImage"/>
#!   </Item>
#!   <Item>
#!     <Ref Func="CanonicalImage" BookName="images" />
#!   </Item>
#! </Row>
#! </Table>

#! Perhaps some final text?


#! @Section &Vole; functions emulating built-in &GAP; functions


#! @BeginGroup wilf
#! @GroupTitle hey
#! @Arguments G1[, G2[, G3, ...]]
#! @Returns An permutation group
#! @Description
#! Text about this
#! Oh no! Actually we need it to work for cosets as well.
#! @BeginExampleSession
#! gap> true;
#! true
#! @EndExampleSession
DeclareGlobalFunction("Vole.Intersection");
DeclareGlobalFunction("Vole.Stabilizer");
DeclareGlobalFunction("Vole.Stabiliser");
DeclareGlobalFunction("Vole.RepresentativeAction");
DeclareGlobalFunction("Vole.Normalizer");
DeclareGlobalFunction("Vole.Normaliser");
DeclareGlobalFunction("Vole.Centralizer");
DeclareGlobalFunction("Vole.Centraliser");
DeclareGlobalFunction("Vole.IsConjugate");
#! @EndGroup

#!
#! The following four functions each take an action.
#! The supported actions are the same for all functions, and listed below:
#! The supported combinations of objects and actions...
#!
#! * `Vole.Stabilizer(<A>G</A>,<A>obj</A>,<A>action</A>)`,
#!    for a permutation group <A>G</A>, and <A>action</A> on <A>obj</A>.
#! * `Vole.RepresentativeAction(<A>G</A>,<A>obj1</A>,<A>obj2</A>,<A>action</A>)`
#!    for a permutation group <A>G</A> and <A>action</A> on <A>obj1</A> and <A>obj2</A>.
#! * `Vole.CanonicalImage(<A>G</A>,<A>obj</A>,<A>action</A>)`.
#! * `Vole.CanonicalPerm(<A>G</A>,<A>obj</A>,<A>action</A>)`.
#!
#! The following actions are supported by `Stabilizer` and `RepresentativeAction`:
#!
#! * `OnPoints` (for a point, or permutation)
#! * `OnSets`   (for a set of integers)
#! * `OnTuples` (for a list of integers)
#! * `OnSetsSets`, `OnSetsTuples`, `OnTuplesSets`, `OnTuplesTuples`
#!   (for sets/lists of integers as appropriate)
#! * `OnDigraphs`


#! @Section other

#! @Arguments G, constraints...
#! @Returns A permutation
#! @Description
#! Text about `Vole.CanonicalPerm`.
#! @BeginExampleSession
#! gap> true;
#! true
#! @EndExampleSession
DeclareGlobalFunction("Vole.CanonicalPerm");

#! @Arguments G, constraints...
#! @Returns ?
#! @Description
#! Text about `Vole.CanonicalImage`.
#! @BeginExampleSession
#! gap> true;
#! true
#! @EndExampleSession
DeclareGlobalFunction("Vole.CanonicalImage");
