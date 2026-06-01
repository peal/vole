#@local G, H, w, gen
gap> START_TEST("canonical-group.tst");
gap> LoadPackage("vole", false);
true

# Canonical image of a permutation group H inside an overgroup G under
# conjugation.  The defining contract: every member of the G-orbit of H
# under conjugation must canonicalise to the same group.  This is a
# Vole-specific feature — GAP has no built-in CanonicalImage for
# permutation groups under OnPoints.

# (C_p)^k abelian regular: shortcut closes at the root.
gap> G := SymmetricGroup(6);; H := Group([(1,2,3),(4,5,6)]);;
gap> Vole.CanonicalImage(G, H, OnPoints) = Vole.CanonicalImage(G, H^(1,4)(2,5)(3,6), OnPoints);
true
gap> Vole.CanonicalImage(G, H, OnPoints) = Vole.CanonicalImage(G, H^PseudoRandom(G), OnPoints);
true

# The action is optional and defaults to OnPoints (matching Vole.CanonicalPerm
# and the documented signature): omitting it must equal passing OnPoints, and
# stay conjugacy-invariant.
gap> Vole.CanonicalImage(G, H) = Vole.CanonicalImage(G, H, OnPoints);
true
gap> Vole.CanonicalImage(G, H) = Vole.CanonicalImage(G, H^PseudoRandom(G));
true
gap> Vole.CanonicalImagePerm(G, H) = Vole.CanonicalPerm(G, H, OnPoints);
true
gap> Vole.CanonicalImage(G, H, OnPoints, OnSets);
Error, Vole.CanonicalImage args: G, object[, action]

gap> G := SymmetricGroup(9);; H := Group([(1,2,3),(4,5,6),(7,8,9)]);;
gap> Vole.CanonicalImage(G, H, OnPoints) = Vole.CanonicalImage(G, H^PseudoRandom(G), OnPoints);
true
gap> Vole.CanonicalImage(G, H, OnPoints) = Vole.CanonicalImage(G, H^PseudoRandom(G), OnPoints);
true

gap> G := SymmetricGroup(15);;
gap> H := Group(List([0..2], i -> CycleFromList([i*5+1..(i+1)*5])));;
gap> Vole.CanonicalImage(G, H, OnPoints) = Vole.CanonicalImage(G, H^PseudoRandom(G), OnPoints);
true

# Direct product of symmetrics — transitive constituents per block.
gap> G := SymmetricGroup(12);;
gap> H := Group(Concatenation(GeneratorsOfGroup(SymmetricGroup([1..4])),
> GeneratorsOfGroup(SymmetricGroup([5..8])),
> GeneratorsOfGroup(SymmetricGroup([9..12]))));;
gap> Vole.CanonicalImage(G, H, OnPoints) = Vole.CanonicalImage(G, H^PseudoRandom(G), OnPoints);
true

# Wreath product on a smallish degree.
gap> G := SymmetricGroup(9);;
gap> w := WreathProduct(SymmetricGroup(3), SymmetricGroup(3));;
gap> Vole.CanonicalImage(G, w, OnPoints) = Vole.CanonicalImage(G, w^PseudoRandom(G), OnPoints);
true

# AGL(1, 7) — primitive affine on [1..7].
gap> G := SymmetricGroup(7);; H := Group([(1,2,3,4,5,6,7),(2,3,5)(4,7,6)]);;
gap> Vole.CanonicalImage(G, H, OnPoints) = Vole.CanonicalImage(G, H^PseudoRandom(G), OnPoints);
true

# Mathieu group as a primitive subgroup of S_11.
gap> G := SymmetricGroup(11);; H := MathieuGroup(11);;
gap> Vole.CanonicalImage(G, H, OnPoints) = Vole.CanonicalImage(G, H^PseudoRandom(G), OnPoints);
true

#
gap> STOP_TEST("canonical-group.tst", 1);
