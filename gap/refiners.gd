# Vole: Backtrack search in permutation groups with graphs
# A GAP package by Mun See Chang, Christopher Jefferson, and Wilf A. Wilson.
#
# SPDX-License-Identifier: MPL-2.0
#
# Declarations: Vole refiners

#! @Chapter Refiners in &Vole;
#! @ChapterLabel Refiners

#! @Section Refiners

#! Refiners in &Vole; are still a work in progress, and are not yet properly 
#! documented.
#! Please check back in the next version.

# There can be multiple refiners implemented for the same constraint
# with different tradeoffs, and also refiners implemented for special cases
# (such as symmetric and alternating groups). In general most users will want to
# use provide constraints rather than refiners, and let &Vole; choose
#! appropriate refiners for the given constraints.


#! @Section The <C>VoleRefiner</C> record

#! @Description
#!
#! <C>VoleRefiner</C> is a record that contains all of the refiners that are
#! included in &Vole;.
#!
#! &GraphBacktracking; and &BacktrackKit; refiners are
#! also compatible with &Vole;.
#! @BeginExampleSession
#! gap> LoadPackage("vole", false);;
#! gap> Set(RecNames(VoleRefiner));
#! [ "DigraphStab", "DigraphTransporter", "FromConstraint", "InSymmetricGroup",
#!   "MultisetOf", "SetOf", "SetSetStab", "SetSetTransporter", "SetStab",
#!   "SetTransporter", "SetTupleStab", "SetTupleTransporter", "TupleOf",
#!   "TupleStab", "TupleTransporter" ]
#! @EndExampleSession
DeclareGlobalVariable("VoleRefiner");
# TODO When we require GAP >= 4.12, use GlobalName rather than GlobalVariable
InstallValue(VoleRefiner, rec());


DeclareRepresentation("IsVoleRefiner", IsRefiner, ["constraint"]);
BindGlobal("VoleRefinerFamily", NewFamily("VoleRefinerFamily", IsVoleRefiner));
BindGlobal("VoleRefinerType", NewType(VoleRefinerFamily, IsVoleRefiner));


#! @Section &Vole; refiners via the <C>VoleRefiner</C> record
#! @SectionLabel providedrefs

#! @Arguments x
#! @Returns A &Vole; refiner
#! @Description
#! Something
#! @BeginExampleSession
#! gap> true;
#! true
#! @EndExampleSession
DeclareGlobalFunction("VoleRefiner.InSymmetricGroup");


#! @BeginGroup Set
#! @Arguments s
#! @Returns A &Vole; refiner
#! @Description
#! Something
DeclareGlobalFunction("VoleRefiner.SetStab");
#! @EndGroup
#! @Arguments s, t
#! @Group Set
#! @BeginExampleSession
#! gap> true;
#! true
#! @EndExampleSession
DeclareGlobalFunction("VoleRefiner.SetTransporter");


#! @BeginGroup Tuple
#! @Arguments s
#! @Returns A &Vole; refiner
#! @Description
#! Something
DeclareGlobalFunction("VoleRefiner.TupleStab");
#! @EndGroup
#! @Arguments s, t
#! @Group Tuple
#! @BeginExampleSession
#! gap> true;
#! true
#! @EndExampleSession
DeclareGlobalFunction("VoleRefiner.TupleTransporter");


#! @BeginGroup SetSet
#! @Arguments s
#! @Returns A &Vole; refiner
#! @Description
#! Something
DeclareGlobalFunction("VoleRefiner.SetSetStab");
#! @EndGroup
#! @Arguments s, t
#! @Group SetSet
#! @BeginExampleSession
#! gap> true;
#! true
#! @EndExampleSession
DeclareGlobalFunction("VoleRefiner.SetSetTransporter");


#! @BeginGroup SetTuple
#! @Arguments s
#! @Returns A &Vole; refiner
#! @Description
#! Something
DeclareGlobalFunction("VoleRefiner.SetTupleStab");
#! @EndGroup
#! @Arguments s, t
#! @Group SetTuple
#! @BeginExampleSession
#! gap> true;
#! true
#! @EndExampleSession
DeclareGlobalFunction("VoleRefiner.SetTupleTransporter");

#! @BeginGroup Digraph
#! @Arguments s
#! @Returns A &Vole; refiner
#! @Description
#! Something
DeclareGlobalFunction("VoleRefiner.DigraphStab");
#! @EndGroup
#! @Arguments s, t
#! @Group Digraph
#! @BeginExampleSession
#! gap> true;
#! true
#! @EndExampleSession
DeclareGlobalFunction("VoleRefiner.DigraphTransporter");


#! @Section Combining refiners: sets, multisets, and tuples of refiners
#! @SectionLabel combinators

#! The refiners <Ref Func="VoleRefiner.SetOf"/>,
#! <Ref Func="VoleRefiner.MultisetOf"/>, and <Ref Func="VoleRefiner.TupleOf"/>
#! are <E>combinators</E>: each is built from a nonempty list of other refiners,
#! its <E>members</E>, and constrains a permutation by what it does to the whole
#! collection of objects that those members describe.
#!
#! Whereas <Ref Func="VoleRefiner.SetStab"/> stabilises one concrete set of
#! points, and <Ref Func="VoleRefiner.SetSetStab"/> one concrete set of sets,
#! these combinators stabilise a set (or multiset, or tuple) whose members are
#! described by <E>arbitrary</E> refiners, of any kind, possibly of different
#! kinds, and possibly themselves combinators. For example, with normaliser or
#! conjugacy members one obtains the setwise stabiliser of a <E>set of groups</E>
#! under conjugation, which no single built-in action provides.
#!
#! The three combinators differ only in how the members' objects are gathered:
#! <List>
#! <Item><Ref Func="VoleRefiner.SetOf"/> treats them as a <E>set</E> (order and
#!   repetition are ignored; the members may be matched up in any order);</Item>
#! <Item><Ref Func="VoleRefiner.MultisetOf"/> treats them as a <E>multiset</E>
#!   (order is ignored, but repetition is significant); and</Item>
#! <Item><Ref Func="VoleRefiner.TupleOf"/> treats them as an ordered
#!   <E>tuple</E> (position <M>i</M> is mapped to position <M>i</M>).</Item>
#! </List>
#!
#! When every member is a stabiliser, the result is a stabiliser (a group);
#! when the members are transporters, it is the corresponding transporter (a
#! coset, or empty). The family is <E>type-aware</E>: because &GAP; represents
#! the set <C>[2, 4]</C> and the tuple <C>[2, 4]</C> by the same list, each
#! member's object is tagged by its kind, so a set member is never accidentally
#! identified with a tuple member describing the same list.
#!
#! The members must be &BacktrackKit; or &GraphBacktracking; refiners (such as
#! those in the <C>BTKit_Refiner</C> and <C>GB_Con</C> records), because the
#! combinator reads each member's graph through its refine hooks. A native &Vole;
#! refiner from the <Ref Var="VoleRefiner"/> record builds its graph in Rust,
#! exposes no such hooks, and so cannot be a member.

#! @Arguments refiners
#! @Returns A &Vole; refiner
#! @Description
#! Returns a refiner for the <E>set</E> of the objects that the member
#! <A>refiners</A> describe: a permutation is accepted if and only if it maps the
#! set of the members' source objects onto the set of their result objects, where
#! the members may be matched up in any order.
#!
#! Since a set has no repeated elements, two members that describe the identical
#! object are rejected with an error; use <Ref Func="VoleRefiner.MultisetOf"/> if
#! the repetition is intended.
#!
#! The first example below is the setwise stabiliser of the set of sets
#! <M>\{\{1,2,3\}, \{3,4\}\}</M>; the second is the setwise stabiliser of the set
#! of groups <M>\{\langle(1,2)\rangle, \langle(3,4)\rangle\}</M> under
#! conjugation.
#! @BeginExampleSession
#! gap> setofsets := VoleRefiner.SetOf(
#! >      [BTKit_Refiner.SetStab([1, 2, 3]), BTKit_Refiner.SetStab([3, 4])]);;
#! gap> G := VoleFind.Group(SymmetricGroup(4), setofsets);;
#! gap> G = Stabilizer(SymmetricGroup(4), Set([[1, 2, 3], [3, 4]]), OnSetsSets);
#! true
#! gap> Size(G);
#! 2
#! gap> grps := [Group((1, 2)), Group((3, 4))];;
#! gap> conj := VoleRefiner.SetOf(List(grps, GB_Con.NormaliserSimple2));;
#! gap> N := VoleFind.Group(SymmetricGroup(4), conj);;
#! gap> N = Group(Filtered(SymmetricGroup(4),
#! >              p -> Set(grps, g -> g ^ p) = Set(grps)));
#! true
#! gap> Size(N);
#! 8
#! @EndExampleSession
DeclareGlobalFunction("VoleRefiner.SetOf");

#! @Arguments refiners
#! @Returns A &Vole; refiner
#! @Description
#! As <Ref Func="VoleRefiner.SetOf"/>, but for the <E>multiset</E> of the objects
#! that the member <A>refiners</A> describe: repeated objects are kept, and a
#! permutation is accepted only if it preserves their multiplicities. Duplicate
#! members are therefore permitted, and meaningful.
#!
#! In the example, the object <M>\{1,2\}</M> occurs twice and <M>\{3,4\}</M> once,
#! so a permutation that swapped these two sets would not preserve the
#! multiplicities and is excluded; the stabiliser is thus smaller than for the
#! corresponding set <M>\{\{1,2\}, \{3,4\}\}</M>, whose two members may be
#! swapped.
#! @BeginExampleSession
#! gap> mems := List([[1, 2], [1, 2], [3, 4]], BTKit_Refiner.SetStab);;
#! gap> M := VoleFind.Group(SymmetricGroup(4), VoleRefiner.MultisetOf(mems));;
#! gap> M = Group(Filtered(SymmetricGroup(4),
#! >              p -> SortedList(List([[1, 2], [1, 2], [3, 4]], s -> OnSets(s, p)))
#! >                 = SortedList([[1, 2], [1, 2], [3, 4]])));
#! true
#! gap> Size(M);
#! 4
#! @EndExampleSession
DeclareGlobalFunction("VoleRefiner.MultisetOf");

#! @Arguments refiners
#! @Returns A &Vole; refiner
#! @Description
#! Returns a refiner for the ordered <E>tuple</E> of the objects that the member
#! <A>refiners</A> describe: a permutation is accepted if and only if it maps the
#! source object of each member to the result object of the <E>same</E> member,
#! position by position.
#!
#! On its own this is just the intersection of the member refiners, and so is of
#! little use directly. Its purpose is to be a member of a
#! <Ref Func="VoleRefiner.SetOf"/> or <Ref Func="VoleRefiner.MultisetOf"/>, in
#! order to describe a (multi)set of <E>tuples</E>: the tuples may be matched up
#! in any order, but the entries within each tuple are ordered and so may not.
#!
#! In the example, <C>setoftuples</C> is the setwise stabiliser of the set of
#! ordered pairs <M>\{(1,2), (3,4)\}</M>. The pairs may be swapped — by the
#! permutation <M>(1,3)(2,4)</M>, which sends <M>(1,2)</M> to <M>(3,4)</M> — but,
#! because each pair is ordered, no permutation may reverse a pair; so the
#! stabiliser has order <M>2</M>, smaller than the order <M>8</M> it would have
#! were the pairs unordered sets.
#! @BeginExampleSession
#! gap> tup := VoleRefiner.TupleOf(
#! >      [BTKit_Refiner.SetStab([1, 2]), BTKit_Refiner.SetStab([3, 4, 5])]);;
#! gap> VoleFind.Group(SymmetricGroup(5), tup)
#! >    = Intersection(Stabilizer(SymmetricGroup(5), [1, 2], OnSets),
#! >                   Stabilizer(SymmetricGroup(5), [3, 4, 5], OnSets));
#! true
#! gap> pair := t -> VoleRefiner.TupleOf(
#! >      [BTKit_Refiner.TupleStab([t[1]]), BTKit_Refiner.TupleStab([t[2]])]);;
#! gap> setoftuples := VoleRefiner.SetOf([pair([1, 2]), pair([3, 4])]);;
#! gap> G := VoleFind.Group(SymmetricGroup(4), setoftuples);;
#! gap> G = Stabilizer(SymmetricGroup(4), Set([[1, 2], [3, 4]]), OnSetsTuples);
#! true
#! gap> Size(G);
#! 2
#! @EndExampleSession
DeclareGlobalFunction("VoleRefiner.TupleOf");

#! @Subsection A worked example: pairs of transformations up to conjugacy
#!
#! The combinators earn their keep when no built-in &GAP; action expresses the
#! object you want. Here we classify <E>pairs of transformations</E> up to
#! simultaneous conjugacy by the symmetric group: the pairs <M>\{a, b\}</M> and
#! <M>\{a', b'\}</M> are equivalent when some <M>g \in S_n</M> conjugates one
#! onto the other, that is <M>\{a^g, b^g\} = \{a', b'\}</M>.
#!
#! A conjugacy refiner together with <C>VoleFind.CanonicalPerm</C> yields a
#! canonical form. For a single transformation <C>t</C>, the permutation
#! <C>c</C> below sends <C>t</C> to a canonical representative of its conjugacy
#! class; collecting <C>t ^ c</C> over the whole monoid and taking the set
#! therefore counts the classes (the OEIS sequence A001372, though we assume
#! nothing — we just compute it).
#! Wrapping two such refiners in a <Ref Func="VoleRefiner.SetOf"/> canonises the
#! unordered <E>pair</E> instead: one and the same <C>c</C> is applied to both
#! members.
#!
#! The pairs are too numerous to canonise all <M>|M|^2</M> of them, but we need
#! not. Every pair-class has a representative whose <E>first</E> member is already
#! canonical (conjugate the pair by the permutation that canonises one member), so
#! it suffices to range the first member over the class representatives and the
#! second over the whole monoid. One may <E>not</E> canonise both members in
#! advance: the permutation that canonises a pair need not canonise either member
#! on its own. For instance the pair of distinct transpositions
#! <M>\{(1,2), (1,3)\}</M> has no conjugate in which both members equal the single
#! canonical transposition, since conjugation keeps them distinct — so building
#! pairs only from canonical members would miss that class.
#!
#! @BeginExampleSession
#! gap> n := 3;;
#! gap> S := SymmetricGroup(n);;
#! gap> M := Elements(FullTransformationMonoid(n));;
#! gap> canon1 := t -> t ^ VoleFind.CanonicalPerm(S,
#! >                          GB_Con.TransformationConjugacy(t, t));;
#! gap> singles := Set(M, canon1);;
#! gap> Length(singles);   # transformations up to conjugacy
#! 7
#! gap> canonPair := function(a, b)
#! >      local c;
#! >      c := VoleFind.CanonicalPerm(S, VoleRefiner.SetOf(
#! >             [GB_Con.TransformationConjugacy(a, a),
#! >              GB_Con.TransformationConjugacy(b, b)]));
#! >      return Set([a ^ c, b ^ c]);
#! >    end;;
#! gap> pairs := Set(Filtered(Cartesian(singles, M), p -> p[1] <> p[2]),
#! >                 p -> canonPair(p[1], p[2]));;
#! gap> Length(pairs);   # distinct unordered pairs up to simultaneous conjugacy
#! 67
#! gap> Length(pairs) = Length(Orbits(S, Combinations(M, 2),
#! >        {p, g} -> Set([p[1] ^ g, p[2] ^ g])));   # cross-check against GAP
#! true
#! @EndExampleSession


#! @Section Choosing a refiner for a given constraint


#! @Arguments constraint
#! @Returns A &Vole;, &GraphBacktracking;, or &BacktrackKit; refiner
#! @Description
#! Something.
#! @BeginExampleSession
#! gap> true;
#! true
#! @EndExampleSession
DeclareGlobalFunction("VoleRefiner.FromConstraint");
