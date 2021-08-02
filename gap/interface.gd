# Vole: Backtrack search in permutation groups with graphs
# A GAP package by Mun See Chang, Christopher Jefferson, and Wilf A. Wilson.
#
# SPDX-License-Identifier: MPL-2.0
#
# Declarations: The native interface to Vole


################################################################################
## Chunks

#! @BeginChunk args-or-list
#! The <A>arguments</A> may be given separately, or as a single list.
#! @EndChunk

#! @BeginChunk con-ref-or
#! Each argument may be a &Vole; constraint
#! (Chapter&nbsp;<Ref Chap="Chapter_Constraints"/>),
#! a refiner (Chapter&nbsp;<Ref Chap="Chapter_Refiners"/>;
#! note that a refiner implies a constraint),
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
#! <B>Warning</B>: The permutation given by a canonical search, and more
#! importantly the canonical image that it defines,
#! are <B>not guaranteed to be the same across different sessions</B>.
#! In particular, canonical permutations and images may differ in different
#! versions of &Vole;, in different versions of &GAP;,
#! and on different hardware.
#! @EndChunk
#! @BeginChunk canonical-warning-ordering
#! In addition, please note that the result also depends on order in which
#! the <A>arguments</A> are given, and on the specific arguments that
#! are used.
#! @EndChunk

#! @BeginChunk bounds-ref
#! Otherwise, an error is given.
#! This guarantees that &Vole; terminates (given sufficient resources).
#! See Section&nbsp;<Ref Sect="Section_bounds"/> for examples and further
#! information.
#! @EndChunk

#! @BeginChunk need-lmp
#! For at least one of the <A>arguments</A>, &Vole; must be able to
#! immediately deduce a (finite) largest moved point of all the permutations
#! that satisfy the corresponding constraint.
#! @InsertChunk bounds-ref
#! @EndChunk

#! @BeginChunk need-lrp
#! For at least one of the <A>arguments</A>, &Vole; must be able to immediately
#! a positive integer `k`, such that for the corresponding constraint:
#! * there exists a permutation satisfying the constraint
#!   if and only if there exists an element of `Sym([1..k])` satisfying
#!   the constraint.
#! @InsertChunk bounds-ref
#! @EndChunk


## End chunks
################################################################################


#! @Chapter The native &Vole; interface
#! @ChapterLabel interface

#! The native interface to &Vole; is similar to that provided by &ferret;,
#! &BacktrackKit;, and &GraphBacktracking;, so it should be somewhat
#! familiar to users of those packages.
#!
#! At a basic level, a search is executed by calling the appropriate function
#! with a suitable list of constraints
#! (and/or refiners, for more expert users).
#! * The name of the function determines the **kind** of search to be executed
#!   (whether for a single permutation, or for a group, or for a canonical
#!    image, etc).
#! * Broadly speaking, the arguments are a list of properties that together
#!   specify the permutations to be searched for.


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
#! @Arguments arguments...
#! @Returns A permutation, or <K>fail</K>
#! @Description
#! <Ref Func="VoleFind.Representative"/> returns a single permutation that
#! satisfies all of the constraints defined by the <A>arguments</A>,
#! if one exists,
#! and it returns <K>fail</K> otherwise.
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
#! @Arguments arguments...
#! @Group Rep
#! @BeginExampleSession
#! gap> true;
#! true
#! @EndExampleSession
DeclareGlobalFunction("VoleFind.Rep");

#! @Arguments arguments...
#! @Returns A permutation group
#! @Description
#! <Ref Func="VoleFind.Group"/> returns the group of permutations that
#! satisfy the constraints defined by the <A>arguments</A>.
#! It is assumed, although not verified, that for each such
#! constraint, the set of permutations satisfying it forms a group:
#! this is the responsibility of the user.
#TODO: do we actually require this of each constraint; or do we just require
#      it of the result?
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

#! @Arguments arguments...
#! @Returns A &GAP; right coset of a permutation group, or <K>fail</K>
#! @Description
#!
#! For this function, it is assumed, although not verified,
#! that for each constraint defined by one of the arguments,
#! the set of permutations satisfying it either is empty,
#! or forms a right coset of some group.
#! It is the responsibility of the user to ensure that this is the case.
#!
#! Given this, <Ref Func="VoleFind.Coset"/> returns the set of permutations that
#! satisfy the constraints defined by the <A>arguments</A>,
#! in the case that the set is nonempty,
#! and it returns <K>fail</K> otherwise.
#! The set of permutations is returned as a &GAP; right coset object.
#!
#! @InsertChunk args-or-list
#! @InsertChunk con-ref-or
#! @InsertChunk group-ingroup
#! @InsertChunk coset-incoset
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


#! @Section Canonising with the native &Vole; interface
#! @SectionLabel interface_canonical

#! Given a group $G$, a set $X$, and an action of $G$ on $X$,
#! then a **canoniser** for $X$ with respect to the action of $G$
#! is a function $f$ from $X$ to itself such that:
#! * for all $x \in X$, $x$ and $f(x)$ are in the same orbit of $G$ on $X$; and
#! * for all $x, y \in X$, $f(x) = f(y)$ if and only if $x$ and $y$ are in the
#!   same orbit of $G$ on $X$.
#!
#! In other words, a canoniser maps a point $x \in X$ to a canonical element
#! of its orbit, under the action of $G$.
#!
#! This canonical element is known as the **canonical image** of $x$ with
#! respect to the action of $G$. It is sometimes called the **canonical form**
#! of $X$.
#!
#! In this context, a **canonical permutation** for $x$ is any element of
#! $G$ that maps $x$ to its canonical image under the action of $G$ on $x$.
#! This is sometimes called a **canonical labelling**.
#! Note that there is not necessarily a unique canonical permutation for each
#! element of $X$.
#! Indeed, by the orbit-stabiliser theorem, the number of canonical permutations
#! for $x \in X$ is equal to the size of the stabiliser of $x$ in $G$.


#! @Arguments G, arguments...
#! @Returns A record
#! @Description
#! <Ref Func="VoleFind.Canonical"/>
#! is the main function in &Vole; for canonising various kinds of objects,
#! i.e. finding canonical images and permutations.
#! See the beginning of Section&nbsp;<Ref Sect="Section_interface_canonical"/>
#! for a definition of these terms.
#!
#! The first argument, <A>G</A>, must be the group in which to canonise.
#! The remaining <A>arguments</A> specify the rest of the canonisation problem
#! (i.e. the object and the action)
#! in a way that we describe below.
#!
#! <B>Please note</B> that the forthcoming details are crucial for obtaining
#! meaningful and comparable results from <Ref Func="VoleFind.Canonical"/>.
#! Therefore, for users who:
#! * wish to compute a canonical permutation/image
#!   of an object under an action that is listed in the table in
#!   <Ref Func="VoleCon.Stabilise"/>, and
#! * do not wish to specify particular refiners for this
#!   (refiners are introduced and discussed in
#!    Chapter&nbsp;<Ref Chap="Chapter_Refiners"/>),
#! we suggest using the functions <Ref Func="Vole.CanonicalPerm"/> and
#! <Ref Func="Vole.CanonicalImage"/>, which provide a much simpler interface
#! to accommodate this simpler use case.
#!
#! The <A>arguments</A> that follow <A>G</A> may be given separately,
#! or as a list.
#! These must be certain kinds of &Vole; constraints
#! (Chapter&nbsp;<Ref Chap="Chapter_Constraints"/>), and/or
#! certain kinds of refiners (Chapter&nbsp;<Ref Chap="Chapter_Refiners"/>; note
#! that a refiner implies a constraint).
#!
#! In particular, the constraint implied by each of the <A>arguments</A>
#! must be such that...
#!
#! Moreover, for users who wish to canonise multiple objects with respect to the
#! same group and action (which is the typical use case),
#! then
#! it is crucial to perform these computations in the same &GAP; session,
#! with the constraints given in a consistent way.
#!
#! For each constraint, the set of permutations satisfying the constraint
#! must be definable as the set of permutations that stabilise some object
#! under an action of <A>G</A>.
#! The &Vole; constraints of this kind are
#! <Ref Func="VoleCon.Stabilise"/>,
#! <Ref Func="VoleCon.Normalise"/>, and
#! <Ref Func="VoleCon.Centralise"/>.
#! In particular, the constraint <Ref Func="VoleCon.InGroup"/> is not permitted,
#! in general.
#!
#! It is guaranteed that when canonising, &Vole; constraints are
#! translated into refiners in a way that is nice.
#!
#! As a side effect of computing a canonical permutation,
#! you get the stabiliser.
#!
#! Note: you have to give the same constraints in the same order
#!
#! The constraints must be (equivalent) to something of the form
#! `VoleCon.Stabilise(object,action)`, such that <A>G</A> "acts
#! on" <A>object</A>.
#!
#! Refiners must form a refiner family.
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
#! The result of <Ref Func="VoleFind.Canonical"/> is given as a record, with the
#! following components:
#! * `canonical`: blah
#! * `group`: blah
#!
#! @InsertChunk valueoption
#!
#! @InsertChunk canonical-warning-session
#! @InsertChunk canonical-warning-ordering
#!
#! @BeginExampleSession
#! gap> true;
#! true
#! @EndExampleSession
DeclareGlobalFunction("VoleFind.Canonical");

#! @Arguments G, arguments...
#! @Returns A permutation
#! @Description
#! This function returns
#! `VoleFind.Canonical(<A>G</A>,<A>arguments...</A>).canonical`.
#! This is the `canonical` component of the record returned by
#! <Ref Func="VoleFind.Canonical"/>, under the same arguments.
#!
#! Please see the documentation of <Ref Func="VoleFind.Canonical"/> for
#! much more information.
#!
#! @InsertChunk canonical-warning-session
#! @InsertChunk canonical-warning-ordering
#!
#! The following example shows how to compute a canonical permutation
#! for the group $\langle (1\,2) \rangle$ under conjugation by $A_{4}$:
#! @BeginExampleSession
#! gap> VoleFind.CanonicalPerm(AlternatingGroup(4),
#! >  VoleCon.Normalise(Group([ (1,2) ]))
#! > );
#! (1,4)(2,3)
#! @EndExampleSession
#! Thus the canonical image of $\langle (1\,2) \rangle$ under this action of
#! $A_{4}$ is the group $\langle (3\,4) \rangle$.
#!
#! This second example shows how to compute a canonical permutation
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
