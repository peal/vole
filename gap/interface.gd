# Vole: Backtrack search in permutation groups with graphs
# A GAP package by Mun See Chang, Christopher Jefferson, and Wilf A. Wilson.
#
# SPDX-License-Identifier: MPL-2.0
#
# Declarations: TODO

#! @Chapter The native &Vole; interface
#! @ChapterLabel interface

# TODO Note how these support a value option.

#! Similar to &ferret; interface.

#! @Section The <C>VoleFind</C> record
#! @SectionLabel VoleFind

#! @Description
#!
#! `VoleFind` is a record that contains...
#!
#! @BeginExampleSession
#! gap> LoadPackage("vole", false);;
#! gap> Set(RecNames(VoleFind));
#! [ "Canonical", "CanonicalImage", "CanonicalPerm", "Coset", "Group", "Rep", 
#!   "Representative" ]
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

#! @Arguments constraints...
#! @Returns A right coset of a permutation group, or <K>fail</K>
#! @Description
#! Text about `VoleFind.Coset`.
#! @BeginExampleSession
#! gap> true;
#! true
#! @EndExampleSession
DeclareGlobalFunction("VoleFind.Coset");


#! @Arguments G, constraints...
#! @Returns A record
#! @Description
#! Text about `VoleFind.Canonical`.
#! @BeginExampleSession
#! gap> true;
#! true
#! @EndExampleSession
DeclareGlobalFunction("VoleFind.Canonical");

#! @Arguments G, constraints...
#! @Returns A permutation
#! @Description
#! Text about `VoleFind.CanonicalPerm`.
#! @BeginExampleSession
#! gap> true;
#! true
#! @EndExampleSession
DeclareGlobalFunction("VoleFind.CanonicalPerm");

#! @Arguments G, constraints...
#! @Returns A record
#! @Description
#! Text about `VoleFind.CanonicalImage`.
#! @BeginExampleSession
#! gap> true;
#! true
#! @EndExampleSession
DeclareGlobalFunction("VoleFind.CanonicalImage");


#! @Section Bounds associated with a constraint or refiner

#! In &GAP;, all permutations are implicitly defined on the set of all positive
#! integers, although there are bounds on the points that can be involved that
#! are prescribed by the limits of the computer and the laws of physics.
#! Finite support.
#!
#! But there's a potential for danger here with (nearly) infinite stuff.
#! So we need to bound the search somehow.
#! We want to be doing stuff with finite groups.
#! We actually want to do a search in Sym([1..k]) for some posint `k`,
#! or even in Sym(C) for some finite subset of `PositiveIntegers`.
#!
#! <B>Largest required point</B>
#!
#! The largest required point of a 'constraint' is either
#! <K>infinity</K>, or a positive integer `k` such that for any permutation `x`:
#! * `x` satisfies the constraint if and only if
#!   `x` preserves `[1..k]` as a set, and the restriction of `x` to `[1..k]`
#!   satisfies the constraint.
#!
#! The constraint only concerns (at most) the points [1..k], and that the action
#! of a permutation on the points greater than `k` is irrelevant to whether the
#! constraint is satisfied.
#!
#! In particular, there exists some permutation that satisfies the constraint
#! if and only if there exists a permutation in Sym([1..k]) that satisfies
#! the constraint. This also a search for a representative
#!
#! <B>Largest moved point</B>
#!
#! The largest moved point is either <K>infinity</K>,
#! or a positive integer `m` for
#! which it is known a priori that any permutation satisfying the
#! 'constraint' fixes all points > `m`.
#! For many 'constraints' there is no such bound, or at least none can be easily
#! deduced. For instance, the constraint "is even" can be satisfied by
#! some permutation that moves any given point.
#!
