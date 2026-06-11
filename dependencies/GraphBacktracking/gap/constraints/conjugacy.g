# Conjugacy refiners for the three kinds of map on points -- a permutation, a
# transformation, or a partial permutation -- all encoded the same way: by the
# map's functional digraph, with one out-edge i -> i^x from each vertex to its
# image. A fixed point becomes a loop; the edge is omitted only where x is
# undefined (a partial permutation, where i^x = 0). Conjugation by a permutation
# g acts as OnDigraphs(-, g), so two maps are S_n-conjugate iff their functional
# digraphs are isomorphic.
#
# The digraph is built on n = PS_Points(ps), the search degree, NOT the map's own
# degree, for two reasons:
#   1. Faithfulness: GAP trims trailing fixed points from a permutation or
#      transformation, so building on the element's degree would drop their
#      loops; a conjugate that moves such a point into range would keep it, and
#      the two would wrongly look non-isomorphic.
#   2. Combinator-safety: when several of these refiners are combined (in
#      VoleRefiner.SetOf / TupleOf / MultisetOf, to canonicalise a set, multiset,
#      or tuple of maps), the combinator glues each member's digraph to the shared
#      points by vertex number, so every member must report a digraph on the SAME
#      n vertices. Encoding on the element's own degree (e.g. omitting fixed
#      points to be degree-agnostic) makes members of different degrees disagree
#      on the vertex set, and the combined graph stops being a faithful invariant
#      of the family.

if not IsBound(GB_FunctionalDigraph) then
    # The functional digraph of a map x (permutation, transformation, or partial
    # permutation) on n points: out-edge i -> i^x, loop at a fixed point, omitted
    # where x is undefined (i^x = 0, partial permutations only).
    GB_FunctionalDigraph :=
        {x, n} -> Digraph(List([1 .. n], i -> Filtered([i ^ x], y -> y <> 0)));
fi;

GB_Con.PermConjugacy := function(permL, permR)
    return Objectify(GBRefinerType, rec(
        name := "GB_PermConjugacy",
        largest_required_point :=
            Maximum(LargestMovedPoint(permL), LargestMovedPoint(permR), 1),
        constraint := Constraint.Transport(permL, permR, OnPoints),
        refine := rec(
            initialise := function(ps, buildingRBase)
                if buildingRBase then
                    return rec(graph := GB_FunctionalDigraph(permL, PS_Points(ps)));
                else
                    return rec(graph := GB_FunctionalDigraph(permR, PS_Points(ps)));
                fi;
            end)
    ));
end;

GB_Con.TransformationConjugacy := function(transL, transR)
    return Objectify(GBRefinerType, rec(
        name := "GB_TransformationConjugacy",
        largest_required_point := Maximum(
            DegreeOfTransformation(transL), DegreeOfTransformation(transR), 1),
        constraint := Constraint.Transport(transL, transR, OnPoints),
        refine := rec(
            initialise := function(ps, buildingRBase)
                if buildingRBase then
                    return rec(graph := GB_FunctionalDigraph(transL, PS_Points(ps)));
                else
                    return rec(graph := GB_FunctionalDigraph(transR, PS_Points(ps)));
                fi;
            end)
    ));
end;

GB_Con.PartialPermConjugacy := function(ppL, ppR)
    return Objectify(GBRefinerType, rec(
        name := "GB_PartialPermConjugacy",
        largest_required_point := Maximum(
            DegreeOfPartialPerm(ppL), CodegreeOfPartialPerm(ppL),
            DegreeOfPartialPerm(ppR), CodegreeOfPartialPerm(ppR), 1),
        constraint := Constraint.Transport(ppL, ppR, OnPoints),
        refine := rec(
            initialise := function(ps, buildingRBase)
                if buildingRBase then
                    return rec(graph := GB_FunctionalDigraph(ppL, PS_Points(ps)));
                else
                    return rec(graph := GB_FunctionalDigraph(ppR, PS_Points(ps)));
                fi;
            end)
    ));
end;
