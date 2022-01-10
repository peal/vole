#@local con
gap> START_TEST("refiners.tst");
gap> LoadPackage("vole", false);
true

# VoleRefiner.InSymmetricGroup
gap> VoleRefiner.InSymmetricGroup(0);
<Vole refiner: InSymmetricGroup on [  ]>
gap> VoleRefiner.InSymmetricGroup([]);
<Vole refiner: InSymmetricGroup on [  ]>
gap> VoleRefiner.InSymmetricGroup([4, 2, 1]);
<Vole refiner: InSymmetricGroup on [ 1, 2, 4 ]>
gap> VoleRefiner.InSymmetricGroup(5);
<Vole refiner: InSymmetricGroup on [ 1 .. 5 ]>
gap> VoleRefiner.InSymmetricGroup([1 .. 5]);
<Vole refiner: InSymmetricGroup on [ 1 .. 5 ]>
gap> VoleRefiner.InSymmetricGroup([2, 3, 5]);
<Vole refiner: InSymmetricGroup on [ 2, 3, 5 ]>

# VoleRefiner.FromConstraint
gap> con := Constraint.Stabilise(
>     [CycleDigraph(3), CycleDigraph(4)], OnTuplesDigraphs);;
gap> VoleRefiner.FromConstraint(con);
[ <Vole refiner: DigraphStab of [ [ 2 ], [ 3 ], [ 1 ] ]>, 
  <Vole refiner: DigraphStab of [ [ 2 ], [ 3 ], [ 4 ], [ 1 ] ]> ]

#
gap> STOP_TEST("refiners.tst");
