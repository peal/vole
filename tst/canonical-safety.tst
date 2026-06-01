#@local canon, H, G, safe
gap> START_TEST("canonical-safety.tst");
gap> ReadPackage("vole", "tst/test_functions.g");
true

# The canonical-safety boundary.
#
# Computing a canonical image of a group under conjugacy imposes a STRONGER
# requirement than computing its normaliser: not only the refiners but the
# search's branch ORDER must be a Sym(Omega)-invariant of the input, so that
# conjugate inputs follow corresponding search trajectories. The regular-orbit
# accelerator (NormaliserOrbitalRegOrbit, Theissen 3.7) proposes its branch
# from a regular orbit of H -- a point set tied to the INPUT labelling -- so it
# is sound for the normaliser (it only reorders the search) but UNSAFE for
# canonical images: conjugate inputs can receive different canonical images.
# Vole's canonical dispatch therefore uses the safe NormaliserOrbital refiner.
#
# This test pins that boundary on a minimal witness: the regular representation
# of S_3 on 6 points, with sigma = (2,3,4).
gap> canon := {grp, sub, ref} -> sub ^ VoleFind.CanonicalPerm(grp, ref(sub));;
gap> H := Image(RegularActionHomomorphism(SymmetricGroup(3)));;
gap> G := SymmetricGroup(6);;

# Safe refiner: the canonical image is constant on the conjugacy class.
gap> safe := canon(G, H, GB_Con.NormaliserOrbital);;
gap> ForAll([(2, 3, 4), (1, 2)(3, 4), (1, 5, 3)], s ->
>       canon(G, H ^ s, GB_Con.NormaliserOrbital) = safe);
true

# Unsafe (regular-orbit) refiner: NOT constant on the class. H and H^(2,3,4)
# are conjugate in G yet receive different canonical images -- the documented
# unsafety. If a canonical-safe regular-orbit ordering is ever designed this
# assertion will flip; update it together with the canonical dispatch.
gap> canon(G, H ^ (2, 3, 4), GB_Con.NormaliserOrbitalRegOrbit)
>      <> canon(G, H, GB_Con.NormaliserOrbitalRegOrbit);
true

gap> STOP_TEST("canonical-safety.tst");
