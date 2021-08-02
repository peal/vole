# Vole: Backtrack search in permutation groups with graphs
# A GAP package by Mun See Chang, Christopher Jefferson, and Wilf A. Wilson.
#
# SPDX-License-Identifier: MPL-2.0
#
# Declarations: The native interface to Vole

#! @BeginChunk args-or-list
#! The constraints may be given as separate arguments, or as a single list.
#! @EndChunk

#! @BeginChunk con-ref-or
#! A constraint may be a &Vole; constraint
#! (Chapter&nbsp;<Ref Chap="Chapter_Constraints"/>),
#! a refiner (Chapter&nbsp;<Ref Chap="Chapter_Refiners"/>),
#! or one of the following objects:
#! @EndChunk

#! @BeginChunk valueoption
#! This function supports various options, which are documented in
#! Section&nbsp;<Ref Sect="Section_options"/>.
#! @EndChunk

#! @BeginChunk group-ingroup
#! * A permutation group <A>G</A>, which is interpreted as an instance of the
#!   constraint <Ref Func="VoleCon.InGroup"/> with argument <A>G</A>.
#! @EndChunk

#! @BeginChunk coset-incoset
#! * A &GAP; right coset object <A>U</A>, which is interpreted as an instance
#!   of the constraint <Ref Func="VoleCon.InCoset"/> with argument <A>U</A>.
#! @EndChunk

#! @BeginChunk posint-lmp
#! * A positive integer <A>k</A>, which is interpreted as an instance of the
#!   constraint <Ref Func="VoleCon.LargestMovedPoint"/> with argument <A>k</A>.
#! @EndChunk

#! @BeginChunk canonical-warning-session
#! <B>Warning</B>: The permutation given by a canonical search, and the
#! canonical image that it defines, are <B>not guaranteed to be the same
#! across different sessions</B>.
#! In particular, canonical permutations and images may differ in different
#! versions of &Vole;, in different versions of &GAP;,
#! and on different hardware.
#! @EndChunk
#! @BeginChunk canonical-warning-ordering
#! In addition, please note that the result also depends on order in which
#! the <A>constraints</A> are given.
#! @EndChunk

#! @BeginChunk bounds-ref
#! This guarantees that &Vole; terminates (given sufficient resources).
#! See Section&nbsp;<Ref Sect="Section_bounds"/> for examples and further
#! information.
#! @EndChunk

#! @BeginChunk need-lmp
#! At least one of the constraints must clearly imply a finite largest moved
#! point of any permutation that satisfies the constraint.
#! An error is given if &Vole; cannot immediately deduce such a largest moved
#! point.
#! @InsertChunk bounds-ref
#! @EndChunk

#! @BeginChunk need-lrp
#! At least one of the constraints must clearly imply a positive integer bound
#! `k` such that there exists **some** permutation satisfying the constraint
#! if and only if there exists an element of `Sym([1 .. k])` satisfying
#! the constraint.
#! An error is given if &Vole; cannot immediately deduce such a bound.
#! @InsertChunk bounds-ref
#! @EndChunk


#! @BeginChunk
#! In each of the following functions, the arguments <A>constraints...</A>
#! can be a non-empty assortment of permutation groups, and/or
#! right cosets, and/or
#! &Vole; <E>constraints</E> (Chapter&nbsp;<Ref Chap="Chapter_Constraints"/>),
#! and/or <E>refiners</E> (Chapter&nbsp;<Ref Chap="Chapter_Refiners"/>);
#! or a single list thereof.
#! @EndChunk

#! @Chapter The native &Vole; interface
#! @ChapterLabel interface

#! The native interface to &Vole; is similar to that provided by &ferret;,
#! &BacktrackKit;, and &GraphBacktracking;, so it should be somewhat
#! familiar to users of those packages.
#!
#! At a basic level, a search is executed by calling the appropriate function
#! with a suitable list of constraints
#! (and/or refiners, for more expert users):
#! * The name of the function determines the **kind** of search to be executed
#!   (whether for a single permutation, or for a group, or for a canonical
#!    image, etc).
#! * Broadly speaking, the arguments are a list of properties that constrain
#!   the search to give the desired result.


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
#! [ "Canonical", "CanonicalPerm", "Coset", "Group", "Rep", "Representative" ]
#! @EndExampleSession
DeclareGlobalVariable("VoleFind");
# TODO When we require GAP >= 4.12, use GlobalName rather than GlobalVariable
InstallValue(VoleFind, rec());


#! @Section Searching for groups, cosets, and representatives with the native interface
#! @SectionLabel interface_main


#! @BeginGroup Rep
#! @Arguments constraints...
#! @Returns A permutation, or <K>fail</K>
#! @Description
#! <Ref Func="VoleFind.Representative"/> returns a single permutation that
#! satisfies all of the <A>constraints</A> if one exists,
#! and returns <K>fail</K> otherwise.
#! <Ref Func="VoleFind.Rep"/> is a synonym for
#! <Ref Func="VoleFind.Representative"/>.
#!
#! @InsertChunk args-or-list
#! @InsertChunk con-ref-or
#! @InsertChunk group-ingroup
#! @InsertChunk coset-incoset
#! @InsertChunk posint-lmp
#!
#! @InsertChunk need-lrp
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
#! <Ref Func="VoleFind.Group"/> returns the group of permutations that satisfy
#! all of the constraints.  It is assumed, although not verified, that for each
#! constraint, the set of permutations that satisfy that constraint forms a
#! group: this is the responsibility of the user.
#!
#! @InsertChunk args-or-list
#! @InsertChunk con-ref-or
#! @InsertChunk group-ingroup
#! @InsertChunk posint-lmp
#!
#! @InsertChunk need-lmp
#!
#! @InsertChunk valueoption
#! @BeginExampleSession
#! gap> true;
#! true
#! @EndExampleSession
DeclareGlobalFunction("VoleFind.Group");

#! @Arguments constraints...
#! @Returns A &GAP; right coset of a permutation group, or <K>fail</K>
#! @Description
#! Text about `VoleFind.Coset`.
#!
#! @InsertChunk group-ingroup
#! @InsertChunk posint-lmp
#!
#! @InsertChunk need-lmp
#!
#! @InsertChunk valueoption
#! @BeginExampleSession
#! gap> true;
#! true
#! @EndExampleSession
DeclareGlobalFunction("VoleFind.Coset");


#! @Section Searching for canonical permutations and images with the native interface
#! @SectionLabel interface_canonical

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
#! This excludes `InGroup` style refiners!
#!
#! Suppose the i-th constraint is equivalent to
#! `VoleCon.Stabilise(object_i,action_i)`.
#!
#! Then `VoleFind.Canonical` searches for the canonical image of
#!
#! @InsertChunk valueoption
#!
#! @InsertChunk canonical-warning-session
#! @InsertChunk canonical-warning-ordering
#!
#! * <Ref Func="Vole.CanonicalPerm"/>
#! * <Ref Func="Vole.CanonicalImage"/>
#! * <Ref Func="Vole.DigraphCanonicalLabelling"/>
#! * <Ref Func="Vole.CanonicalDigraph"/>
#!
#! @BeginExampleSession
#! gap> true;
#! true
#! @EndExampleSession
DeclareGlobalFunction("VoleFind.Canonical");

#! @Arguments G, constraints...
#! @Returns A permutation
#! @Description
#! This function returns
#! `VoleFind.Canonical(<A>G</A>,<A>constraints...</A>).perm`.
#! This is the `perm` component of the record returned by
#! <Ref Func="VoleFind.Canonical"/>, under the same arguments.
#!
#! Please see the documentation of <Ref Func="VoleFind.Canonical"/> for more
#! information.
#!
#! For users who wish to provide only one constraint, and who do not wish to
#! specify a particular refiner, the function <Ref Func="Vole.CanonicalPerm"/>
#! provides a simpler interface for executing the same computation.
#!
#! @InsertChunk canonical-warning-session
#! @InsertChunk canonical-warning-ordering
#!
#! The following example shows how to compute a ‘canonical permutation’
#! for the group $\langle (1\,2) \rangle$ under conjugation by $A_{4}$:
#! @BeginExampleSession
#! gap> VoleFind.CanonicalPerm(AlternatingGroup(4),
#! >  VoleCon.Normalise(Group([ (1,2) ]))
#! > );
#! (1,4)(2,3)
#! @EndExampleSession
#! This second example shows how to compute a ‘canonical permutation’
#! for the pair $[S, D]$ under the specified componentwise action of $S_{4}$,
#! where $S$ is the set-of-sets $\{ \{1,2\}, \{1,4\}, \{2,3\}, \{3,4\} \}$,
#! and $D$ is the cycle digraph on four vertices:
#! @BeginExampleSession
#! gap> VoleFind.CanonicalPerm(SymmetricGroup(4),
#! >  VoleCon.Stabilise([ [1,2], [1,4], [2,3], [3,4] ], OnSetsSets),
#! >  VoleCon.Stabilise(CycleDigraph(4), OnDigraphs)
#! > );
#! (1,2,3)
#! @EndExampleSession
DeclareGlobalFunction("VoleFind.CanonicalPerm");
