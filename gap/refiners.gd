# Vole: Backtrack search in permutation groups with graphs
# A GAP package by Mun See Chang, Christopher Jefferson, and Wilf A. Wilson.
#
# SPDX-License-Identifier: MPL-2.0
#
# Declarations: Vole refiners

#! @Chapter Refiners in &Vole;
#! @ChapterLabel Refiners

#! @Section Refiners

#! Refiners in &Vole; are still a work in progress, and are not yet properly 
#! documented.
#! Please check back in the next version.

# There can be multiple refiners implemented for the same constraint
# with different tradeoffs, and also refiners implemented for special cases
# (such as symmetric and alternating groups). In general most users will want to
# use provide constraints rather than refiners, and let &Vole; choose
#! appropriate refiners for the given constraints.


#! @Section The <C>VoleRefiner</C> record

#! @Description
#!
#! <C>VoleRefiner</C> is a record that contains all of the refiners that are
#! included in &Vole;.
#!
#! &GraphBacktracking; and &BacktrackKit; refiners are
#! also compatible with &Vole;.
#! @BeginExampleSession
#! gap> LoadPackage("vole", false);;
#! gap> Set(RecNames(VoleRefiner));
#! [ "DigraphStab", "DigraphTransporter", "FromConstraint", "InSymmetricGroup", 
#!   "SetSetStab", "SetSetTransporter", "SetStab", "SetTransporter", 
#!   "SetTupleStab", "SetTupleTransporter", "TupleStab", "TupleTransporter" ]
#! @EndExampleSession
DeclareGlobalVariable("VoleRefiner");
# TODO When we require GAP >= 4.12, use GlobalName rather than GlobalVariable
InstallValue(VoleRefiner, rec());


DeclareRepresentation("IsVoleRefiner", IsRefiner, ["constraint"]);
BindGlobal("VoleRefinerFamily", NewFamily("VoleRefinerFamily", IsVoleRefiner));
BindGlobal("VoleRefinerType", NewType(VoleRefinerFamily, IsVoleRefiner));


#! @Section &Vole; refiners via the <C>VoleRefiner</C> record
#! @SectionLabel providedrefs

#! @Arguments x
#! @Returns A &Vole; refiner
#! @Description
#! Something
#! @BeginExampleSession
#! gap> true;
#! true
#! @EndExampleSession
DeclareGlobalFunction("VoleRefiner.InSymmetricGroup");


#! @BeginGroup Set
#! @Arguments s
#! @Returns A &Vole; refiner
#! @Description
#! Something
DeclareGlobalFunction("VoleRefiner.SetStab");
#! @EndGroup
#! @Arguments s, t
#! @Group Set
#! @BeginExampleSession
#! gap> true;
#! true
#! @EndExampleSession
DeclareGlobalFunction("VoleRefiner.SetTransporter");


#! @BeginGroup Tuple
#! @Arguments s
#! @Returns A &Vole; refiner
#! @Description
#! Something
DeclareGlobalFunction("VoleRefiner.TupleStab");
#! @EndGroup
#! @Arguments s, t
#! @Group Tuple
#! @BeginExampleSession
#! gap> true;
#! true
#! @EndExampleSession
DeclareGlobalFunction("VoleRefiner.TupleTransporter");


#! @BeginGroup SetSet
#! @Arguments s
#! @Returns A &Vole; refiner
#! @Description
#! Something
DeclareGlobalFunction("VoleRefiner.SetSetStab");
#! @EndGroup
#! @Arguments s, t
#! @Group SetSet
#! @BeginExampleSession
#! gap> true;
#! true
#! @EndExampleSession
DeclareGlobalFunction("VoleRefiner.SetSetTransporter");


#! @BeginGroup SetTuple
#! @Arguments s
#! @Returns A &Vole; refiner
#! @Description
#! Something
DeclareGlobalFunction("VoleRefiner.SetTupleStab");
#! @EndGroup
#! @Arguments s, t
#! @Group SetTuple
#! @BeginExampleSession
#! gap> true;
#! true
#! @EndExampleSession
DeclareGlobalFunction("VoleRefiner.SetTupleTransporter");

#! @BeginGroup Digraph
#! @Arguments s
#! @Returns A &Vole; refiner
#! @Description
#! Something
DeclareGlobalFunction("VoleRefiner.DigraphStab");
#! @EndGroup
#! @Arguments s, t
#! @Group Digraph
#! @BeginExampleSession
#! gap> true;
#! true
#! @EndExampleSession
DeclareGlobalFunction("VoleRefiner.DigraphTransporter");


#! @Section Choosing a refiner for a given constraint


#! @Arguments constraint
#! @Returns A &Vole;, &GraphBacktracking;, or &BacktrackKit; refiner
#! @Description
#! Something.
#! @BeginExampleSession
#! gap> true;
#! true
#! @EndExampleSession
DeclareGlobalFunction("VoleRefiner.FromConstraint");
