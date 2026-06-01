#@local grpKey, conjGrpKey, voleCanonKey, gapConj, A5, s, c, subs, sets, vkeys, s3
gap> START_TEST("canonical-setofgroups.tst");
gap> LoadPackage("vole", false);;

# Canonical form of an UNORDERED set of groups under simultaneous
# conjugation, via Constraint.Stabilize(s, OnSets) where the set elements
# are *groups*.  This is outside the documented object/action table (there
# OnSets means a set of points), so we verify it directly against the true
# G-orbit equivalence.
#
# Ground truth uses permutation-only keys: a group is represented by its
# sorted element set, so comparison never needs '<' on groups (which is not
# total -- GAP's RepresentativeAction(.,.,OnSets) on groups can hit a
# NoMethodFound on '<', which is why we brute-force the orbit instead).
gap> grpKey := H -> Set(AsList(H));;
gap> conjGrpKey := {H, g} -> Set(List(AsList(H), p -> p ^ g));;
gap> voleCanonKey := function(G, s)
>     local c;
>     c := VoleFind.CanonicalPerm(G, Constraint.Stabilize(s, OnSets));
>     Assert(0, c in G, "canonical perm must lie in G");
>     return Set(List(s, H -> conjGrpKey(H, c)));
> end;;
gap> gapConj := function(G, s1, s2)
>     local k2;
>     k2 := Set(List(s2, grpKey));
>     return ForAny(AsList(G), g -> Set(List(s1, H -> conjGrpKey(H, g))) = k2);
> end;;

# The motivating example: a set of two groups in A5.
gap> A5 := AlternatingGroup(5);;
gap> s := Set([Group((1,2,3)), Group((1,2)(3,4))]);;
gap> c := VoleFind.CanonicalPerm(A5, Constraint.Stabilize(s, OnSets));;
gap> c in A5;
true

# Exhaustive: Vole's canonical-equality matches true G-conjugacy over every
# pair of 2-element sets drawn from a pool of subgroups.
gap> subs := [Group((1,2,3)), Group((1,2)(3,4)), Group((1,2,3,4,5)),
>             Group((3,4,5)), Group((1,2,3),(1,2)(4,5))];;
gap> sets := Concatenation(List([1 .. Length(subs)], a ->
>     List([a + 1 .. Length(subs)], b -> Set([subs[a], subs[b]]))));;
gap> vkeys := List(sets, s -> voleCanonKey(A5, s));;
gap> ForAll([1 .. Length(sets)], i -> ForAll([i .. Length(sets)], j ->
>     (vkeys[i] = vkeys[j]) = gapConj(A5, sets[i], sets[j])));
true

# Conjugacy-invariance, including a 3-element set: conjugating the whole set
# by any g in G leaves the canonical form unchanged.
gap> s3 := Set([Group((1,2,3)), Group((1,2)(3,4)), Group((1,2,3,4,5))]);;
gap> ForAll([1 .. 6], i ->
>     voleCanonKey(A5, s3) = voleCanonKey(A5, OnSets(s3, PseudoRandom(A5))));
true

gap> STOP_TEST("canonical-setofgroups.tst", 1);
