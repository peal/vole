#@local canon1, canonOrd, canonSetUno, canonMSetUno, voleTriple, voleMSetUno
#@local gapTriple, t3, p3
#
# Canonical enumeration of permutations, transformations and partial
# permutations, and of ordered/unordered pairs of them, up to conjugacy by the
# symmetric group -- a stress test for the VoleRefiner.SetOf / TupleOf /
# MultisetOf combinators, with GraphBacktracking's conjugacy refiners as members.
#
# GB_Con.PermConjugacy(x, x), GB_Con.TransformationConjugacy(x, x), and
# GB_Con.PartialPermConjugacy(x, x) are refiners for "is conjugate to x" (under
# S_n), all using the same functional-digraph encoding. Combined:
#   * a single element up to conjugacy        <- the refiner alone;
#   * an ORDERED pair, simultaneous conjugation <- VoleRefiner.TupleOf;
#   * an UNORDERED pair                         <- VoleRefiner.SetOf (distinct)
#                                                  or MultisetOf (any).
# The canonical permutation c of such a combinator sends the element(s) to a
# canonical conjugate, so counting distinct canonical forms counts orbits. We
# check Vole's counts against GAP's orbit counts (the source of truth); the
# single-transformation column is the published sequence 1, 3, 7, 19 (OEIS
# A001372, "mapping patterns").
#
gap> START_TEST("canonical-pairs.tst");
gap> LoadPackage("vole", false);;

# Canonical forms of an element / ordered pair / unordered pair under conjugacy.
# R is the conjugacy-refiner constructor for the kind of element (transformation
# or partial perm); the canonical form is the element(s) moved by the canonical
# permutation, so it lives in the same world as the input -- no digraphs in sight.
gap> canon1 := {x, n, R} -> x ^ VoleFind.CanonicalPerm(SymmetricGroup(n), R(x, x));;
gap> canonOrd := function(a, b, n, R)
>      local c;
>      c := VoleFind.CanonicalPerm(SymmetricGroup(n),
>                                  VoleRefiner.TupleOf([R(a, a), R(b, b)]));
>      return [a ^ c, b ^ c];
>    end;;
gap> canonSetUno := function(a, b, n, R)
>      local c;
>      c := VoleFind.CanonicalPerm(SymmetricGroup(n),
>                                  VoleRefiner.SetOf([R(a, a), R(b, b)]));
>      return SortedList([a ^ c, b ^ c]);
>    end;;
gap> canonMSetUno := function(a, b, n, R)
>      local c;
>      c := VoleFind.CanonicalPerm(SymmetricGroup(n),
>                                  VoleRefiner.MultisetOf([R(a, a), R(b, b)]));
>      return SortedList([a ^ c, b ^ c]);
>    end;;

# Vole's [single, ordered-pair, unordered-pair] orbit counts for a monoid, using
# its conjugacy refiner R. The unordered count uses SetOf off the diagonal
# (distinct members) and the single-element canonical form on it.
gap> voleTriple := function(mon, n, R)
>      local elts, k, ord, uno, i, j;
>      elts := Elements(mon);
>      k := Length(elts);
>      ord := Cartesian([1 .. k], [1 .. k]);
>      uno := [];
>      for i in [1 .. k] do
>        for j in [i .. k] do
>          if i = j then
>            Add(uno, SortedList([canon1(elts[i], n, R), canon1(elts[i], n, R)]));
>          else
>            Add(uno, canonSetUno(elts[i], elts[j], n, R));
>          fi;
>        od;
>      od;
>      return [Size(Set(elts, x -> canon1(x, n, R))),
>              Size(Set(ord, ij -> canonOrd(elts[ij[1]], elts[ij[2]], n, R))),
>              Size(Set(uno))];
>    end;;

# The unordered count again, but via MultisetOf throughout (it accepts the
# diagonal directly). This must agree with the SetOf-based count above.
gap> voleMSetUno := function(mon, n, R)
>      local elts, k, uno, i, j;
>      elts := Elements(mon);
>      k := Length(elts);
>      uno := [];
>      for i in [1 .. k] do
>        for j in [i .. k] do
>          Add(uno, canonMSetUno(elts[i], elts[j], n, R));
>        od;
>      od;
>      return Size(Set(uno));
>    end;;

# GAP's [single, ordered, unordered] orbit counts under (simultaneous)
# conjugation, the source of truth.
gap> gapTriple := function(mon, n)
>      local elts, ord;
>      elts := Elements(mon);
>      ord := Cartesian(elts, elts);
>      return [Length(Orbits(SymmetricGroup(n), elts, \^)),
>              Length(Orbits(SymmetricGroup(n), ord,
>                            {pr, g} -> [pr[1] ^ g, pr[2] ^ g])),
>              Length(Orbits(SymmetricGroup(n), Set(ord, SortedList),
>                            {pr, g} -> SortedList([pr[1] ^ g, pr[2] ^ g])))];
>    end;;

# Transformations: Vole matches GAP for n = 2, 3.
gap> voleTriple(FullTransformationMonoid(2), 2, GB_Con.TransformationConjugacy)
>    = gapTriple(FullTransformationMonoid(2), 2);
true
gap> t3 := voleTriple(FullTransformationMonoid(3), 3, GB_Con.TransformationConjugacy);;
gap> t3 = gapTriple(FullTransformationMonoid(3), 3);
true
gap> t3;
[ 7, 129, 74 ]

# Partial permutations: Vole matches GAP for n = 2, 3.
gap> voleTriple(SymmetricInverseMonoid(2), 2, GB_Con.PartialPermConjugacy)
>    = gapTriple(SymmetricInverseMonoid(2), 2);
true
gap> p3 := voleTriple(SymmetricInverseMonoid(3), 3, GB_Con.PartialPermConjugacy);;
gap> p3 = gapTriple(SymmetricInverseMonoid(3), 3);
true
gap> p3;
[ 10, 216, 120 ]

# Permutations: GB_Con.PermConjugacy uses the same functional-digraph encoding,
# so it too is safe as a combinator member (its older degree-agnostic cycle
# encoding would over-count inside SetOf/TupleOf). Orbits of (pairs of)
# permutations under (simultaneous) conjugation, matching GAP.
gap> voleTriple(SymmetricGroup(3), 3, GB_Con.PermConjugacy)
>    = gapTriple(SymmetricGroup(3), 3);
true

# The single-permutation column is the partition numbers p(n): conjugacy classes
# of S_n.
gap> List([1 .. 4],
>      n -> Size(Set(Elements(SymmetricGroup(n)),
>                    p -> p ^ VoleFind.CanonicalPerm(SymmetricGroup(n),
>                                                    GB_Con.PermConjugacy(p, p)))));
[ 1, 2, 3, 5 ]

# MultisetOf gives the same unordered counts as SetOf (checked at n = 2, where
# the values 7 and 18 were validated against GAP just above).
gap> voleMSetUno(FullTransformationMonoid(2), 2, GB_Con.TransformationConjugacy);
7
gap> voleMSetUno(SymmetricInverseMonoid(2), 2, GB_Con.PartialPermConjugacy);
18

# The single-transformation column is OEIS A001372 (mapping patterns).
gap> List([1 .. 4],
>      n -> Size(Set(Elements(FullTransformationMonoid(n)),
>                    t -> canon1(t, n, GB_Con.TransformationConjugacy))));
[ 1, 3, 7, 19 ]

#
gap> STOP_TEST("canonical-pairs.tst");
