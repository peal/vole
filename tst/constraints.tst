#@local n,Sn,pts,G,x
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

#
gap> STOP_TEST("constraints.tst");
