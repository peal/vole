#@local agree, canonStable, n, k
gap> START_TEST("selector.tst");
gap> ReadPackage("vole", "tst/test_functions.g");
true

# The branching-cell selector (set per call via the `selector` option, or
# globally via `_Vole.Selector`) changes only the search order, never the
# group that is found. Every strategy must agree with the default.
gap> agree := function(solve)
>     local sels, ref, s;
>     sels := ["smallest", "largest", "first", "most-connected",
>              "most-connected-smallest", "most-connected-largest",
>              "smallest-most-connected"];
>     ref := solve("default");
>     return ForAll(sels, s -> solve(s) = ref);
> end;;

# set stabiliser (no aux), set-of-sets (aux), normaliser, intersection.
gap> agree(s -> Vole.Stabilizer(SymmetricGroup(9), [1, 2, 3, 4], OnSets : selector := s));
true
gap> agree(s -> Vole.Stabilizer(SymmetricGroup(8), [[1, 2], [3, 4], [5, 6], [7, 8]], OnSetsSets : selector := s));
true
gap> agree(s -> Vole.Normalizer(SymmetricGroup(8), Group((1, 2, 3, 4), (5, 6, 7, 8)) : selector := s));
true
gap> agree(s -> Vole.Intersection(TransitiveGroup(8, 10), TransitiveGroup(8, 15) : selector := s));
true

# Across all transitive groups of degree 6..7, every selector returns the
# same normaliser as the default.
gap> ForAll([6, 7], n -> ForAll([1 .. NrTransitiveGroups(n)], k ->
>     agree(s -> Vole.Normalizer(SymmetricGroup(n), TransitiveGroup(n, k) : selector := s))));
true

# The canonical labelling itself depends on the selector, but under any
# FIXED selector the canonical image is still a genuine invariant:
# conjugate inputs map to the same image.
gap> canonStable := function(s)
>     local G, H, g;
>     G := SymmetricGroup(7);
>     H := Group((1, 2, 3), (4, 5));
>     g := PseudoRandom(G);
>     return Vole.CanonicalImage(G, H, OnPoints : selector := s)
>          = Vole.CanonicalImage(G, H ^ g, OnPoints : selector := s);
> end;;
gap> ForAll(["default", "smallest", "largest", "first", "most-connected"], canonStable);
true

gap> STOP_TEST("selector.tst");
