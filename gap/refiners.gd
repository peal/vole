# Vole: Backtrack search in permutation groups with graphs
# A GAP package by Mun See Chang, Christopher Jefferson, and Wilf A. Wilson.
#
# SPDX-License-Identifier: MPL-2.0
#
# Declarations: TODO

#! @Chapter Refiners

#! @Section Refiners

#! Something.
#! Something else.

#! @Description
#!
#! <C>VoleRefiner</C> is a record that contains all of the &Vole; refiners.
#! There can be multiple refiners implemented for the same mathematical property
#! with different tradeoffs, and also refiners implemented for special cases
#! (such as symmetric and alternating groups). In general most users will want to
#! use <Ref Var="VoleCon"/>, which provides a higher-level interface.
#! @BeginExampleSession
#! gap> LoadPackage("vole", false);;
#! gap> fail;
#! fail
#! @EndExampleSession
DeclareGlobalVariable("VoleRefiner");
# TODO When we require GAP >= 4.12, use GlobalName rather than GlobalVariable
InstallValue(VoleRefiner, rec());
