gap> Read("gap-code/vole-base.g");
gap> LoadPackage("quickcheck", false);;
gap> for i in [2..6] do
>    for j in [1..NrTransitiveGroups(i)] do
>        Comp(i, [GB_Con.NormaliserSimple(i,TransitiveGroup(i,j))]);
>    od;
> od;