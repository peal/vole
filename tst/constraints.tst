#@local n, Sn, pts, G, x, y, con, D
gap> START_TEST("constraints.tst");
gap> LoadPackage("vole", false);
true

# VoleCon.Stabilise
gap> VoleCon.Stabilise();
Error, Function: number of arguments must be at least 1 (not 0)
gap> VoleCon.Stabilise(1, 3);
Error, VoleCon.Stabilize args: object[, action]

# VoleCon.InCoset, for a coset of a symmetric group
gap> n := 100;;
gap> Sn := SymmetricGroup(n);;
gap> VoleFind.Coset(Sn * Random(Sn)) = Sn * ();
true
gap> pts := OnSets([1 .. n], Random(SymmetricGroup(200)));;
gap> G := SymmetricGroup(pts);;
gap> x := Random(SymmetricGroup(200));;
gap> VoleFind.Coset(G * x) = G * x;
true

# Permutation under conjugation
gap> x := (3,5,8,4)(1,7);;
gap> con := VoleCon.Stabilise(x);;
gap> G := VoleFind.Group(VoleCon.MovedPoints(MovedPoints(x)), con);;
gap> G = Centraliser(SymmetricGroup(MovedPoints(x)), x);
true
gap> VoleFind.Group(10, con) = Centraliser(SymmetricGroup(10), x);
true

# OnTuplesDigraphs
gap> G := DihedralGroup(IsPermGroup, 12);;
gap> VoleFind.Group(6,
> VoleCon.Stabilise(OrbitalGraphs(G), OnTuplesDigraphs)) = G;
true
gap> D := DigraphFromGraph6String("Esa?");;
gap> x := CycleDigraph(6);;
gap> y := DigraphReverse(CycleDigraph(6));;
gap> VoleFind.Rep(6, VoleCon.Transport([x, D], [y, D, x], OnTuplesDigraphs));
fail
gap> VoleFind.Coset(6, VoleCon.Transport([x, D], [y, D], OnTuplesDigraphs));
RightCoset(Group(()),(2,6)(3,5))

#
gap> STOP_TEST("constraints.tst");
