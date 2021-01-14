Read("gap-code/vole-base.g");

Comp(5, [con.SetStab([2,3,4]), con.SetStab([3,4,5])]);

Comp(7, [con.SetStab([2,3,4]), con.TupleStab([5])]);

Comp(5, [con.SetStab([2,3,4]), con.TupleStab([5])]);

Comp(5, [con.DigraphStab([[2,4],[1,3],[2,4],[1,3],[]])]);


Print("Tests passed\n");
QUIT_GAP(0);