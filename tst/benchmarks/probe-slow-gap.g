# Probe for input classes where GAP's Normalizer is slow (>= threshold ms).
#
# Useful for finding genuine algorithmic gaps to Vole that startup
# overhead can't explain. Designed to be run interactively, e.g.
#
#   gap -q -c 'LOG := "find.txt"; Read("tst/benchmarks/probe-slow-gap.g"); QUIT;'
#
# Each candidate is timed via IO_CallWithTimeout with a per-call cap so
# the loop survives a 19-minute outlier. Outputs are appended to LOG
# (default "tst/benchmarks/slow-gap-finds.txt") so they survive a crash.

LoadPackage("vole", false);;
LoadPackage("io", false);;
LoadPackage("primgrp", false);;
LoadPackage("transgrp", false);;
Read("tst/bank/helpers.g");
Read("tst/bank/jnp.g");

if not IsBoundGlobal("LOG") then
    LOG := "tst/benchmarks/slow-gap-finds.txt";
fi;
if not IsBoundGlobal("THRESHOLD_MS") then
    THRESHOLD_MS := 200;
fi;
if not IsBoundGlobal("PER_CALL_SECONDS") then
    PER_CALL_SECONDS := 60;
fi;

PrintTo(LOG, "# probe-slow-gap.g  threshold_ms=", THRESHOLD_MS,
        "  per_call_seconds=", PER_CALL_SECONDS, "\n");

_gapNormChild := function(gens, n)
    local t, N, ms;
    t := NanosecondsSinceEpoch();
    N := Normalizer(SymmetricGroup(n), Group(gens));
    ms := Int((NanosecondsSinceEpoch() - t) / 1000000);
    return rec(ms := ms, size := Size(N));
end;

# Bench a single input. Per-call wall-clock cap; results above
# THRESHOLD_MS get logged.
bench := function(name, G, n)
    local timeoutRec, raw;
    if Length(GeneratorsOfGroup(G)) = 0 then return; fi;
    timeoutRec := rec(seconds := PER_CALL_SECONDS);
    raw := IO_CallWithTimeout(timeoutRec, _gapNormChild,
                              GeneratorsOfGroup(G), n);
    if Length(raw) >= 2 and raw[1] = true then
        if raw[2].ms >= THRESHOLD_MS then
            AppendTo(LOG,
                     name, "  n=", n, "  |G|=", Size(G),
                     "  gap_ms=", raw[2].ms,
                     "  |N|=", raw[2].size, "\n");
            Print(name, "  ms=", raw[2].ms, "\n");
        fi;
    elif Length(raw) >= 1 and raw[1] = false then
        AppendTo(LOG, name, "  n=", n, "  gap_TIMEOUT (>",
                 PER_CALL_SECONDS, "s)\n");
        Print(name, "  TIMEOUT\n");
    fi;
end;

rs := RandomSource(IsMersenneTwister, 20260518);;

Print("# Chang JnP random subdirect\n");
for p in [3, 5, 7] do
    for k in [10, 12, 14, 16] do
        if p * k > 90 then continue; fi;
        H := _BankJnPRandomSubdirect(p, k, rs);
        bench(Concatenation("jnp_subdirect(", String(p), ",", String(k), ")"),
              H, p * k);
    od;
od;

Print("# Larger primitives\n");
for n in [29, 31, 37, 41, 47] do
    if NrPrimitiveGroups(n) = fail then continue; fi;
    for k in [1 .. NrPrimitiveGroups(n)] do
        G := PrimitiveGroup(n, k);
        if Size(G) >= Factorial(n)/2 then continue; fi;
        if Size(G) > 10^11 then continue; fi;
        bench(Concatenation("PrimGrp(", String(n), ",", String(k), ")"),
              G, n);
    od;
od;

Print("# Larger AGL\n");
for spec in [[1, 53], [1, 71], [1, 97], [1, 127],
             [2, 7], [2, 11], [2, 13],
             [3, 5], [3, 7],
             [4, 3], [4, 5], [5, 2], [5, 3]] do
    d := spec[1]; p := spec[2]; n := p ^ d;
    if d = 1 then
        G := First(List([1..NrPrimitiveGroups(p)], i -> PrimitiveGroup(p, i)),
                   H -> Size(H) = p * (p-1));
    else
        G := First(List([1..NrPrimitiveGroups(n)], i -> PrimitiveGroup(n, i)),
                   H -> HasSize(H) and Size(H) = n * Size(GL(d, p)));
    fi;
    if G = fail then continue; fi;
    bench(Concatenation("AGL(", String(d), ",", String(p), ")"), G, n);
od;

Print("# Wreath products\n");
for spec in [[SymmetricGroup(5), SymmetricGroup(5), "S_5wrS_5", 25],
             [SymmetricGroup(5), SymmetricGroup(7), "S_5wrS_7", 35],
             [SymmetricGroup(7), SymmetricGroup(5), "S_7wrS_5", 35]] do
    G := WreathProduct(spec[1], spec[2]);
    bench(spec[3], G, spec[4]);
od;

Print("# Mathieu\n");
for spec in [[22, "M_22"], [23, "M_23"], [24, "M_24"]] do
    bench(spec[2], MathieuGroup(spec[1]), spec[1]);
od;

AppendTo(LOG, "# DONE\n");
Print("Done — see ", LOG, "\n");
QUIT;
