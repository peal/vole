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
#! gap> LoadPackage("vole", false);;
#! gap> Set(RecNames(VoleFind));
#! [ "CanonicalPerm", "Group", "Rep", "Representative" ]
#! @EndExampleSession
DeclareGlobalVariable("VoleFind");
# TODO When we require GAP >= 4.12, use GlobalName rather than GlobalVariable
InstallValue(VoleFind, rec());


#! @Section Executing a search with the native &Vole; interface

#! In each of the following functions, the arguments <A>constraints...</A>
#! can be a non-empty assortment of permutation groups, and/or
#! right cosets, and/or
#! &Vole; <E>constraints</E> (Chapter&nbsp;<Ref Chap="Chapter_Constraints"/>),
#! and/or <E>refiners</E> (Chapter&nbsp;<Ref Chap="Chapter_Refiners"/>);
#! or a single list thereof.

#! @BeginGroup Rep
#! @Arguments constraints...
#! @Returns A permutation, or <K>fail</K>
#! @Description
#! Text about `VoleFind.Representative`.
#!
#! `VoleFind.Rep` is a synonym for `VoleFind.Representative`.
DeclareGlobalFunction("VoleFind.Representative");
#! @EndGroup
#! @Arguments constraints...
#! @Group Rep
#! @BeginExampleSession
#! gap> true;
#! true
#! @EndExampleSession
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
