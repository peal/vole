#@local G, H, Nref, Nvole, orig
gap> START_TEST("override.tst");
gap> ReadPackage("vole", "tst/test_functions.g");
true

gap> G := SymmetricGroup(6);;
gap> H := Group((1, 2, 3), (4, 5, 6));;
gap> Nref := Normalizer(G, H);;

# The override mechanism starts inactive, and we can grab the original
# implementation to compare against after a Restore.
gap> _Vole.OverrideGAP.IsActive("DoNormalizerPermGroup");
false
gap> orig := ValueGlobal("DoNormalizerPermGroup");;

# Install the Vole override (via the friendly NormalizerOn sugar).
gap> _Vole.OverrideGAP.NormalizerOn();;
gap> _Vole.OverrideGAP.IsActive("DoNormalizerPermGroup");
true
gap> IsIdenticalObj(ValueGlobal("DoNormalizerPermGroup"), _Vole.DoNormalizerPermGroup_VoleImpl);
true

# The overridden bottom layer computes the correct normaliser. Call it
# directly (DoNormalizerPermGroup(G, E, L, Omega)) so the test does not
# depend on which pre-backtrack reductions GAP's dispatcher applies.
gap> Nvole := ValueGlobal("DoNormalizerPermGroup")(G, H, Group(()), MovedPoints(G));;
gap> Nvole = Nref;
true

# Restore: inactive again, the original implementation is back in place.
gap> _Vole.OverrideGAP.NormalizerOff();;
gap> _Vole.OverrideGAP.IsActive("DoNormalizerPermGroup");
false
gap> IsIdenticalObj(ValueGlobal("DoNormalizerPermGroup"), orig);
true

# Restore is safe to call again when nothing is installed.
gap> _Vole.OverrideGAP.NormalizerOff();;
gap> _Vole.OverrideGAP.IsActive("DoNormalizerPermGroup");
false

# Normalizer still gives the right answer after the round trip.
gap> Normalizer(G, H) = Nref;
true

gap> STOP_TEST("override.tst");
