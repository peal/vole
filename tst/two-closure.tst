#@local g, gap, vole1, vole2, n
gap> START_TEST("two-closure.tst");
gap> LoadPackage("vole", false);
true

#
gap> n := 9;;
gap> for g in AllTransitiveGroups(NrMovedPoints, n, Transitivity, 1) do
>   gap := TwoClosure(g);
>   vole1 := Vole.TwoClosure(g);
>   vole2 := VoleFind.Group(n, Constraint.Stabilize(OrbitalGraphs(g, n),
>                                                OnTuplesDigraphs));
>   if gap <> vole1 then Print(g, ":", gap, vole1); fi;
>   if gap <> vole2 then Print(g, ":", gap, vole2); fi;
> od;

#
gap> STOP_TEST("two-closure.tst");
