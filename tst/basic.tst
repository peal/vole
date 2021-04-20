#@local edges, frucht, neigh, r
gap> START_TEST("basic.tst");
gap> LoadPackage("vole", false);
true
gap> LoadPackage("quickcheck", false);
true

#
gap> edges := [[1,2], [1,3], [1,4], [2,5], [2,6], [4,7], [4,8], [5,9], [5,10], [6,11],
>         [6,12], [3,7], [7,8], [8,12], [12,11], [11,9], [9,10], [10,3]];;
gap> frucht := DigraphSymmetricClosure(DigraphByEdges(edges));;
gap> neigh := OutNeighbours(frucht);;
gap> VoleComp(5, [VoleCon.SetStab([2,3,4]), VoleCon.SetStab([3,4,5])]);
gap> VoleComp(7, [VoleCon.SetStab([2,3,4]), VoleCon.TupleStab([5])]);
gap> VoleComp(5, [VoleCon.SetStab([2,3,4]), VoleCon.TupleStab([5])]);
gap> VoleComp(5, [VoleCon.DigraphStab([[2,4],[1,3],[2,4],[1,3],[]])]);
gap> VoleComp(5, [BTKit_Con.SetStab(5, [2,3])]);
gap> VoleComp(12, [VoleCon.DigraphStab(neigh)]);

# Bug found by Mun See Chang and fixed in commit 11e06f
gap> VoleComp(7, [GB_Con.NormaliserSimple(7, Group([(1,2,3,4), (1,2), (5,6,7)]))]);

#
gap> r := VoleSolve(5, true, [VoleCon.TupleTransport([2,3,4,5],[1,3,5,4])]);;
gap> Assert(0,r.sol = [(1,2)(4,5)]);
gap> r := VoleSolve(5, true, [VoleCon.SetTransport([2,3,4],[1,4,5])]);;
gap> Assert(0, OnSets([2,3,4], r.sol[1]) = [1,4,5]);

#
gap> STOP_TEST("basic.tst");
