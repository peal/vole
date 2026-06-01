#@local autMatch, changedQ, mp, cliques, part, mp2, G, og
#
# Unit tests for _BTKit.compressGraph: the graph-compression pass that
# replaces whole-component cliques and complete-multipartite graphs with
# compact auxiliary-vertex gadgets of the SAME automorphism group.
#
gap> START_TEST("compress.tst");
gap> LoadPackage("vole", false);
true
gap> LoadPackage("digraphs", false);
true

# autMatch: does compressGraph preserve the automorphism group, as acting on
# the real points [1..n]? (gadget vertices form their own colour classes)
gap> autMatch := function(D)
>     local r, n, colours, A;
>     n := DigraphNrVertices(D);
>     r := _BTKit.compressGraph(D);
>     if not IsBound(r.vertlabels) then
>         return true;   # unchanged: trivially preserved (checked via changedQ)
>     fi;
>     colours := List(r.vertlabels, x -> Position(Set(r.vertlabels), x));
>     A := AutomorphismGroup(r.graph, colours);
>     return AutomorphismGroup(D) = Action(A, [1 .. n]);
> end;;

# changedQ: did the pass fire (gadget vertices added)?
gap> changedQ := D -> IsBound(_BTKit.compressGraph(D).vertlabels);;

# (1) Union of cliques: 3 x K4 on 12 points (the "within-block" shape).
gap> cliques := DigraphNC(List([1 .. 12],
>     i -> Filtered([1 .. 12], j -> j <> i and QuoInt(j - 1, 4) = QuoInt(i - 1, 4))));;
gap> DigraphNrEdges(cliques);
36
gap> autMatch(cliques);
true
gap> changedQ(cliques);
true
gap> DigraphNrEdges(_BTKit.compressGraph(cliques).graph);   # 3 centres, 4 arcs each
12

# (2) Complete multipartite K_{4,4,4} on 12 points (the "between-block" shape).
gap> mp := DigraphNC(List([1 .. 12],
>     i -> Filtered([1 .. 12], j -> j <> i and QuoInt(j - 1, 4) <> QuoInt(i - 1, 4))));;
gap> DigraphNrEdges(mp);
96
gap> autMatch(mp);
true
gap> changedQ(mp);
true
gap> DigraphNrEdges(_BTKit.compressGraph(mp).graph);    # 12 part-arcs + 3 top-arcs
15

# (3) A single big clique K8.
gap> autMatch(CompleteDigraph(8));
true
gap> DigraphNrEdges(_BTKit.compressGraph(CompleteDigraph(8)).graph);
8

# (4) Complete multipartite with UNEQUAL parts, sizes 2,3,4 (must still match).
gap> part := [1, 1, 2, 2, 2, 3, 3, 3, 3];;
gap> mp2 := DigraphNC(List([1 .. 9],
>     i -> Filtered([1 .. 9], j -> part[j] <> part[i])));;
gap> autMatch(mp2);
true
gap> changedQ(mp2);
true

# (5) Informative graphs must be LEFT ALONE: a plain cycle is neither a
# clique nor complete multipartite.
gap> changedQ(CycleDigraph(7));
false

# (6) Symmetry-safety counterexample: the regular group C_10 has a block
# system, but its orbital graphs are matchings/cycles carrying real
# structure — they must NOT be compressed.
gap> G := Group([(1,2,3,4,5)(6,7,8,9,10), (1,6)(2,7)(3,8)(4,9)(5,10)]);;
gap> ForAll(_BTKit.getOrbitalListWithOptions(G, rec(maxval := 10)),
>           og -> not changedQ(og));
true

# (7) The kill-switch makes it the identity.
gap> _BTKit.COMPRESS_ENABLE := false;;
gap> changedQ(mp);
false
gap> _BTKit.COMPRESS_ENABLE := true;;
gap> changedQ(mp);
true

gap> STOP_TEST("compress.tst");
