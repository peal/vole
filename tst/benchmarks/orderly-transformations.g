# Orderly generation of transformations up to conjugacy by the symmetric group.
#
# We enumerate, level by level in the number of points n, one representative of
# every transformation on [1 .. n] up to S_n-conjugacy. The classical "build
# n from n-1" step does not work directly on transformations: deleting point n
# from a transformation f on [n] leaves the in-neighbours of n (the points with
# i ^ f = n) without an image, so the restriction is a PARTIAL transformation,
# not a transformation. Partial transformations are therefore the carrier of the
# recursion, and total ones are read off as the subset we ultimately count.
#
# Representation: a partial transformation on [1 .. n] is a length-n list with
# entries in [0 .. n], where 0 means "undefined". Conjugation by g in S_n acts
# by  L -> [ i -> (L[i ^ (g ^ -1)]) ^ g ]  (with 0 fixed); this is exactly
# OnDigraphs of the functional digraph (out-edge i -> i ^ x, none where
# undefined), so the canonical form is the functional digraph's Bliss canonical
# labelling applied back to the list.
#
# Augmentation n-1 -> n: given a canonical rep Q on [n-1], a child P on [n] keeps
# every defined image of Q, chooses P[n] in [0 .. n], and lets each undefined
# point of Q either stay undefined or attach to the new point n. Canonicalise
# each child and dedup. (This is basic orderly generation: every level-n orbit
# has a representative that is a child of the canonical rep of its parent orbit,
# so dedup-by-canonical-form reaches each orbit exactly once. It does NOT avoid
# generating non-canonical children -- at n = 13 it makes ~8.4M children to keep
# 465778 reps, an ~18x overhead. McKay canonical augmentation, accepting a child
# only when its canonical deleted-point matches the removed point, would remove
# that overhead; it is not implemented here.)
#
# Self-check: at each level the number of reps must equal A126285(n) (partial
# endofunctions / partial mapping patterns) and the number of totals must equal
# A001372(n) (mapping patterns). Reference terms are embedded below.
#
# Run (default cap n = 13, ~5 min; level time grows ~3.3x per step):
#   gap -q -c 'Read("tst/benchmarks/orderly-transformations.g"); QUIT;'
#   gap -q -c 'ORDERLY_MAXN := 11;; ORDERLY_BUDGET := 120;; \
#              Read("tst/benchmarks/orderly-transformations.g"); QUIT;'

LoadPackage("vole", false);

if not IsBoundGlobal("ORDERLY_MAXN") then ORDERLY_MAXN := 13; fi;
if not IsBoundGlobal("ORDERLY_BUDGET") then ORDERLY_BUDGET := 1200; fi;

_OrderlyRun := function(maxN, budgetSec)
  local A001372, A126285, ptAct, ptCanon, reps, n, dict, newreps, sample,
        Q, zeros, Pn, S, P, i, c, nch, nreps, ntot, t0, tlev, ok1, ok2;
  # OEIS reference terms, indexed by n (n = 1 .. 15).
  A001372 := [1, 3, 7, 19, 47, 130, 343, 951, 2615, 7318, 20491, 57903,
              163898, 466199, 1328993];
  A126285 := [2, 6, 16, 45, 121, 338, 929, 2598, 7261, 20453, 57738, 163799,
              465778, 1328697, 3798473];
  ptAct := function(L, g)
    local ginv, res, k, v;
    ginv := g ^ -1;
    res := EmptyPlist(Length(L));
    for k in [1 .. Length(L)] do
      v := L[k ^ ginv];
      if v = 0 then res[k] := 0; else res[k] := v ^ g; fi;
    od;
    return res;
  end;
  ptCanon := function(L)
    local D, c;
    D := Digraph(List(L, x -> Filtered([x], y -> y <> 0)));
    c := BlissCanonicalLabelling(D);
    return ptAct(L, c);
  end;
  reps := [[0], [1]];   # level n = 1: both partial transformations are canonical
  t0 := NanosecondsSinceEpoch();
  for n in [2 .. maxN] do
    tlev := NanosecondsSinceEpoch();
    sample := [1 .. n];
    dict := NewDictionary(sample, true);
    newreps := [];
    nch := 0;
    for Q in reps do
      zeros := Positions(Q, 0);
      for Pn in [0 .. n] do
        for S in Combinations(zeros) do
          P := ShallowCopy(Q);
          P[n] := Pn;
          for i in S do P[i] := n; od;
          nch := nch + 1;
          c := ptCanon(P);
          if not KnowsDictionary(dict, c) then
            AddDictionary(dict, c, true);
            Add(newreps, c);
          fi;
        od;
      od;
    od;
    reps := newreps;
    nreps := Length(reps);
    ntot := Number(reps, L -> not 0 in L);
    ok1 := not IsBound(A126285[n]) or nreps = A126285[n];
    ok2 := not IsBound(A001372[n]) or ntot = A001372[n];
    Print(StringFormatted(
      "n={}  partial={} (A126285 ok={})  total={} (A001372 ok={})  ",
      n, nreps, ok1, ntot, ok2));
    Print(StringFormatted("children={}  level_s={}  cum_s={}\n", nch,
      Int((NanosecondsSinceEpoch() - tlev) / 1000000000),
      Int((NanosecondsSinceEpoch() - t0) / 1000000000)));
    if not (ok1 and ok2) then
      Print("MISMATCH at n=", n, " -- stopping\n");
      return;
    fi;
    if (NanosecondsSinceEpoch() - t0) / 1000000000 > budgetSec then
      Print("budget reached after n=", n, "\n");
      return;
    fi;
  od;
end;;

_OrderlyRun(ORDERLY_MAXN, ORDERLY_BUDGET);
