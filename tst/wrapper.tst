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
gap> Vole.Intersection([SymmetricGroup(5), AlternatingGroup(5)]
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

# Vole.Normaliser
gap> Vole.Normaliser();
Error, Function: number of arguments must be 2 (not 0)
gap> Vole.Normaliser(fail);
Error, Function: number of arguments must be 2 (not 1)
gap> Vole.Normaliser(fail, fail, fail);
Error, Function: number of arguments must be 2 (not 3)
gap> Vole.Normaliser(fail, fail);
Error, Vole.Normalizer: The first argument must be a perm group
gap> Vole.Normaliser(Group(()), fail);
Error, Vole.Normalizer: The second argument must a perm group or a permutation

# Vole.Centraliser
gap> Vole.Centraliser();
Error, Function: number of arguments must be 2 (not 0)
gap> Vole.Centraliser(fail, fail);
Error, Vole.Centralizer: The first argument must be a perm group
gap> Vole.Centraliser(AlternatingGroup(4), fail);
Error, Vole.Centralizer: The second argument must be a perm group or a permuta\
tion

# Vole.InConjugate
gap> Vole.IsConjugate();
Error, Function: number of arguments must be 3 (not 0)
gap> Vole.IsConjugate(fail, fail, fail);
Error, Vole.IsConjugate: The first argument must be a perm group
gap> Vole.IsConjugate(AlternatingGroup(4), fail, fail);
Error, Vole.IsConjugate: The second and third arguments must either be both pe\
rmutations or both perm groups
gap> Vole.IsConjugate(AlternatingGroup(4), (1,2), fail);
Error, Vole.IsConjugate: The second and third arguments must either be both pe\
rmutations or both perm groups
gap> Vole.IsConjugate(AlternatingGroup(4), fail, (1,2));
Error, Vole.IsConjugate: The second and third arguments must either be both pe\
rmutations or both perm groups
gap> Vole.IsConjugate(AlternatingGroup(4), Group([(3,4)]), (1,2));
Error, Vole.IsConjugate: The second and third arguments must either be both pe\
rmutations or both perm groups
gap> Vole.IsConjugate(AlternatingGroup(4), (3,4), Group([(1,2)]));
Error, Vole.IsConjugate: The second and third arguments must either be both pe\
rmutations or both perm groups
gap> Vole.IsConjugate(AlternatingGroup(4), (3,4), (1,2));
true
gap> Vole.IsConjugate(AlternatingGroup(4), Group([(3,4)]), Group([(1,2)]));
true

# Vole.RepresentativeAction
gap> Vole.RepresentativeAction();
Error, Function: number of arguments must be at least 3 (not 0)
gap> Vole.RepresentativeAction(fail, fail, fail, fail, fail);
Error, Vole.RepresentativeAction: The first argument must be a perm group
gap> Vole.RepresentativeAction(Group(()), fail, fail, fail, fail);
Error, VoleCon.RepresentativeAction args: G, object1, object2[, action]
gap> Vole.RepresentativeAction(Group(()), fail, fail, fail);
Error, VoleCon.Transport args: object1, object2[, action]

# Vole.TwoClosure
gap> Vole.TwoClosure();
Error, Function: number of arguments must be 1 (not 0)
gap> Vole.TwoClosure(fail);
Error, Vole.TwoClosure: The argument must be a perm group
gap> Vole.TwoClosure(AlternatingGroup(4)) = SymmetricGroup(4);
true

# Vole.CanonicalPerm
gap> Vole.CanonicalPerm();
Error, Function: number of arguments must be at least 2 (not 0)
gap> Vole.CanonicalPerm(fail, fail);
Error, Vole.CanonicalPerm: The first argument must be a perm group
gap> Vole.CanonicalPerm(Group(()), fail, fail, fail);
Error, VoleCon.CanonicalPerm args: G, object[, action]
gap> Vole.CanonicalPerm(Group(()), fail, fail);
Error, VoleCon.Stabilize args: object[, action]
gap> Vole.CanonicalPerm(Group(()), 1 : raw).canonical;
()

# Vole.CanonicalImage
gap> Vole.CanonicalImage();
Error, Function: number of arguments must be at least 2 (not 0)

# Vole.AutomorphismGroup
gap> Vole.AutomorphismGroup();
Error, Function: number of arguments must be at least 1 (not 0)
gap> Vole.AutomorphismGroup(fail);
Error, Vole.AutomorphismGroup: The first argument must be a digraph
gap> Vole.AutomorphismGroup(CycleDigraph(5), fail);
Error, not yet implemented for vertex/edge colours
gap> Vole.AutomorphismGroup(CycleDigraph(5)) = Group((1,2,3,4,5));
true

# Vole.CanonicalDigraph
gap> Vole.CanonicalDigraph();
Error, Function: number of arguments must be 1 (not 0)
gap> Vole.CanonicalDigraph(fail);
Error, Vole.AutomorphismGroup: The first argument must be a digraph

# Vole.DigraphCanonicalLabelling
gap> Vole.DigraphCanonicalLabelling();
Error, Function: number of arguments must be at least 1 (not 0)
gap> Vole.DigraphCanonicalLabelling(fail);
Error, Vole.AutomorphismGroup: The first argument must be a digraph
gap> Vole.DigraphCanonicalLabelling(CycleDigraph(5), fail);
Error, not yet implemented for vertex/edge colours

# Vole.IsIsomorphicDigraph
gap> Vole.IsIsomorphicDigraph();
Error, Function: number of arguments must be 2 (not 0)
gap> Vole.IsIsomorphicDigraph(fail, fail);
Error, Vole.IsIsomorphicDigraph: The arguments must be digraphs
gap> Vole.IsIsomorphicDigraph(CycleDigraph(4), fail);
Error, Vole.IsIsomorphicDigraph: The arguments must be digraphs
gap> Vole.IsIsomorphicDigraph(fail, CycleDigraph(4));
Error, Vole.IsIsomorphicDigraph: The arguments must be digraphs
gap> Vole.IsIsomorphicDigraph(Digraph([[4], [3], [1], [2]]), CycleDigraph(4));
true
gap> Vole.IsIsomorphicDigraph(CompleteDigraph(4), CycleDigraph(4));
false

# Vole.IsomorphismDigraphs
gap> Vole.IsomorphismDigraphs();
Error, Function: number of arguments must be 2 (not 0)
gap> Vole.IsomorphismDigraphs(fail, fail);
Error, Vole.IsomorphismDigraphs: The arguments must be digraphs
gap> Vole.IsomorphismDigraphs(CycleDigraph(4), fail);
Error, Vole.IsomorphismDigraphs: The arguments must be digraphs
gap> Vole.IsomorphismDigraphs(fail, CycleDigraph(4));
Error, Vole.IsomorphismDigraphs: The arguments must be digraphs
gap> Vole.IsomorphismDigraphs(Digraph([[4], [3], [1], [2]]), CycleDigraph(4));
(1,2,4,3)
gap> Vole.IsomorphismDigraphs(CompleteDigraph(4), CycleDigraph(4));
fail

#
gap> STOP_TEST("wrapper.tst");
