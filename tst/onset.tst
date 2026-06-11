#@local sets, tt, n, refs, G, H, d1, d2, GR, sA, sB, mems, p, F, F2, c1, c2, h
#@local mkset, mktup, img1, img2, hetimg, bruteConj, grps
#@local bruteMSet, fam, mkpair, tup, set, bruteSetTup, prs, mkgp
#
# Tests for VoleRefiner.SetOf / MultisetOf / TupleOf: the generic combinators
# that constrain a permutation to map the set / multiset / tuple of objects
# described by their member refiners onto another such family. We check them
# against GAP's built-in set-of-X actions and by brute force.
#
gap> START_TEST("onset.tst");
gap> ReadPackage("vole", "tst/test_functions.g");
true

# A small GraphBacktracking refiner that pushes a single digraph as a graph
# record, so the graph-edge path of the widget is exercised.
gap> GR := D -> Objectify(GBRefinerType, rec(
>      name := "GraphRec",
>      largest_required_point := DigraphNrVertices(D),
>      constraint := Constraint.Stabilise(D, OnDigraphs),
>      refine := rec(initialise := function(ps, brb) return rec(graph := D); end)));;

# Setwise stabiliser of a family of sets agrees with OnSetsSets (randomised).
# SetOf rejects duplicate members, so the random family is made duplicate-free
# first; this is exactly the set { a, b, c }, which is what OnSetsSets sees too.
gap> mkset := s -> BTKit_Refiner.SetStab(s);;
gap> QC_Check(List([1 .. 3], i -> QC_SetOf(IsPosInt)),
>   function(a, b, c)
>     local sets, n, G, H;
>     sets := DuplicateFreeList(List([a, b, c], Set));
>     n := Maximum(Flat([sets, 1]));
>     G := VoleFind.Group(SymmetricGroup(n), VoleRefiner.SetOf(List(sets, mkset)));
>     H := Stabilizer(SymmetricGroup(n), Set(sets), OnSetsSets);
>     return G = H;
>   end);
true

# Setwise stabiliser of a family of tuples agrees with OnSetsTuples (randomised).
gap> mktup := t -> BTKit_Refiner.TupleStab(t);;
gap> QC_Check(List([1 .. 2], i -> QC_SetOf(IsPosInt)),
>   function(a, b)
>     local tt, n, G, H;
>     tt := DuplicateFreeList([a, b]);
>     n := Maximum(Flat([tt, 1]));
>     G := VoleFind.Group(SymmetricGroup(n), VoleRefiner.SetOf(List(tt, mktup)));
>     H := Stabilizer(SymmetricGroup(n), Set(tt), OnSetsTuples);
>     return G = H;
>   end);
true

# SetOf is a genuine SET, not a multiset: duplicate members (the same typed
# object) are rejected with an error rather than silently merged. (Widen the
# screen so the error message prints on one line, for a stable comparison.)
gap> n := SizeScreen()[1];; SizeScreen([4096]);;
gap> VoleRefiner.SetOf(List([[2], [2], [1]], BTKit_Refiner.SetStab));
Error, VoleRefiner.SetOf: members 1 and 2 describe the same object, but a set does not accept duplicate members; remove the duplicate, or use VoleRefiner.MultisetOf to keep repeated objects
gap> SizeScreen([n]);;

# MultisetOf keeps repeats: a repeated object must map to an object of the same
# multiplicity, so the stabiliser preserves multiplicities. Checked against a
# brute-force multiset comparison (SortedList keeps duplicates; Set would drop
# them).
gap> bruteMSet := {n, fam, act} -> Group(Filtered(SymmetricGroup(n),
>      p -> SortedList(List(fam, x -> act(x, p)))
>         = SortedList(List(fam, x -> act(x, ())))));;
gap> fam := [[1, 2], [1, 2], [3], [2, 3]];;
gap> VoleFind.Group(SymmetricGroup(4),
>      VoleRefiner.MultisetOf(List(fam, BTKit_Refiner.SetStab)))
>    = bruteMSet(4, fam, OnSets);
true

# A repeated singleton pins its point: {{1}, {1}, {2}} on S_2 is trivial.
gap> Size(VoleFind.Group(SymmetricGroup(2),
>      VoleRefiner.MultisetOf(List([[1], [1], [2]], BTKit_Refiner.SetStab))));
1

# With no repeats, MultisetOf and SetOf coincide.
gap> mems := List([[1, 2], [3], [2, 3, 4]], BTKit_Refiner.SetStab);;
gap> VoleFind.Group(SymmetricGroup(4), VoleRefiner.MultisetOf(mems))
>    = VoleFind.Group(SymmetricGroup(4), VoleRefiner.SetOf(mems));
true

# A multiset transporter with no solution returns fail.
gap> mems := List([1 .. 2],
>      i -> BTKit_Refiner.SetTransporter([[1, 2], [3, 4]][i], [[1, 2, 3], [4]][i]));;
gap> VoleFind.Rep(SymmetricGroup(4), VoleRefiner.MultisetOf(mems));
fail

# A singleton family reduces to the member's own constraint.
gap> G := VoleFind.Group(SymmetricGroup(4),
>           VoleRefiner.SetOf([BTKit_Refiner.SetStab([1, 2, 3])]));;
gap> G = Stabilizer(SymmetricGroup(4), [1, 2, 3], OnSets);
true

# Set of digraphs: matches OnSetsDigraphs and the existing SetDigraphs refiner.
gap> d1 := Digraph([[2], [1], []]);; d2 := Digraph([[], [3], [2]]);;
gap> G := VoleFind.Group(SymmetricGroup(3), VoleRefiner.SetOf([GR(d1), GR(d2)]));;
gap> G = Stabilizer(SymmetricGroup(3), Set([d1, d2]), OnSetsDigraphs);
true
gap> G = VoleFind.Group(SymmetricGroup(3), GB_Con.SetDigraphs([d1, d2], [d1, d2]));
true

# Heterogeneous family (a set and a tuple), checked by brute force. The family
# is type-aware: a set is never identified with a tuple, even when GAP would
# represent them by the same list. The brute reference tags each image by its
# action accordingly.
gap> hetimg := {a, b, p} -> Set([["OnSets", OnSets(a, p)], ["OnTuples", OnTuples(b, p)]]);;
gap> mems := [BTKit_Refiner.SetStab([1, 2]), BTKit_Refiner.TupleStab([3, 4, 5])];;
gap> G := VoleFind.Group(SymmetricGroup(5), VoleRefiner.SetOf(mems));;
gap> G = Group(Filtered(SymmetricGroup(5), p -> hetimg([1,2],[3,4,5],p) = hetimg([1,2],[3,4,5],())));
true

# Heterogeneous with a *possible* list-level cross-match: set {3,4} and tuple
# [2,4]. Untyped, the permutation (2,3) sends the set to [2,4] and the tuple to
# [3,4], so an untyped check would wrongly admit it. Type-aware, a set is not a
# tuple, so the stabiliser is trivial. (Regression for the set/tuple list
# representation collision.)
gap> mems := [BTKit_Refiner.SetStab([3, 4]), BTKit_Refiner.TupleStab([2, 4])];;
gap> G := VoleFind.Group(SymmetricGroup(4), VoleRefiner.SetOf(mems));;
gap> Size(G);
1
gap> G = Group(Filtered(SymmetricGroup(4), p -> hetimg([3,4],[2,4],p) = hetimg([3,4],[2,4],())));
true

# Transporter of one family onto another (a representative is found and valid).
gap> sA := [[1, 2], [3, 4]];; sB := [[1, 3], [2, 4]];;
gap> mems := List([1 .. 2], i -> BTKit_Refiner.SetTransporter(sA[i], sB[i]));;
gap> p := VoleFind.Rep(SymmetricGroup(4), VoleRefiner.SetOf(mems));;
gap> p <> fail and OnSetsSets(Set(sA, Set), p) = Set(sB, Set);
true

# Transporter with no solution returns fail.
gap> sA := [[1, 2], [3, 4]];; sB := [[1, 2, 3], [4]];;
gap> mems := List([1 .. 2], i -> BTKit_Refiner.SetTransporter(sA[i], sB[i]));;
gap> VoleFind.Rep(SymmetricGroup(4), VoleRefiner.SetOf(mems));
fail

# Canonical image is invariant across the group action, and distinguishes
# families that are not in the same orbit.
gap> mkset := fam -> VoleRefiner.SetOf(List(fam, BTKit_Refiner.SetStab));;
gap> F := [[1, 2, 3], [3, 4], [4, 5, 6]];;
gap> ForAll([(), (1, 4)(2, 5)(3, 6), (1, 2, 3, 4, 5, 6)], function(h)
>      local F2, c1, c2;
>      F2 := List(F, s -> OnSets(s, h));
>      c1 := VoleFind.CanonicalPerm(SymmetricGroup(6), mkset(F));
>      c2 := VoleFind.CanonicalPerm(SymmetricGroup(6), mkset(F2));
>      return Set(F, s -> OnSets(s, c1)) = Set(F2, s -> OnSets(s, c2));
>    end);
true
gap> c1 := VoleFind.CanonicalPerm(SymmetricGroup(6), mkset([[1, 2], [3, 4], [5, 6]]));;
gap> c2 := VoleFind.CanonicalPerm(SymmetricGroup(6), mkset([[1, 2], [2, 3], [4, 5]]));;
gap> Set([[1, 2], [3, 4], [5, 6]], s -> OnSets(s, c1))
>      <> Set([[1, 2], [2, 3], [4, 5]], s -> OnSets(s, c2));
true

# Set of groups under conjugation: OnSet over normaliser refiners. This is the
# main case that needs per-node recall (orbital members emit new graphs as
# points are fixed); the simple member only works at the root. Both must give
# the setwise stabiliser of the groups under conjugation.
gap> bruteConj := {n, grps} -> Group(Filtered(SymmetricGroup(n),
>      p -> Set(grps, G -> G ^ p) = Set(grps)));;
gap> grps := [Group((1,2)), Group((3,4))];;
gap> VoleFind.Group(SymmetricGroup(4), VoleRefiner.SetOf(
>      List(grps, GB_Con.NormaliserSimple2))) = bruteConj(4, grps);
true
gap> VoleFind.Group(SymmetricGroup(4), VoleRefiner.SetOf(
>      List(grps, g -> GB_Con.GroupConjugacyOrbital(g, g)))) = bruteConj(4, grps);
true
gap> grps := [Group((1,2,3)), Group((1,2,4))];;
gap> VoleFind.Group(SymmetricGroup(4), VoleRefiner.SetOf(
>      List(grps, g -> GB_Con.GroupConjugacyOrbital(g, g)))) = bruteConj(4, grps);
true
gap> grps := [Group([(1,2,3,4),(1,3)]), Group([(3,4,5,6),(3,5)])];;
gap> VoleFind.Group(SymmetricGroup(6), VoleRefiner.SetOf(
>      List(grps, g -> GB_Con.GroupConjugacyOrbital(g, g)))) = bruteConj(6, grps);
true

# TupleOf is ordered: standalone it is merely the intersection of its members.
gap> G := VoleFind.Group(SymmetricGroup(5), VoleRefiner.TupleOf(
>      [BTKit_Refiner.SetStab([1, 2]), BTKit_Refiner.SetStab([3, 4])]));;
gap> G = Intersection(Stabilizer(SymmetricGroup(5), [1, 2], OnSets),
>                     Stabilizer(SymmetricGroup(5), [3, 4], OnSets));
true

# Ordered vs unordered: with the same two members, TupleOf pins the positions
# while SetOf may swap them, so the tuple stabiliser is strictly smaller.
gap> tup := VoleRefiner.TupleOf(
>      [BTKit_Refiner.SetStab([1, 2]), BTKit_Refiner.SetStab([3, 4])]);;
gap> set := VoleRefiner.SetOf(
>      [BTKit_Refiner.SetStab([1, 2]), BTKit_Refiner.SetStab([3, 4])]);;
gap> Size(VoleFind.Group(SymmetricGroup(4), tup));
4
gap> Size(VoleFind.Group(SymmetricGroup(4), set));
8

# TupleOf of transporters transports each member in order; the representative
# found is valid.
gap> tup := VoleRefiner.TupleOf([BTKit_Refiner.SetTransporter([1, 2], [2, 3]),
>                                BTKit_Refiner.SetTransporter([3, 4], [1, 4])]);;
gap> p := VoleFind.Rep(SymmetricGroup(4), tup);;
gap> p <> fail and OnSets([1, 2], p) = [2, 3] and OnSets([3, 4], p) = [1, 4];
true

# The point of TupleOf is to live inside a set: a SET of TUPLES. Building each
# pair with TupleOf and taking SetOf agrees with OnSetsTuples.
gap> mkpair := t -> VoleRefiner.TupleOf(List(t, x -> BTKit_Refiner.TupleStab([x])));;
gap> tt := [[1, 2], [3, 4]];;
gap> VoleFind.Group(SymmetricGroup(4), VoleRefiner.SetOf(List(tt, mkpair)))
>    = Stabilizer(SymmetricGroup(4), Set(tt), OnSetsTuples);
true

# A MULTISET of TUPLES: {(1,2), (1,2), (3,4)} as ordered pairs. The repeated
# pair (1,2) must keep its multiplicity, so the only symmetry is the identity.
gap> tt := [[1, 2], [1, 2], [3, 4]];;
gap> VoleFind.Group(SymmetricGroup(4), VoleRefiner.MultisetOf(List(tt, mkpair)))
>    = Group(Filtered(SymmetricGroup(4),
>        p -> SortedList(List(tt, t -> [t[1] ^ p, t[2] ^ p])) = SortedList(tt)));
true

# Type-aware even for composites: a TupleOf member and a SetStab member over the
# same points are different family elements, never merged (cf. the set/tuple
# list-representation collision above).
gap> mems := [VoleRefiner.TupleOf(
>               [BTKit_Refiner.TupleStab([3]), BTKit_Refiner.TupleStab([4])]),
>             BTKit_Refiner.SetStab([3, 4])];;
gap> G := VoleFind.Group(SymmetricGroup(4), VoleRefiner.SetOf(mems));;
gap> G = Group(Filtered(SymmetricGroup(4),
>        p -> Set([["t", [3 ^ p, 4 ^ p]], ["s", OnSets([3, 4], p)]])
>           = Set([["t", [3, 4]], ["s", [3, 4]]])));
true

# Set of TUPLES of groups under simultaneous conjugation: a set of pairs
# {[G1, G2], [G3, G4]}, each pair conjugated as an ordered unit but the pairs may
# be swapped. This nests orbital conjugacy members (per-node recall) inside a
# TupleOf inside a SetOf; checked by brute force.
gap> bruteSetTup := {n, prs} -> Group(Filtered(SymmetricGroup(n),
>      p -> Set(prs, pr -> List(pr, g -> g ^ p)) = Set(prs)));;
gap> prs := [[Group((1,2)), Group((3,4))], [Group((1,2,3)), Group((1,2,4))]];;
gap> mkgp := pr -> VoleRefiner.TupleOf(List(pr, g -> GB_Con.GroupConjugacyOrbital(g, g)));;
gap> VoleFind.Group(SymmetricGroup(4), VoleRefiner.SetOf(List(prs, mkgp)))
>    = bruteSetTup(4, prs);
true

#
gap> STOP_TEST("onset.tst");
