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
#!   constraint <Ref  Func="Constraint.InGroup"/> with argument <A>G</A>.
#! @EndChunk

#! @BeginChunk coset-incoset
#! * A &GAP; right coset object <A>U</A>, which is interpreted as an instance
#!   of the constraint <Ref  Func="Constraint.InCoset"/> with argument <A>U</A>.
#! @EndChunk

#! @BeginChunk posint-lmp
#! * A positive integer <A>k</A>, which is interpreted as an instance of the
#!   constraint <Ref  Func="Constraint.LargestMovedPoint"/> with argument <A>k</A>.
#! @EndChunk

#! @BeginChunk fail-none
#! * The value <K>fail</K>, which is interpreted as an instance of the
#!   constraint <Ref  Func="Constraint.None"/>.
#! @EndChunk

#! @BeginChunk canonical-warning-session
#! <B>Warning</B>: The permutation given by a canonical search and
#! the canonical image that it defines
#! are <B>not guaranteed to be the same across different sessions</B>.
#! In particular, canonical permutations/labellings and images may differ
#! in different versions of &Vole;, in different versions of &GAP;,
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
#! deduce a positive integer `k`, such that for the corresponding constraint:
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
#! &BacktrackKit;, and &GraphBacktracking;.
#!
#! At a basic level, a search can be executed by choosing a suitable
#! list of constraints
#! (and/or refiners, for more expert users)
#! to define the problem to be solved,
#! and then calling the appropriate function on these constraints.
#! * The name of the function determines the **kind** of search to be executed
#!   (whether for a single permutation, or for a group, or for a canonical
#!    image, etc).  These functions are described in the rest of this chapter.
#! * Broadly speaking, constraints and/or refiners define properties that
#!   together specify the permutations that are valid solutions to the search
#!   problem.
#!   Constraints and refiners are described in
#!   Chapters&nbsp;<Ref Chap="Chapter_Constraints"/>
#!   and&nbsp;<Ref Chap="Chapter_Refiners"/>, respectively.


#! @Section The <C>VoleFind</C> record
#! @SectionLabel VoleFind

#! @Description
#!
#! <Ref Var="VoleFind"/> is a record that contains the functions providing the
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
#! @InsertChunk fail-none
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
#! gap> tuple_transport := Constraint.Transport([1,2,3], [1,2,4], OnTuples);;
#! gap> VoleFind.Rep(Constraint.InGroup(SymmetricGroup(4)), tuple_transport);
#! (3,4)
#! gap> VoleFind.Rep(AlternatingGroup(4), tuple_transport);
#! fail
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
#! gap> graph_auto := Constraint.Stabilise(JohnsonDigraph(4,2), OnDigraphs);;
#! gap> set_stab := Constraint.Stabilise([2,4,6], OnSets);;
#! gap> G := VoleFind.Group(graph_auto, set_stab, 6);;
#! gap> G = Group([ (2,4)(3,5), (1,3,5)(2,6,4) ]);
#! true
#! @EndExampleSession
#! Note that multiple groups-by-generators may be given as constraints:
#! @BeginExampleSession
#! gap> norm_PSL25 := Constraint.Normalise(PSL(2,5));;
#! gap> in_A6  := Constraint.InGroup(AlternatingGroup(6));;
#! gap> in_D12 := Constraint.InGroup(DihedralGroup(IsPermGroup, 12));;
#! gap> G := VoleFind.Group(in_A6, in_D12, norm_PSL25);;
#! gap> G = Group([ (1,3,5)(2,4,6) ]);
#! true
#! @EndExampleSession
DeclareGlobalFunction("VoleFind.Group");

#! @Arguments arguments...
#! @Returns A &GAP; right coset of a permutation group, or <K>fail</K>
#! @Description
#!
#! For this function, it is assumed, although not verified,
#! that for each constraint defined by the arguments,
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
#! @InsertChunk fail-none
#!
#! @InsertChunk need-lmp
#!
#! @InsertChunk valueoption
#! @BeginExampleSession
#! gap> tuple_transport := Constraint.Transport([1,2,3], [1,2,4], OnTuples);;
#! gap> VoleFind.Coset(Constraint.InGroup(SymmetricGroup(6)), tuple_transport);
#! RightCoset(Group([ (5,6), (4,5,6) ]),(3,4,6))
#! gap> VoleFind.Coset(AlternatingGroup(4), tuple_transport);
#! fail
#! gap> VoleFind.Coset(AlternatingGroup(5), Constraint.Transport(
#! > CycleDigraph(5), DigraphReverse(CycleDigraph(5)), OnDigraphs));
#! RightCoset(Group([ (1,2,3,4,5) ]),(1,4)(2,3))
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
#! of its orbit under the action of $G$.
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
#! The forthcoming details are crucial for obtaining
#! meaningful results from <Ref Func="VoleFind.Canonical"/>.
#!
#! **For users who
#! wish to canonise an object under an action listed in the table in
#! <Ref  Func="Constraint.Stabilise"/>, and who
#! do not wish to specify particular refiners,
#! it may be easier to use the simpler functions
#! <Ref Func="Vole.CanonicalPerm"/> and
#! <Ref Func="Vole.CanonicalImage"/>.**
#!
#! The first argument to <Ref Func="VoleFind.Canonical"/>
#! must be the group <A>G</A> in which to canonise.
#! The remaining <A>arguments</A> specify the rest of the canonisation problem;
#! in particular, they define the relevant object and action.
#!
#! The <A>arguments</A> that follow <A>G</A> may be given separately,
#! or in a list.
#! Each of the <A>arguments</A> must be an instance of a
#! <Ref  Func="Constraint.Stabilise"/> constraint,
#! either directly, or indirectly as an instance of
#! <Ref  Func="Constraint.Normalise"/> or
#! <Ref  Func="Constraint.Centralise"/>.
#! <B>Note that it is not permitted to include constraints of the kind
#! produced by</B>
#! <Ref  Func="Constraint.InGroup"/>.
#!
#! It is also permitted to include special kinds of refiners as arguments
#! to <Ref Func="VoleFind.Canonical"/>, although we do not yet document the
#! details of this,
#! since the theory and implementation is still under active development.
#! (Refiners will be documented in Chapter&nbsp;<Ref Chap="Chapter_Refiners"/>).
#!
#! For the following, we will suppose that <A>arguments...</A> is a list of
#! `k` constraints `Constraint.Stabilise(object_i,action_i)`,
#! for `i=1..k` in sequence.
#! Then <Ref Func="VoleFind.Canonical"/> canonises the `k`-tuple
#! `[object_1,...,object_k]`, where the action on the `i`-th coordinate is
#! `action_i`.
#!
#! In order to canonise in <A>G</A> another `k`-tuple of the same kind, such as
#! `[nextobject_1,...,nextobject_k]` with respect to the same action,
#! and in a way that is comparable to the first canonisation,
#! it is necessary to call <Ref Func="VoleFind.Canonical"/> with the same group
#! <A>G</A> followed by the <A>arguments...</A>
#! `Constraint.Stabilise(nextobject_i,action_i)`, <B>in the same order</B>.
#!
#! The result of <Ref Func="VoleFind.Canonical"/> is given as a record,
#! with the following components
#! (see the beginning of Section&nbsp;<Ref Sect="Section_interface_canonical"/>
#! for a definition of some of the following terms):
#! * `canonical`: a canonical permutation in <A>G</A> for the object, with
#!    respect to the action.
#! * `group`: the stabiliser of the object in <A>G</A>, under the action.
#!   This is computed as a by-product of canonisation.
#!
#! @InsertChunk valueoption
#!
#! @InsertChunk canonical-warning-session
#! @InsertChunk canonical-warning-ordering
#!
#! In the following examples, we first show how to canonise two cycle digraphs
#! in the alternating group of degree $6$, to find that they are indeed in the
#! same orbit of $A_6$ under the natural action.
#! We canonise them again in a different group, but this time as
#! **vertex-coloured** digraphs, by canonising them digraph simultaneously
#! with a corresponding colouring of the vertices.
#! @BeginExampleSession
#! gap> cycle := CycleDigraph(6);;
#! gap> reverse := DigraphReverse(cycle);;
#! gap> A6 := AlternatingGroup(6);;
#! gap> canon1 := VoleFind.Canonical(A6, Constraint.Stabilise(cycle, OnDigraphs));
#! rec( canonical := (1,3,4,6,5), group := Group([ (1,3,5)(2,4,6) ]) )
#! gap> canon2 := VoleFind.Canonical(A6,
#! >                                 Constraint.Stabilise(reverse, OnDigraphs));
#! rec( canonical := (1,4,5), group := Group([ (1,3,5)(2,4,6) ]) )
#! @EndExampleSession
#! Let us verify that the canonical permutations are indeed in $A_6$, and
#! that the `group` record component is indeed the stabiliser in $A_6$:
#! @BeginExampleSession
#! gap> SignPerm(canon1.canonical) = 1 and SignPerm(canon2.canonical) = 1
#! > and canon1.group = Vole.Stabiliser(A6, cycle, OnDigraphs)
#! > and canon2.group = Vole.Stabiliser(A6, reverse, OnDigraphs);
#! true
#! @EndExampleSession
#! Next, let's compare the canonical images of the digraphs,
#! to test whether they are in the same orbit of $A_6$.
#! et us also verify this result with <Ref Func="Vole.RepresentativeAction"/>:
#! @BeginExampleSession
#! gap> OnDigraphs(cycle, canon1.canonical)
#! > = OnDigraphs(reverse, canon2.canonical);
#! true
#! gap> Vole.RepresentativeAction(A6, cycle, reverse, OnDigraphs);
#! (1,5)(2,4)
#! @EndExampleSession
#! Next, we turn to vertex-coloured digraphs. This time, we will canonise
#! in the 2-transitive group `G` defined below. We first verify that `cycle`
#! and `reverse` are in the same orbit of `G`, as digraphs:
#! @BeginExampleSession
#! gap> G := Group([ (1,2,3,4,6), (1,4)(5,6) ]);;
#! gap> Vole.RepresentativeAction(G, cycle, reverse, OnDigraphs) <> fail;
#! true
#! @EndExampleSession
#! We will colour the vertices `1`, `3`, and `5` of `cycle` with colour `1`,
#! and the remainder with colour `2`; and we will colour the vertices of
#! `reverse` in the opposite way.
#! @BeginExampleSession
#! gap> colours1 := [[1,3,5],[2,4,6]];;
#! gap> colours2 := [[2,4,6],[1,3,5]];;
#! @EndExampleSession
#! We may therefore consider a vertex-coloured digraph as a pair
#! `[digraph,colours]`, with `colours` in the above form, and a permutation
#! group acts on vertex-coloured digraphs by acting via `OnDigraphs` on the
#! first component, and acting via `OnTuplesSets` on the second component.
#! @BeginExampleSession
#! gap> canon1 := VoleFind.Canonical(G,
#! >                                 Constraint.Stabilise(cycle, OnDigraphs),
#! >                                 Constraint.Stabilise(colours1, OnTuplesSets));
#! rec( canonical := (1,5,2,3,6), group := Group(()) )
#! gap> canon2 := VoleFind.Canonical(G,
#! >                                 Constraint.Stabilise(reverse, OnDigraphs),
#! >                                 Constraint.Stabilise(colours2, OnTuplesSets));
#! rec( canonical := (1,6,5,4,3), group := Group(()) )
#! @EndExampleSession
#! We find that these vertex-coloured digraphs are not in the same orbit of `G`:
#! @BeginExampleSession
#! gap> OnDigraphs(cycle, canon1.canonical)
#! > = OnDigraphs(reverse, canon2.canonical);
#! false
#! @EndExampleSession
#! However, if we canonise them again in the whole symmetric group of degree 6,
#! we find that they **are** in the same orbit of it as coloured digraphs:
#! @BeginExampleSession
#! gap> canon1 := VoleFind.Canonical(SymmetricGroup(6),
#! >                                 Constraint.Stabilise(cycle, OnDigraphs),
#! >                                 Constraint.Stabilise(colours1, OnTuplesSets));
#! rec( canonical := (1,5,2,3,4,6), group := Group([ (1,3,5)(2,4,6) ]) )
#! gap> canon2 := VoleFind.Canonical(SymmetricGroup(6),
#! >                                 Constraint.Stabilise(reverse, OnDigraphs),
#! >                                 Constraint.Stabilise(colours2, OnTuplesSets));
#! rec( canonical := (1,3)(2,5,6,4), group := Group([ (1,3,5)(2,4,6) ]) )
#! gap> OnDigraphs(cycle, canon1.canonical)
#! > = OnDigraphs(reverse, canon2.canonical);
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
#! >  Constraint.Normalise(Group([ (1,2) ]))
#! > );
#! (1,4)(2,3)
#! @EndExampleSession
#! Thus the canonical image of $\langle (1\,2) \rangle$ under this action of
#! $A_{4}$ is the group ${\langle (1\,2) \rangle}^{(1\,4)(2\,3)}$,
#! i.e. $\langle (3\,4) \rangle$.
#!
#! This second example shows how to compute a canonical permutation
#! for the pair $[S, D]$ under the specified componentwise action of $S_{4}$,
#! where $S$ is the set-of-sets $\{ \{1,2\}, \{1,4\}, \{2,3\}, \{3,4\} \}$,
#! and $D$ is the cycle digraph on four vertices:
#! @BeginExampleSession
#! gap> VoleFind.CanonicalPerm(SymmetricGroup(4),
#! >  Constraint.Stabilise([ [1,2], [1,4], [2,3], [3,4] ], OnSetsSets),
#! >  Constraint.Stabilise(CycleDigraph(4), OnDigraphs)
#! > );
#! (1,2,3)
#! @EndExampleSession
DeclareGlobalFunction("VoleFind.CanonicalPerm");
