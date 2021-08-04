#@local i, j
gap> START_TEST("normaliser.tst");
gap> ReadPackage("vole", "tst/test_functions.g");
true

#
gap> for i in [2..6] do
>    for j in [1..NrTransitiveGroups(i)] do
>        VoleComp(i, [GB_Con.NormaliserSimple(TransitiveGroup(i,j))]);
>    od;
> od;

#
gap> STOP_TEST("normaliser.tst");
