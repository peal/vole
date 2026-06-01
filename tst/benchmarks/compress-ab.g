# A/B benchmark for the graph-compression pass (_BTKit.compressGraph).
# Toggles _BTKit.COMPRESS_ENABLE to compare end-to-end normaliser wall time
# with compression ON vs OFF, interleaved, best-of-N (to blunt timing noise),
# against GAP. Wall clock (Vole forks a Rust subprocess).
#
# Usage: gap -r tst/benchmarks/compress-ab.g

LoadPackage("vole", false);
SizeScreen([4096, 4096]);

REPS := 5;

bestOf := function(H, enable)
    local G, n, t, best, i, N;
    n := LargestMovedPoint(H);
    G := SymmetricGroup(n);
    _BTKit.COMPRESS_ENABLE := enable;
    best := 1000000000;
    for i in [1 .. REPS] do
        t := NanosecondsSinceEpoch();
        N := Vole.Normalizer(G, H : refiner := "Orbital");
        t := Int((NanosecondsSinceEpoch() - t) / 1000000);
        if t < best then best := t; fi;
    od;
    return best;
end;

run := function(label, H)
    local n, NG, gms, t, on, off;
    n := LargestMovedPoint(H);
    # GAP baseline (best of 3)
    NG := Normalizer(SymmetricGroup(n), H);
    gms := 1000000000;
    for t in [1 .. 3] do
        t := NanosecondsSinceEpoch();
        Normalizer(SymmetricGroup(n), H);
        t := Int((NanosecondsSinceEpoch() - t) / 1000000);
        if t < gms then gms := t; fi;
    od;
    # interleave ON/OFF to share any drift
    off := bestOf(H, false);
    on  := bestOf(H, true);
    off := Minimum(off, bestOf(H, false));
    on  := Minimum(on,  bestOf(H, true));
    Print(label, " deg=", n,
          " | GAP=", gms, "ms  Vole OFF=", off, "ms  ON=", on, "ms",
          "  (ON/OFF=", Int(100 * on / Maximum(off,1)), "%)\n");
end;

# warm up the subprocess
Vole.Normalizer(SymmetricGroup(6), Group([(1,2,3),(4,5,6)]));

run("S5wrS5",   WreathProduct(SymmetricGroup(5),  SymmetricGroup(5)));
run("S10wrS10", WreathProduct(SymmetricGroup(10), SymmetricGroup(10)));
run("S10wrS15", WreathProduct(SymmetricGroup(10), SymmetricGroup(15)));
run("S20wrS10", WreathProduct(SymmetricGroup(20), SymmetricGroup(10)));
run("S15wrS20", WreathProduct(SymmetricGroup(15), SymmetricGroup(20)));
run("S10wrS25", WreathProduct(SymmetricGroup(10), SymmetricGroup(25)));

QUIT;
