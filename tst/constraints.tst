#@local n, Sn, pts, G, x, y, con, D, D1, D2
gap> START_TEST("constraints.tst");
gap> LoadPackage("vole", false);
true

# Constraint.Stabilise
gap> Constraint.Stabilise();
Error, Function: number of arguments must be at least 1 (not 0)

#gap> Constraint.Stabilise(1, 3);
#Error, Constraint.Stabilize args: object[, action]
#
# Constraint.InCoset, for a coset of a symmetric group
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
gap> con := Constraint.Stabilise(x);;
gap> G := VoleFind.Group(Constraint.MovedPoints(MovedPoints(x)), con);;
gap> G = Centraliser(SymmetricGroup(MovedPoints(x)), x);
true
gap> VoleFind.Group(10, con) = Centraliser(SymmetricGroup(10), x);
true

# OnTuplesDigraphs
gap> G := DihedralGroup(IsPermGroup, 12);;
gap> VoleFind.Group(6,
> Constraint.Stabilise(OrbitalGraphs(G), OnTuplesDigraphs)) = G;
true
gap> D := DigraphFromGraph6String("Esa?");;
gap> x := CycleDigraph(6);;
gap> y := DigraphReverse(CycleDigraph(6));;
gap> VoleFind.Rep(6, Constraint.Transport([x, D], [y, D, x], OnTuplesDigraphs));
fail
gap> VoleFind.Coset(6, Constraint.Transport([x, D], [y, D], OnTuplesDigraphs));
RightCoset(Group(()),(2,6)(3,5))

# Representative
gap> D1 := CycleDigraph(5);;
gap> D2 := DigraphReverse(D1);;
gap> con := Constraint.Transport(D1, D2, OnDigraphs);;
gap> x := Representative(con);;
gap> IsPerm(x) and IsDigraphIsomorphism(D1, D2, x);
true

#
gap> STOP_TEST("constraints.tst");
