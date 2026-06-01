#@local
gap> START_TEST("normaliser-vole.tst");
gap> ReadPackage("vole", "tst/test_functions.g");
true

# The user-facing Vole.Normalizer (default refiner + wrapper + base/SGS
# handoff) must agree with GAP's Normalizer in the symmetric group on the
# moved points, for random permutation groups.
gap> QC_Check([IsPermGroup], function(g)
>     local n, S;
>     n := LargestMovedPoint(g);
>     if n < 2 then return true; fi;
>     S := SymmetricGroup(n);
>     if Vole.Normalizer(S, g) = Normalizer(S, g) then
>         return true;
>     fi;
>     return StringFormatted("Normalizer mismatch for {}", g);
> end);
true

# The same entry point over every transitive group of small degree.
gap> ForAll([2 .. 8], n -> ForAll([1 .. NrTransitiveGroups(n)], k ->
>     Vole.Normalizer(SymmetricGroup(n), TransitiveGroup(n, k))
>       = Normalizer(SymmetricGroup(n), TransitiveGroup(n, k))));
true

# Group transporter through the user-facing wrappers: for random (g, h) and
# random p in g, Vole.RepresentativeAction conjugates h to h^p, and
# Vole.IsConjugate confirms the two are conjugate in g.
gap> QC_Check([IsPermGroup, IsPermGroup], function(g, h)
>     local p, h2, e;
>     p := Random(g);
>     h2 := h ^ p;
>     e := Vole.RepresentativeAction(g, h, h2);
>     if e = fail or h ^ e <> h2 or not e in g then
>         return StringFormatted("transporter failed: {} {} {}", g, h, p);
>     fi;
>     if not Vole.IsConjugate(g, h, h2) then
>         return StringFormatted("IsConjugate false for conjugate pair: {} {} {}", g, h, p);
>     fi;
>     return true;
> end);
true

#
gap> STOP_TEST("normaliser-vole.tst");
