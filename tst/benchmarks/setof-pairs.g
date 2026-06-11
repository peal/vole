# Benchmark: canonical enumeration of (pairs of) transformations and partial
# permutations up to conjugacy, via the VoleRefiner.SetOf / TupleOf / MultisetOf
# combinators over GraphBacktracking's conjugacy refiners.
#
# Background. GB_Con.TransformationConjugacy(x, x) and
# GB_Con.PartialPermConjugacy(x, x) refine "is conjugate to x" under S_n (each
# encodes x by its functional digraph internally). Combined:
#   * a single element  <-> the refiner alone;
#   * an ORDERED pair (simultaneous conjugation) <-> VoleRefiner.TupleOf;
#   * an UNORDERED pair <-> VoleRefiner.SetOf (distinct) / MultisetOf (diagonal).
# The canonical permutation moves the element(s) to a canonical conjugate, so
# counting distinct canonical forms counts orbits -- a published enumeration: the
# single-transformation column is OEIS A001372 (mapping patterns).
#
# This is a heavy, fan-out workload -- for transformations at n = 4 it performs
# 256 + 256^2 + (256 choose 2)+256 = ~98k canonical-image searches -- so it
# stresses the combinators far harder than the unit tests, while still checking
# every count against a known-good table (EXPECTED below, validated against
# GAP's Orbits in tst/canonical-pairs.tst and by hand for small n).
#
# Run:
#   gap -q -c 'Read("tst/benchmarks/setof-pairs.g"); QUIT;'
# Override the degree cap (default 4; n = 4 takes a few minutes, n = 5 is huge):
#   gap -q -c 'SETOF_PAIRS_MAXN := 3;; Read("tst/benchmarks/setof-pairs.g"); QUIT;'
#
# Output CSV (also written to tst/benchmarks/setof-pairs.csv):
#   structure,n,kind,combinator,count,expected,ok,images,wall_ms,images_per_s,nodes

LoadPackage("vole", false);

if not IsBoundGlobal("SETOF_PAIRS_MAXN") then
    SETOF_PAIRS_MAXN := 4;
fi;

# Known-good orbit counts [single, ordered pair, unordered pair], indexed by n.
# Validated against GAP's Orbits (see tst/canonical-pairs.tst).
_SetOfPairsExpected := rec(
    transformations := [[1, 1, 1], [3, 10, 7], [7, 129, 74], [19, 2836, 1474]],
    partialperms    := [[2, 4, 3], [5, 29, 18], [10, 216, 120], [20, 1994, 1044]]);

# A canonical-image search plus its search-node count, accumulated globally.
_SetOfPairsNodes := 0;
_SetOfPairsCanon := function(refiner, n)
    local c;
    c := VoleFind.CanonicalPerm(SymmetricGroup(n), refiner);
    if IsBound(_Vole.LastStats) and IsBound(_Vole.LastStats.search_nodes) then
        _SetOfPairsNodes := _SetOfPairsNodes + _Vole.LastStats.search_nodes;
    fi;
    return c;
end;

# Time and run one (structure, n, kind) cell; emit a CSV row; return ok. R is the
# conjugacy-refiner constructor; elts the monoid's elements.
_SetOfPairsCell := function(structure, n, kind, combinator, elts, R, expected, out)
    local t, nodes0, forms, k, i, j, c, count, ms, images, rate, ok;
    t := NanosecondsSinceEpoch();
    nodes0 := _SetOfPairsNodes;
    k := Length(elts);
    forms := [];
    if kind = "single" then
        for i in [1 .. k] do
            c := _SetOfPairsCanon(R(elts[i], elts[i]), n);
            Add(forms, elts[i] ^ c);
        od;
    elif kind = "ordered" then
        for i in [1 .. k] do
            for j in [1 .. k] do
                c := _SetOfPairsCanon(
                    VoleRefiner.TupleOf([R(elts[i], elts[i]), R(elts[j], elts[j])]), n);
                Add(forms, [elts[i] ^ c, elts[j] ^ c]);
            od;
        od;
    else   # "unordered": SetOf off the diagonal, single canonical form on it
        for i in [1 .. k] do
            for j in [i .. k] do
                if i = j then
                    c := _SetOfPairsCanon(R(elts[i], elts[i]), n);
                    Add(forms, SortedList([elts[i] ^ c, elts[i] ^ c]));
                else
                    c := _SetOfPairsCanon(
                        VoleRefiner.SetOf([R(elts[i], elts[i]), R(elts[j], elts[j])]), n);
                    Add(forms, SortedList([elts[i] ^ c, elts[j] ^ c]));
                fi;
            od;
        od;
    fi;
    count := Size(Set(forms));
    images := Length(forms);
    ms := Int((NanosecondsSinceEpoch() - t) / 1000000);
    rate := 0;
    if ms > 0 then rate := Int(images * 1000 / ms); fi;
    ok := count = expected;
    PrintTo(out, StringFormatted("{},{},{},{},{},{},{},{},{},{},{}\n",
        structure, n, kind, combinator, count, expected, ok,
        images, ms, rate, _SetOfPairsNodes - nodes0));
    Print(StringFormatted("  {} n={} {}: count={} (expected {}) ok={}  [{} images, {} ms, {} img/s]\n",
        structure, n, kind, count, expected, ok, images, ms, rate));
    return ok;
end;

_SetOfPairsRun := function()
    local out, allok, structure, spec, n, elts, exp, kinds, combs, i;
    out := OutputTextFile("tst/benchmarks/setof-pairs.csv", false);
    SetPrintFormattingStatus(out, false);
    PrintTo(out, "structure,n,kind,combinator,count,expected,ok,images,",
                 "wall_ms,images_per_s,nodes\n");
    allok := true;
    kinds := ["single", "ordered", "unordered"];
    combs := ["(refiner)", "TupleOf", "SetOf"];
    for spec in [["transformations", FullTransformationMonoid,
                  GB_Con.TransformationConjugacy],
                 ["partialperms", SymmetricInverseMonoid,
                  GB_Con.PartialPermConjugacy]] do
        structure := spec[1];
        for n in [1 .. SETOF_PAIRS_MAXN] do
            elts := Elements(spec[2](n));
            exp := _SetOfPairsExpected.(structure)[n];
            Print(StringFormatted("{} n={}: |M|={}\n", structure, n, Length(elts)));
            for i in [1 .. 3] do
                if not _SetOfPairsCell(structure, n, kinds[i], combs[i],
                                       elts, spec[3], exp[i], out) then
                    allok := false;
                fi;
            od;
        od;
    od;
    CloseStream(out);
    Print("\nTotal canonical-image search nodes: ", _SetOfPairsNodes, "\n");
    Print("All counts match the expected table: ", allok, "\n");
end;

_SetOfPairsRun();
