# Vole: Backtrack search in permutation groups with graphs
# A GAP package by Mun See Chang, Christopher Jefferson, and Wilf A. Wilson.
#
# SPDX-License-Identifier: MPL-2.0
#
# Declarations: The native interface to Vole

#! @BeginChunk valueoption
#! This function supports various options, which are documented in
#! Section&nbsp;<Ref Sect="Section_options"/>.
#! @EndChunk

#! @BeginChunk group-ingroup
#! * A permutation group <A>G</A> is interpreted as the constraint
#!   `VoleCon.InGroup(<A>G</A>)`; see <Ref Func="VoleCon.InGroup"/>.
#! @EndChunk

#! @BeginChunk coset-incoset
#! * A &GAP; right coset object  <A>U</A> is interpreted as the constraint
#!   `VoleCon.InCoset(<A>U</A>)`; see <Ref Func="VoleCon.InCoset"/>.
#! @EndChunk

#! @BeginChunk posint-lmp
#! * A positive integer <A>k</A> is interpreted as the
#!   constraint `VoleCon.LargestMovedPoint(<A>k</A>)`;
#!   see <Ref Func="VoleCon.LargestMovedPoint"/>.
#! @EndChunk

#! @BeginChunk canonical-warning
#! TODO: canonical labels etc are not necessarily permanent across GAP sessions.
#! @EndChunk


#! @Chapter The native &Vole; interface
#! @ChapterLabel interface

#! The native interface to &Vole; is similar to that provided by &ferret;,
#! &BacktrackKit;, and &GraphBacktracking;, so it should be somewhat
#! familiar to users of those packages.

#! At a basic level,

#! @Section The <C>VoleFind</C> record
#! @SectionLabel VoleFind

#! @Description
#!
#! `VoleFind` is a record that contains the functions providing the
#! native interface to &Vole;.
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


#! @Section Searching for groups, cosets, and representatives with the native interface

#! In each of the following functions, the arguments <A>constraints...</A>
#! can be a non-empty assortment of permutation groups, and/or
#! right cosets, and/or
#! &Vole; <E>constraints</E> (Chapter&nbsp;<Ref Chap="Chapter_Constraints"/>),
#! and/or <E>refiners</E> (Chapter&nbsp;<Ref Chap="Chapter_Refiners"/>);
#! or a single list thereof.

#! @Subsection lolol

#! @BeginGroup Rep
#! @Arguments constraints...
#! @Returns A permutation, or <K>fail</K>
#! @Description
#! `VoleFind.Representative` searches for a single permutation that
#! satisfies the <A>constraints</A>
#! `VoleFind.Rep` is a synonym for `VoleFind.Representative`.
#!
#! @InsertChunk group-ingroup
#! @InsertChunk coset-incoset
#! @InsertChunk posint-lmp
#!
#! @InsertChunk valueoption
#!
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
#!
#! @InsertChunk group-ingroup
#! @InsertChunk posint-lmp
#!
#! Warning: it is up to the users to make sure that the constraints define
#! a group.
#!
#! @InsertChunk valueoption
#! @BeginExampleSession
#! gap> true;
#! true
#! @EndExampleSession
DeclareGlobalFunction("VoleFind.Group");

#! @Arguments constraints...
#! @Returns A right coset of a permutation group, or <K>fail</K>
#! @Description
#! Text about `VoleFind.Coset`.
#!
#! @InsertChunk group-ingroup
#! @InsertChunk posint-lmp
#!
#! @InsertChunk valueoption
#! @BeginExampleSession
#! gap> true;
#! true
#! @EndExampleSession
DeclareGlobalFunction("VoleFind.Coset");


#! @Section Bounds associated with a constraint or refiner

#! In &GAP;, all permutations are implicitly defined on the set of all positive
#! integers, although there are limits on the points that can be involved that
#! are prescribed by the computer and the laws of physics.
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


#! @Section Searching for canonical permutations and images with the native interface

#! @Arguments G, constraints...
#! @Returns A record
#! @Description
#! Text about `VoleFind.Canonical`.
#!
#! The constraints must be (equivalent) to something of the form
#! `VoleCon.Stabilise(object,action)`, such that <A>G</A> "acts
#! on" <A>object</A>.
#!
#! In the sense that the set of all permutations satisfying
#! the constraint is a stabiliser of some `object` under an `action`.
#! For example, `VoleCon.Normalise(G)`!
#!
#! Suppose the i-th constraint is equivalent to
#! `VoleCon.Stabilise(object_i,action_i)`.
#!
#! Then `VoleFind.Canonical` searches for the canonical image of
#!
#! @InsertChunk valueoption
#! @InsertChunk canonical-warning
#! @BeginExampleSession
#! gap> true;
#! true
#! @EndExampleSession
DeclareGlobalFunction("VoleFind.Canonical");

#! @Arguments G, constraints...
#! @Returns A permutation
#! @Description
#! This function returns the `perm` component of the record returned by
#! <Ref Func="VoleFind.Canonical"/>, when given the same arguments.
#!
#! In other words, this returns
#! `VoleFind.Canonical(<A>G</A>,<A>constraints...</A>).perm`.
#!
#! Please see the documentation of <Ref Func="VoleFind.Canonical"/> for more
#! information.
#!
#! @BeginExampleSession
#! gap> true;
#! true
#! @EndExampleSession
DeclareGlobalFunction("VoleFind.CanonicalPerm");
