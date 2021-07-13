# Vole: Backtrack search in permutation groups with graphs
# A GAP package by Mun See Chang, Christopher Jefferson, and Wilf A. Wilson.
#
# SPDX-License-Identifier: MPL-2.0
#
# Declarations: TODO

#! @Chapter The native &Vole; interface

# TODO Note how these support a value option.


#! @Section The <C>VoleFind</C> record
#! @SectionLabel VoleFind

#! @Description
#!
#! `VoleFind` is a record that contains...
#!
#! @BeginExampleSession
#! gap> Set(RecNames(VoleFind));
#! @EndExampleSession
DeclareGlobalVariable("VoleFind");
# TODO When we require GAP >= 4.12, use GlobalName rather than GlobalVariable
InstallValue(VoleFind, rec());


#! @Section Interface

#! @Arguments constraints...
#! @Returns A permutation, or <K>fail</K>
#! @Description
#! Text about `VoleFind.Representative`.
#! @BeginExampleSession
#! gap> true;
#! true
#! @EndExampleSession
DeclareGlobalFunction("VoleFind.Representative");
DeclareGlobalFunction("VoleFind.Rep");

#! @Arguments constraints...
#! @Returns A permutation group
#! @Description
#! Text about `VoleFind.Group`.
#! @BeginExampleSession
#! gap> true;
#! true
#! @EndExampleSession
DeclareGlobalFunction("VoleFind.Group");

#! @Arguments G, constraints...
#! @Returns A permutation
#! @Description
#! Text about `VoleFind.CanonicalPerm`.
#! @BeginExampleSession
#! gap> true;
#! true
#! @EndExampleSession
DeclareGlobalFunction("VoleFind.CanonicalPerm");
