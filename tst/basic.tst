gap> Read("gap-code/vole-base.g");
gap> LoadPackage("quickcheck", false);;
gap> edges := [[1,2], [1,3], [1,4], [2,5], [2,6], [4,7], [4,8], [5,9], [5,10], [6,11],
>         [6,12], [3,7], [7,8], [8,12], [12,11], [11,9], [9,10], [10,3]];;
gap> frucht := DigraphSymmetricClosure(DigraphByEdges(edges));;
gap> neigh := OutNeighbours(frucht);;
gap> Comp(5, [con.SetStab([2,3,4]), con.SetStab([3,4,5])]);
gap> Comp(7, [con.SetStab([2,3,4]), con.TupleStab([5])]);
gap> Comp(5, [con.SetStab([2,3,4]), con.TupleStab([5])]);
gap> Comp(5, [con.DigraphStab([[2,4],[1,3],[2,4],[1,3],[]])]);
gap> Comp(5, [BTKit_Con.SetStab(5, [2,3])]);
gap> Comp(12, [con.DigraphStab(neigh)]);
gap> # Bug found by Mun See Chang and fixed in commit 11e06f
gap> Comp(7, [GB_Con.NormaliserSimple(7, Group([(1,2,3,4), (1,2), (5,6,7)]))]);
gap> r := VoleSolve(5, true, [con.TupleTransport([2,3,4,5],[1,3,5,4])]);;
gap> Assert(0,r.sol = [(1,2)(4,5)]);
gap> r := VoleSolve(5, true, [con.SetTransport([2,3,4],[1,4,5])]);;
gap> Assert(0, OnSets([2,3,4], r.sol[1]) = [1,4,5]);