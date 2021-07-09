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

#! @Description
#!
#! `VoleCon` is a record that contains the constraints that &Vole; provides.
#!
#! See Section&nbsp;<Ref Sect="Section_concept"/> for...
#!
#! The currently-provided constraints are:
#! * <Ref Func="VoleCon.InGroup"/>
#! * <Ref Func="VoleCon.Stabilize"/>
#! * <Ref Func="VoleCon.Transport"/>
#! * <Ref Func="VoleCon.Normalize"/>
#! * <Ref Func="VoleCon.Centralize"/>
#! * <Ref Func="VoleCon.MovedPoints"/>
#! * <Ref Func="VoleCon.LargestMovedPoint"/>
#! @BeginExampleSession
#! gap> Set(RecNames(VoleCon));
#! [ "Centralise", "Centralize", "InGroup", "LargestMovedPoint", "MovedPoints", 
#!   "Normalise", "Normalize", "Stabilise", "Stabilize", "Transport" ]
#! @EndExampleSession
DeclareGlobalVariable("VoleCon");
# TODO When we require GAP >= 4.12, use GlobalName rather than GlobalVariable
InstallValue(VoleCon, rec());


#! @Section Constraints provided in the <C>VoleCon</C> record


#! @Arguments G
#! @Returns An object
#! @Description
#! Text about `VoleCon.InGroup`.
#! @BeginExampleSession
#! gap> true;
#! true
#! @EndExampleSession
DeclareGlobalFunction("VoleCon.InGroup");


#! @BeginGroup StabilizeDoc
#! @Arguments obj[, action]
#! @Returns An object
#! @Description
#! Text about `VoleCon.Stabilize`.
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
#! @Returns An object
#! @Description
#! Text about `VoleCon.Transport`.
#! @BeginExampleSession
#! gap> true;
#! true
#! @EndExampleSession
DeclareGlobalFunction("VoleCon.Transport");


#! @BeginGroup NormalizeDoc
#! @Arguments G
#! @Returns An object
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
#! @Returns An object
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


#! @Arguments pointlist
#! @Returns An object
#! @Description
#! Text about `VoleCon.MovedPoints`.
#! @BeginExampleSession
#! gap> true;
#! true
#! @EndExampleSession
DeclareGlobalFunction("VoleCon.MovedPoints");


#! @Arguments point
#! @Returns An object
#! @Description
#! Text about `VoleCon.LargestMovedPoint`.
#! @BeginExampleSession
#! gap> true;
#! true
#! @EndExampleSession
DeclareGlobalFunction("VoleCon.LargestMovedPoint");
