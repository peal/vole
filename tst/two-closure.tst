gap> START_TEST("two-closure.tst");
gap> LoadPackage("vole", false);
true
gap> pnts := 9;;
gap> for g in AllTransitiveGroups(NrMovedPoints, pnts, Transitivity, 1) do
> tc := TwoClosure(g);
> orbs := _BTKit.getOrbitalList(g, pnts);
> voletc := VoleFind.Group(List(orbs, x -> VoleCon.Stabilize(x, OnDigraphs)): points := 9);
> if tc <> voletc then Print(g, ":", tc, voletc); fi;
> od;