#@local i, j
gap> START_TEST("normaliser2.tst");
gap> LoadPackage("vole", false);
true
gap> LoadPackage("quickcheck", false);
true

#
gap> for i in [2..6] do
>    for j in [1..NrTransitiveGroups(i)] do
>        VoleComp(i, [GB_Con.NormaliserSimple2(i,TransitiveGroup(i,j))]);
>    od;
> od;

#
gap> STOP_TEST("normaliser2.tst");
