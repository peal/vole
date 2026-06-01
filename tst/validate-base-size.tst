#@local ValidateOne, n, k
gap> START_TEST("validate-base-size.tst");
gap> ReadPackage("vole", "tst/test_functions.g");
true

# Whenever Vole attaches a base + stabiliser chain to a returned group
# (comms.gi: StabChainBaseStrongGenerators), the result must be valid:
#   * Size via Vole's chain == Size via an independent recompute, and
#   * fixing all of Vole's base points gives the trivial group.
# StabChainBaseStrongGenerators trusts its base/SGS and will silently
# return a wrong size for a bad base, so this is checked, not assumed.
gap> ValidateOne := function(glist)
>     local g, gens, gindep, base, szc, szi;
>     g := CallFuncList(VoleFind.Group, glist);
>     gens := GeneratorsOfGroup(g);
>     gindep := Group(gens, ());
>     szc := Size(g);
>     szi := Size(gindep);
>     base := BaseStabChain(StabChainImmutable(g));
>     return szc = szi and IsTrivial(Stabilizer(gindep, base, OnTuples));
> end;;

# No-aux, set-of-sets (rigid aux), set-of-tuples, normaliser, centraliser.
gap> ForAll([
>     [SymmetricGroup(8), Constraint.Stabilize([1, 2, 3], OnSets)],
>     [SymmetricGroup(10), Constraint.Stabilize([1, 3, 5, 7], OnSets)],
>     [SymmetricGroup(6), AlternatingGroup(6)],
>     [SymmetricGroup(6), Constraint.Stabilize([[1, 2], [3, 4], [5, 6]], OnSetsSets)],
>     [SymmetricGroup(8), Constraint.Stabilize([[1, 2, 3], [4, 5], [6, 7, 8]], OnSetsSets)],
>     [SymmetricGroup(6), Constraint.Stabilize([[1, 2], [3, 4], [5, 6]], OnSetsTuples)],
>     [SymmetricGroup(6), Constraint.Normalise(Group((1, 2, 3), (4, 5, 6)))],
>     [SymmetricGroup(9), Constraint.Normalise(Group((1, 2, 3), (4, 5, 6), (7, 8, 9)))],
>     [SymmetricGroup(8), Constraint.Centralise((1, 2, 3, 4))],
>   ], ValidateOne);
true

# Sweep every transitive group of degree 6..9: normaliser, plus a
# stabiliser computed inside the group itself.
gap> ForAll([6 .. 9], n -> ForAll([1 .. NrTransitiveGroups(n)], k ->
>     ValidateOne([SymmetricGroup(n), Constraint.Normalise(TransitiveGroup(n, k))])
>     and ValidateOne([TransitiveGroup(n, k), Constraint.Stabilize([1, 2], OnSets)])));
true

gap> STOP_TEST("validate-base-size.tst");
