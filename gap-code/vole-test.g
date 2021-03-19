Read("gap-code/vole-base.g");
LoadPackage("quickcheck");

frucht := [[1,2], [1,3], [1,4], [2,5], [2,6], [4,7], [4,8], [5,9], [5,10], [6,11],
           [6,12], [3,7], [7,8], [8,12], [12,11], [11,9], [9,10], [10,3]];

neigh := List([1..12], x -> []);
for f in frucht do
    Add(neigh[f[1]], f[2]);
    Add(neigh[f[2]], f[1]);
od;


Comp(5, [con.SetStab([2,3,4]), con.SetStab([3,4,5])]);

Comp(7, [con.SetStab([2,3,4]), con.TupleStab([5])]);

Comp(5, [con.SetStab([2,3,4]), con.TupleStab([5])]);

Comp(5, [con.DigraphStab([[2,4],[1,3],[2,4],[1,3],[]])]);

Comp(5, [BTKit_Con.SetStab(5, [2,3])]);

Comp(12, [con.DigraphStab(neigh)]);

# Bug found by Mun See Chang and fixed in commit 11e06f
Comp(7, [GB_Con.NormaliserSimple(7, Group([(1,2,3,4), (1,2), (5,6,7)]))]);

r := VoleSolve(5, true, [con.TupleTransport([2,3,4,5],[1,3,5,4])]);
Assert(0,r.sol = [(1,2)(4,5)]);

r := VoleSolve(5, true, [con.SetTransport([2,3,4],[1,4,5])]);
Assert(0, OnSets([2,3,4], r.sol[1]) = [1,4,5]);

for i in [2..6] do
    for j in [1..NrTransitiveGroups(i)] do
        Comp(i, [GB_Con.NormaliserSimple(i,TransitiveGroup(i,j))]);
    od;
od;

QC_Check([ QC_SetOf(QC_SetOf(IsPosInt)) ], {s} -> QuickChecker(Maximum(Flat(s)), [con.SetSetStab(s)]));

QC_Check([ QC_SetOf(QC_ListOf(IsPosInt)) ], {s} -> QuickChecker(Maximum(Flat(s)), [con.SetTupleStab(s)]));

QC_Check([ QC_SetOf(QC_ListOf(IsPosInt)), IsPermGroup ], function(s,g)
    local s2, max, res, p;
    max := Maximum(Maximum(Flat(s)), LargestMovedPoint(g));
    p := Random(g);
    s2 := OnSetsTuples(s,p);
    res := VoleSolve(max, true, [con.SetTupleTransport(s,s2), BTKit_Con.InGroupSimple(max, g)]);
    if IsEmpty(res.sol) or OnSetsTuples(s,res.sol[1]) <> s2 then
        return StringFormatted("Failure: {} {} {}", s2, p, OnSetsTuples(s,res.sol[1]));
    fi;
    return true;
end);

Print("Tests passed\n");
QUIT_GAP(0);