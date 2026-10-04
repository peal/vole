#@local edges, frucht, neigh, r, D, con_stab, con_trans, p
#@local G, H, K, x, H2, res, s2
gap> START_TEST("basic.tst");
gap> LoadPackage("vole", false);
true
gap> ReadPackage("vole", "tst/test_functions.g");
true

#
gap> edges := [[1,2], [1,3], [1,4], [2,5], [2,6], [4,7], [4,8], [5,9], [5,10], [6,11],
>         [6,12], [3,7], [7,8], [8,12], [12,11], [11,9], [9,10], [10,3]];;
gap> frucht := DigraphSymmetricClosure(DigraphByEdges(edges));;
gap> neigh := OutNeighbours(frucht);;
gap> VoleComp(5, [Constraint.Stabilize([2,3,4], OnSets), Constraint.Stabilize([3,4,5], OnSets)]);
gap> VoleComp(7, [Constraint.Stabilize([2,3,4], OnSets), Constraint.Stabilize([5], OnTuples)]);
gap> VoleComp(5, [Constraint.Stabilize([2,3,4], OnSets), Constraint.Stabilize([5], OnTuples)]);
gap> VoleComp(5, [Constraint.Stabilize([[2,4],[1,3],[2,4],[1,3],[]], OnDigraphs)]);
gap> VoleComp(5, [BTKit_Refiner.SetStab([2,3])]);
gap> VoleComp(12, [Constraint.Stabilize(neigh, OnDigraphs)]);

# Bug found by Mun See Chang and fixed in commit 11e06f
gap> VoleComp(7, [GB_Con.NormaliserSimple(Group([(1,2,3,4), (1,2), (5,6,7)]))]);

# Another bug found by Mun See Chang
gap> VoleFind.Rep(BTKit_Refiner.IdentityForTesting(0) : points := 6);;
gap> _Vole.LastStats.search_nodes;
6
gap> VoleFind.Rep(BTKit_Refiner.IdentityForTesting(3) : points := 6);;
gap> _Vole.LastStats.search_nodes;
40
gap> VoleFind.Rep(BTKit_Refiner.IdentityForTesting(6) : points := 6);;
gap> _Vole.LastStats.search_nodes;
518

#
gap> r := VoleFind.Rep([Constraint.Transport([2,3,4,5], [1,3,5,4], OnTuples)] : points := 5);;
gap> Assert(0,r = (1,2)(4,5));
gap> r := VoleFind.Rep(Constraint.Transport([2,3,4], [1,4,5], OnTuples) : points := 5);;
gap> Assert(0, OnSets([2,3,4], r) = [1,4,5]);

#
gap> VoleFind.Group(VoleRefiner.InSymmetricGroup([2,3,4])) = SymmetricGroup([2,3,4]);
true
gap> VoleFind.Group(VoleRefiner.InSymmetricGroup([2,4,8,6])) = SymmetricGroup([2,4,6,8]);
true
gap> VoleFind.Group(VoleRefiner.InSymmetricGroup([])) = Group(());
true

#
gap> VoleFind.Group(Constraint.IsEven, 6) = AlternatingGroup(6);
true
gap> SignPerm(VoleFind.Rep(Constraint.IsOdd, 6)) = -1;
true
gap> VoleFind.Rep(Constraint.IsOdd, AlternatingGroup(6));
fail
gap> VoleFind.Group(AlternatingGroup(20)) = AlternatingGroup(20);
true

# https://github.com/peal/vole/issues/15
gap> D := CycleDigraph(5);;
gap> con_stab := Constraint.Stabilize(D, OnDigraphs);;
gap> con_trans := Constraint.Transport(D, D, OnDigraphs);;
gap> p := VoleFind.Rep(con_stab);;
gap> OnDigraphs(D, p) = D;
true
gap> p := VoleFind.Rep(con_trans);;
gap> OnDigraphs(D, p) = D;
true

#
gap> IsTrivial(VoleFind.Group(Constraint.LargestMovedPoint(0)));
true
gap> IsTrivial(VoleFind.Group(Constraint.LargestMovedPoint(1)));
true

# Deterministic versions of the quickcheck tests from the other test files,
# so the core native API is still checked (against GAP where possible) when
# quickcheck is not installed. The quickcheck tests cross-check the same
# properties much more heavily.
gap> G := SymmetricGroup(7);;
gap> VoleTestCanonical(G, [2,3,5], s -> Constraint.Stabilize(s, OnSets), OnSets);
true
gap> VoleTestCanonical(G, [[1,2],[3,4,5]], x -> Constraint.Stabilize(x, OnSetsSets), OnSetsSets);
true
gap> VoleTestCanonical(G, [[1,2],[3,5]], x -> Constraint.Stabilize(x, OnSetsTuples), OnSetsTuples);
true
gap> VoleTestCanonical(G, Group([(1,2,3),(4,5,6)]), x -> Constraint.Stabilize(x, OnPoints), OnPoints);
true

# Subgroup intersection
gap> H := Group([(1,2,3),(1,4)(5,6)]);;
gap> K := Group([(2,3,4),(3,4)(5,6)]);;
gap> VoleFind.Group(GB_Con.InGroupSimple(H), GB_Con.InGroupSimple(K)) = Intersection(H, K);
true
gap> VoleFind.Group(GB_Con.InGroup(H), GB_Con.InGroup(K)) = Intersection(H, K);
true

# Coset intersection
gap> x := (1,2,3,4,5,6,7);;
gap> VoleFind.Coset(GB_Con.InCosetSimple(H, x), GB_Con.InCosetSimple(K, x))
>      = RightCoset(Intersection(H, K), x);
true

# Transporter of a group under conjugation
gap> H2 := H ^ (2,3,6)(4,5,7);;
gap> res := VoleFind.Rep(Constraint.Transport(H, H2), BTKit_Refiner.InGroupSimple(G));;
gap> res <> fail and H ^ res = H2 and res in G;
true

# Transporter of a set of tuples
gap> s2 := OnSetsTuples([[1,2],[3,5]], x);;
gap> res := VoleFind.Rep(Constraint.Transport([[1,2],[3,5]], s2, OnSetsTuples));;
gap> res <> fail and OnSetsTuples([[1,2],[3,5]], res) = s2;
true

#
gap> STOP_TEST("basic.tst");
