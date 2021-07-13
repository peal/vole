# Vole: Backtrack search in permutation groups with graphs
# A GAP package by Mun See Chang, Christopher Jefferson, and Wilf A. Wilson.
#
# SPDX-License-Identifier: MPL-2.0
#
# Declarations: TODO

#! @Chapter Constraints

#! @Section The concept of constraints
#! @SectionLabel concept

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

#! @BeginGroup LoadPackageGrp
#! @BeginExampleSession
#! gap> LoadPackage("vole", false);; # Just here temporarily
#! @EndExampleSession
#! @EndGroup


#! @Section The <C>VoleCon</C> record
#! @SectionLabel VoleCon

#! @Description
#!
#! `VoleCon` is a record that contains all of the constraints that &Vole;
#! provides.
#!
#! These constraints are documented in
#! Section&nbsp;<Ref Sect="Section_providedcons"/>.
DeclareGlobalVariable("VoleCon");
# TODO When we require GAP >= 4.12, use GlobalName rather than GlobalVariable
InstallValue(VoleCon, rec());


#! @Section Constraints provided in the <C>VoleCon</C> record
#! @SectionLabel providedcons

#! Some text.

#! @BeginExampleSession
#! gap> Set(RecNames(VoleCon));
#! [ "Centralise", "Centralize", "InGroup", "LargestMovedPoint", "MovedPoints", 
#!   "Normalise", "Normalize", "Stabilise", "Stabilize", "Transport" ]
#! @EndExampleSession

#! Some more text, explaining the following table.

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
#!
#!     <Ref Func="VoleCon.InLeftCoset"/>
#!
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
## @Returns An object
#! @Description
#! This constraint is satisfied by the elements of the permutation group
#! <A>G</A>, and no others.
#! @BeginExampleSession
#! gap> con1 := VoleCon.InGroup(DihedralGroup(IsPermGroup, 8));
#! gap> con2 := VoleCon.InGroup(AlternatingGroup(4));
#! gap> VoleFind.Group(con1, con2) = Group([(1,3)(2,4), (1,4)(2,3)]);
#! true
#! @EndExampleSession
DeclareGlobalFunction("VoleCon.InGroup");


#! @Arguments U
## @Returns An object
#! @Description
#! A permutation satisfies this constraint if...
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
## @Returns An object
#! @Description
#! A permutation satisfies this constraint if...
#!
#! See also <Ref Func="VoleCon.InLeftCoset"/>.
#! @BeginExampleSession
#! gap> true;
#! true
#! @EndExampleSession
DeclareGlobalFunction("VoleCon.InRightCoset");



#! @Arguments G, x
## @Returns An object
#! @Description
#! Text about `VoleCon.InLeftCoset`.
#! See also <Ref Func="VoleCon.InRightCoset"/>.
#! @BeginExampleSession
#! gap> true;
#! true
#! @EndExampleSession
DeclareGlobalFunction("VoleCon.InLeftCoset");


#! @BeginGroup StabilizeDoc
#! @Arguments obj[, action]
## @Returns An object
#! @Description
#! Text about `VoleCon.Stabilize`.
#!
#! If the optional argument <A>action</A> is not given, then the action
#! <Ref Func="OnPoints" BookName="Ref"/> is used by default;
#! this is the action obtained by the `^` operator;
#! see <Ref Oper="\^" BookName="Ref"/>.
#!
#! The combinations of objects and actions that are supported by &Vole;
#! is given in... TODO
DeclareGlobalFunction("VoleCon.Stabilize");
#! @EndGroup
#! @Arguments obj[, action]
#! @Group StabilizeDoc
#! @BeginExampleSession
#! gap> true;
#! true
#! @EndExampleSession
DeclareGlobalFunction("VoleCon.Stabilise");


#! @Arguments obj1, obj2[, action]
## @Returns An object
#! @Description
#! Text about `VoleCon.Transport`.
#! @BeginExampleSession
#! gap> true;
#! true
#! @EndExampleSession
DeclareGlobalFunction("VoleCon.Transport");


#! @BeginGroup NormalizeDoc
#! @Arguments G
## @Returns An object
#! @Description
#! Text about `VoleCon.Normalize`.
DeclareGlobalFunction("VoleCon.Normalize");
#! @EndGroup
#! @Arguments G
#! @Group NormalizeDoc
#! @BeginExampleSession
#! gap> true;
#! true
#! @EndExampleSession
DeclareGlobalFunction("VoleCon.Normalise");


#! @BeginGroup CentralizeDoc
#! @Arguments G
## @Returns An object
#! @Description
#! Text about `VoleCon.Centralize`.
DeclareGlobalFunction("VoleCon.Centralize");
#! @EndGroup
#! @Arguments G
#! @Group CentralizeDoc
#! @BeginExampleSession
#! gap> true;
#! true
#! @EndExampleSession
DeclareGlobalFunction("VoleCon.Centralise");


#! @Arguments x, y
## @Returns An object
#! @Description
#! Text about `VoleCon.Conjugate`.
#! @BeginExampleSession
#! gap> true;
#! true
#! @EndExampleSession
DeclareGlobalFunction("VoleCon.Conjugate");


#! @Arguments pointlist
## @Returns An object
#! @Description
#! This constraint is a shorthand for
#! `VoleCon.InGroup(SymmetricGroup(<A>pointlist</A>))`;
#! see <Ref Func="VoleCon.InGroup"/>.
#! @BeginExampleSession
#! gap> con1 := VoleCon.MovedPoints([1..5]);;
#! gap> con2 := VoleCon.MovedPoints([2,6,4,5]);;
#! gap> VoleFind.Group(con1, con2) = SymmetricGroup([2,3,5]);
#! true
#! @EndExampleSession
DeclareGlobalFunction("VoleCon.MovedPoints");


#! @Arguments point
## @Returns An object
#! @Description
#! This constraint is a shorthand for
#! `VoleCon.InGroup(SymmetricGroup([1..<A>point</A>]))`;
#! see <Ref Func="VoleCon.InGroup"/>.
#! @BeginExampleSession
#! gap> con := VoleCon.LargestMovedPoint(5);;
#! gap> VoleFind.Group(con) = SymmetricGroup(5);
#! true
#! @EndExampleSession
DeclareGlobalFunction("VoleCon.LargestMovedPoint");
