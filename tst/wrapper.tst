#@local
gap> START_TEST("wrapper.tst");
gap> LoadPackage("vole", false);
true

# Vole.Intersection
gap> Vole.Intersection();
Error, Vole.Intersection: The arguments must specify at least one perm group o\
r right coset
gap> Vole.Intersection(fail);
Error, Vole.Intersection: The arguments must be (a list containing) perm group\
s and/or right cosets of perm groups
gap> Vole.Intersection(SymmetricGroup(5)) = SymmetricGroup(5);
true
gap> Vole.Intersection(SymmetricGroup(5) : raw := true).group
> = SymmetricGroup(5);
true
gap> Vole.Intersection(SymmetricGroup(5), AlternatingGroup(5))
> = AlternatingGroup(5);
true
gap> Vole.Intersection(SymmetricGroup(5), AlternatingGroup(5)
> : raw := true).group
> = AlternatingGroup(5);
true
gap> Vole.Intersection(AlternatingGroup(4), AlternatingGroup(4) * (1,2));
[  ]
gap> Vole.Intersection(AlternatingGroup(4), AlternatingGroup(4) * (1,2)
> : raw := true).cosetrep;
fail

# Vole.Stabiliser
gap> Vole.Stabiliser();
Error, Function: number of arguments must be at least 2 (not 0)
gap> Vole.Stabiliser(AlternatingGroup(5));
Error, Function: number of arguments must be at least 2 (not 1)
gap> Vole.Stabiliser(AlternatingGroup(5), CycleDigraph(5));
Error, VoleCon.Stabilize: Unrecognised combination of <object> and <action>:
<immutable cycle digraph with 5 vertices> and OnPoints
gap> Vole.Stabiliser(AlternatingGroup(5), CycleDigraph(5), OnDigraphs);
Group([ (1,2,3,4,5) ])
gap> Parent(last) = AlternatingGroup(5);
true
gap> Vole.Stabiliser(AlternatingGroup(5), CycleDigraph(5), OnDigraphs
> : raw := true).group;
Group([ (1,2,3,4,5) ])
gap> Parent(last) = AlternatingGroup(5);
true

#
gap> STOP_TEST("wrapper.tst");
