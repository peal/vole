#
# Vole: Backtrack search in permutation groups with graphs
#

#! @Chapter The wrapper...


#! @Section Simple Wrapper Functions

#! Vole provides a number of reimplementations of built-in GAP functions. These try to
#! provide the same interface as the original GAP function. Note that these functions always
#! use graph backtracking, so may be significantly slower than GAP's built in functions when
#! those functions can greatly simplify solving using group properties.
#!
#! The functions currently implemented are:
#!
#! * Vole.Intersection(G1,G2,..) for a list of permutation groups Gi
#! * Vole.Normaliser(G,H) - for permutation groups G and H
#! * Vole.IsConjugate(G,U,V) for permutation groups G,U,V
#! * Vole.IsConjugate(G,x,y) for a permutation group G and permutations x and y
#!
#! The following 4 functions each take an action. The supported actions are the same for all functions, and listed below:
#!
#! * Vole.Stabilizer(G,o,action) for a permutation group G, and action on 'o'
#! * Vole.RepresentativeAction(G,o1,o2,action) for a permutation group G and action on 'o1' and 'o2'.
#! * Vole.CanonicalImage(G,o,action)
#! * Vole.CanonicalPerm(G,o,action)
#!
#! The following actions are supported by Stabilizer and RepresentativeAction:
#!
#!    - OnPoints (for a point, or permutation)
#!    - OnSets (for a set of integers)
#!    - OnTuples (for a list of integers)
#!    - OnSetsSets, OnSetsTuples, OnTuplesSets, OnTuplesTuples (for sets/lists of integers as approriate)
#!    - OnDigraphs
#!    - 

# TODO - declare properly with DeclareGlobalName
DeclareGlobalVariable("Vole");
InstallValue(Vole, rec());
