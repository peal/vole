gap> START_TEST("two-closure.tst");
gap> LoadPackage("vole", false);
true
gap> pnts := 9;;
gap> for g in AllTransitiveGroups(NrMovedPoints, pnts, Transitivity, 1) do
> tc := TwoClosure(g);
> orbs := OrbitalGraphs(g, pnts);
> voletc := VoleFind.Group(pnts, VoleCon.Stabilize(x, OnTuplesDigraphs));
> if tc <> voletc then Print(g, ":", tc, voletc); fi;
> od;