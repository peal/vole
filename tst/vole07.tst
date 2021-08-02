# Vole, chapter 7
#
# DO NOT EDIT THIS FILE - EDIT EXAMPLES IN THE SOURCE INSTEAD!
#
# This file has been generated by AutoDoc. It contains examples extracted from
# the package documentation. Each example is preceded by a comment which gives
# the name of a GAPDoc XML file and a line range from which the example were
# taken. Note that the XML file in turn may have been generated by AutoDoc
# from some other input.
#
gap> START_TEST("vole07.tst");

# doc/_Chapter_wrapper.xml:82-89
gap> LoadPackage("vole", false);;
gap> Set(RecNames(Vole));
[ "AutomorphismGroup", "CanonicalDigraph", "CanonicalImage", 
  "CanonicalImagePerm", "CanonicalPerm", "Centraliser", "Centralizer", 
  "DigraphCanonicalLabelling", "Intersection", "IsConjugate", "Normaliser", 
  "Normalizer", "RepresentativeAction", "Stabiliser", "Stabilizer" ]

# doc/_Chapter_wrapper.xml:205-208
gap> true;
true

# doc/_Chapter_wrapper.xml:234-237
gap> true;
true

# doc/_Chapter_wrapper.xml:267-270
gap> true;
true

# doc/_Chapter_wrapper.xml:295-298
gap> true;
true

# doc/_Chapter_wrapper.xml:316-319
gap> true;
true

# doc/_Chapter_wrapper.xml:348-358
gap> # Conjugacy of permutations
gap> x := (1,2,3,4,5);; y := (1,2,3,4,6);;
gap> IsConjugate(SymmetricGroup(6), x, y);
true
gap> IsConjugate(AlternatingGroup(6), x, y);
false
gap> IsConjugate(Group([ (5,6) ]), x, y);
true
gap> # Conjugacy of groups

# doc/_Chapter_wrapper.xml:418-421
gap> true;
true

# doc/_Chapter_wrapper.xml:450-453
gap> true;
true

# doc/_Chapter_wrapper.xml:523-526
gap> true;
true

# doc/_Chapter_wrapper.xml:549-552
gap> true;
true

# doc/_Chapter_wrapper.xml:575-578
gap> true;
true

#
gap> STOP_TEST("vole07.tst", 1);
