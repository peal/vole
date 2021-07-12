# Vole: Backtrack search in permutation groups with graphs
# A GAP package by Mun See Chang, Christopher Jefferson, and Wilf A. Wilson.
#
# SPDX-License-Identifier: MPL-2.0
#
# Declarations: Wrappers for Vole functions to emulate the GAP interface.

#! @Chapter Emulating the traditional GAP interface with &Vole;

#! @Section Simple wrapper functions

#! Vole provides a number of reimplementations of built-in &GAP; functions.
#! These try to provide the same interface as the original &GAP; function. Note
#! that these functions always use graph backtracking, so may be significantly
#! slower than &GAP;'s built in functions when those functions can greatly
#! simplify solving using group properties.
#!
#! The functions currently implemented are:
#!
#! * `Vole.Intersection(<A>U1</A>,<A>U2</A>,...)` and 
#!   `Vole.Intersection([<A>U1</A>,<A>U2</A>,...])`
#!    for permutation groups <A>U1</A>, <A>U2</A>, ..., etc.
#! * `Vole.Normaliser(<A>G</A>,<A>H</A>)` - for permutation groups
#!   <A>G</A> and <A>H</A>
#! * `Vole.IsConjugate(<A>G</A>,<A>U</A>,<A>V</A>)` for permutation groups
#!    <A>G</A>, <A>U</A>, <A>V</A>
#! * `Vole.IsConjugate(<A>G</A>,<A>x</A>,<A>y</A>)` for a permutation group
#!    <A>G</A> and permutations <A>x</A> and <A>y</A>.
#!
#! * <Ref Oper="IsConjugate" BookName="Ref"/>
#! * <Ref Oper="Normalizer" BookName="Ref" />
#! * <Ref Oper="Intersection" BookName="Ref" />

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
DeclareGlobalFunction("VoleCon.Intersection");
DeclareGlobalFunction("VoleCon.Normalizer");
DeclareGlobalFunction("VoleCon.Normaliser");
DeclareGlobalFunction("VoleCon.Centralizer");
DeclareGlobalFunction("VoleCon.Centraliser");
DeclareGlobalFunction("VoleCon.IsConjugate");
#! @EndGroup

#!
#! The following four functions each take an action.
#! The supported actions are the same for all functions, and listed below:
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

# TODO: DeclareGlobalName("Vole");
DeclareGlobalVariable("Vole");
InstallValue(Vole, rec());
