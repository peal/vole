#@local edges, frucht, neigh, r
gap> START_TEST("basic.tst");
gap> LoadPackage("vole", false);
true
gap> LoadPackage("quickcheck", false);
true
gap> ReadPackage("vole", "tst/test_functions.g");
true

#
gap> edges := [[1,2], [1,3], [1,4], [2,5], [2,6], [4,7], [4,8], [5,9], [5,10], [6,11],
>         [6,12], [3,7], [7,8], [8,12], [12,11], [11,9], [9,10], [10,3]];;
gap> frucht := DigraphSymmetricClosure(DigraphByEdges(edges));;
gap> neigh := OutNeighbours(frucht);;
gap> VoleComp(5, [VoleCon.Stabilize([2,3,4], OnSets), VoleCon.Stabilize([3,4,5], OnSets)]);
gap> VoleComp(7, [VoleCon.Stabilize([2,3,4], OnSets), VoleCon.Stabilize([5], OnTuples)]);
gap> VoleComp(5, [VoleCon.Stabilize([2,3,4], OnSets), VoleCon.Stabilize([5], OnTuples)]);
gap> VoleComp(5, [VoleCon.Stabilize([[2,4],[1,3],[2,4],[1,3],[]], OnDigraphs)]);
gap> VoleComp(5, [BTKit_Con.SetStab(5, [2,3])]);
gap> VoleComp(12, [VoleCon.Stabilize(neigh, OnDigraphs)]);

# Bug found by Mun See Chang and fixed in commit 11e06f
gap> VoleComp(7, [GB_Con.NormaliserSimple(7, Group([(1,2,3,4), (1,2), (5,6,7)]))]);

#
gap> r := Vole.FindOne([VoleCon.Transport([2,3,4,5], [1,3,5,4], OnTuples)] : conf := rec(points := 5));;
gap> Assert(0,r = (1,2)(4,5));
gap> r := Vole.FindOne(VoleCon.Transport([2,3,4], [1,4,5], OnTuples) : conf := rec(points := 5));;
gap> Assert(0, OnSets([2,3,4], r) = [1,4,5]);

#
gap> Vole.FindGroup([VoleRefiner.InSymmetricGroup([2,3,4])]) = SymmetricGroup([2,3,4]);
true
gap> Vole.FindGroup([VoleRefiner.InSymmetricGroup([2,4,8,6])]) = SymmetricGroup([2,4,6,8]);
true
gap> Vole.FindGroup([VoleRefiner.InSymmetricGroup([])]) = Group(());
true

#
gap> STOP_TEST("basic.tst");
