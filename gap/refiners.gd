# Vole: Backtrack search in permutation groups with graphs
# A GAP package by Mun See Chang, Christopher Jefferson, and Wilf A. Wilson.
#
# SPDX-License-Identifier: MPL-2.0
#
# Declarations: Vole refiners

#! @Chapter Refiners in &Vole;
#! @ChapterLabel Refiners

#! @Section Refiners

#! Refiners in &Vole; are still a work in progress, and are not yet documented.
#! Please check back in the next version.

# There can be multiple refiners implemented for the same mathematical property
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
#! [ "DigraphStab", "DigraphTransporter", "InSymmetricGroup", "PointStab", 
#!   "PointTransporter", "SetSetStab", "SetSetTransporter", "SetStab", 
#!   "SetTransporter", "SetTupleStab", "SetTupleTransporter", "TupleStab", 
#!   "TupleTransporter" ]
#! @EndExampleSession
DeclareGlobalVariable("VoleRefiner");
# TODO When we require GAP >= 4.12, use GlobalName rather than GlobalVariable
InstallValue(VoleRefiner, rec());
DeclareGlobalFunction("VoleRefiner.FromConstraint");
