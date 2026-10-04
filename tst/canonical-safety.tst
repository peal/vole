# Assisted-by: OpenAI Codex (GPT-6), branch-proposal regression tests.
#@local canon, H, G, safe, check, variant
gap> START_TEST("canonical-safety.tst");
gap> LoadPackage("vole", false);
true

# A proposal chosen before later splits could select non-corresponding
# cells. Regular S3 formerly gave different canonical images after (2,3,4).
# Refreshing proposals on changed partitions repairs this witness; it does
# not certify every regular/characteristic strategy as canonical-safe.
gap> canon := {grp, sub, ref} -> sub ^ VoleFind.CanonicalPerm(grp, ref(sub));;
gap> H := Image(RegularActionHomomorphism(SymmetricGroup(3)));;
gap> G := SymmetricGroup(6);;

# Safe refiner: the canonical image is constant on the conjugacy class.
gap> safe := canon(G, H, GB_Con.NormaliserOrbital);;
gap> ForAll([(2, 3, 4), (1, 2)(3, 4), (1, 5, 3)], s ->
>       canon(G, H ^ s, GB_Con.NormaliserOrbital) = safe);
true

# Compare within each strategy: different strategies may choose different
# representatives. Canonical permutations must remain in the ambient group.
gap> check := function(ref)
>     local base, s, p, image, gens;
>     base := canon(G, H, ref);
>     for s in [(2,3,4), (1,2)(3,4), (1,5,3), (1,2,3,4,5)] do
>         gens := GeneratorsOfGroup(H ^ s);
>         image := Group(Concatenation(Reversed(gens), [Product(gens)]));
>         p := VoleFind.CanonicalPerm(G, ref(image));
>         if not p in G or image ^ p <> base then return false; fi;
>     od;
>     return canon(G, base, ref) = base;
> end;;
gap> ForAll(["Orbital", "OrbitalRegOrbit", "OrbitalRegOrbitCross",
>     "OrbitalRegOrbitCrossNoPropose"], v ->
>         check(GB_Con.(Concatenation("Normaliser", v))));
true

gap> STOP_TEST("canonical-safety.tst");
