#@local sets, tt, n, refs, G, H, d1, d2, GR, sA, sB, mems, p, F, F2, c1, c2, h
#@local mkset, mktup, img1, img2, hetimg, bruteConj, grps
#
# Tests for VoleRefiner.SetOf: the generic "set of refiners" refiner, which
# constrains a permutation to map the set of objects described by its member
# refiners onto another such set (the members may be reordered). We check it
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
gap> mkset := s -> BTKit_Refiner.SetStab(s);;
gap> QC_Check(List([1 .. 3], i -> QC_SetOf(IsPosInt)),
>   function(a, b, c)
>     local sets, n, G, H;
>     sets := [a, b, c];
>     n := Maximum(Flat([sets, 1]));
>     G := VoleFind.Group(SymmetricGroup(n), VoleRefiner.SetOf(List(sets, mkset)));
>     H := Stabilizer(SymmetricGroup(n), Set(sets, Set), OnSetsSets);
>     return G = H;
>   end);
true

# Setwise stabiliser of a family of tuples agrees with OnSetsTuples (randomised).
gap> mktup := t -> BTKit_Refiner.TupleStab(t);;
gap> QC_Check(List([1 .. 2], i -> QC_SetOf(IsPosInt)),
>   function(a, b)
>     local tt, n, G, H;
>     tt := [a, b];
>     n := Maximum(Flat([tt, 1]));
>     G := VoleFind.Group(SymmetricGroup(n), VoleRefiner.SetOf(List(tt, mktup)));
>     H := Stabilizer(SymmetricGroup(n), Set(tt), OnSetsTuples);
>     return G = H;
>   end);
true

# Duplicate members are redundant: the family is a set, not a multiset.
# (Regression: repeated objects must not impose multiset semantics.)
gap> G := VoleFind.Group(SymmetricGroup(2),
>      VoleRefiner.SetOf(List([[2], [2], [1]], BTKit_Refiner.SetStab)));;
gap> G = Stabilizer(SymmetricGroup(2), Set([[1], [2]]), OnSetsSets);
true
gap> G = SymmetricGroup(2);
true

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

#
gap> STOP_TEST("onset.tst");
