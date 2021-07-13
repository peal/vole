# Vole: Backtrack search in permutation groups with graphs
# A GAP package by Mun See Chang, Christopher Jefferson, and Wilf A. Wilson.
#
# SPDX-License-Identifier: MPL-2.0
#
# Declarations: TODO

#! @Chapter The native &Vole; interface

# TODO Note how these support a value option.

#! @Section Interface

#! @Arguments constraints...
#! @Returns A permutation, or <K>fail</K>
#! @Description
#! Text about `Vole.FindOne`.
#! @BeginExampleSession
#! gap> true;
#! true
#! @EndExampleSession
DeclareGlobalFunction("Vole.FindOne");

#! @Arguments constraints...
#! @Returns A permutation group
#! @Description
#! Text about `Vole.FindGroup`.
#! @BeginExampleSession
#! gap> true;
#! true
#! @EndExampleSession
DeclareGlobalFunction("Vole.FindGroup");

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
