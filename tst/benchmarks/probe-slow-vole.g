# Probe for Vole's performance on a hand-picked list of slow-GAP inputs.
#
# Usage:
#   gap -q -c 'LOG := "vole-on-slow.txt"; Read("tst/benchmarks/probe-slow-vole.g"); QUIT;'
#
# By default times every refiner variant and every wrapper variant
# (60s/variant cap) against a fixed list of inputs known to be slow in
# GAP (see probe-slow-gap.g for the discovery script).
#
# Outputs go to LOG (default "tst/benchmarks/vole-on-slow.txt") and
# can be cross-checked against the GAP times from probe-slow-gap.g.

LoadPackage("vole", false);;
LoadPackage("io", false);;
LoadPackage("primgrp", false);;
Read("tst/bank/helpers.g");
Read("tst/bank/jnp.g");

if not IsBoundGlobal("LOG") then
    LOG := "tst/benchmarks/vole-on-slow.txt";
fi;
if not IsBoundGlobal("PER_CALL_SECONDS") then
    PER_CALL_SECONDS := 60;
fi;

PrintTo(LOG, "# probe-slow-vole.g  per_call_seconds=",
        PER_CALL_SECONDS, "\n");

PrintFlush := function(s) Print(s); AppendTo(LOG, s); end;

_gapChild := function(gens, n)
    local t, N, ms;
    t := NanosecondsSinceEpoch();
    N := Normalizer(SymmetricGroup(n), Group(gens));
    ms := Int((NanosecondsSinceEpoch() - t) / 1000000);
    return rec(ms := ms, size := Size(N));
end;

_voleRefiner := function(gens, n, variant)
    local refiner, t, N, ms;
    refiner := GB_Con.(Concatenation("Normaliser", variant))(Group(gens));
    t := NanosecondsSinceEpoch();
    N := VoleFind.Group(SymmetricGroup(n), refiner);
    ms := Int((NanosecondsSinceEpoch() - t) / 1000000);
    return rec(ms := ms, size := Size(N));
end;

_voleWrapper := function(gens, n, wrapperName)
    local t, N, ms;
    t := NanosecondsSinceEpoch();
    N := Vole.Normalizer(SymmetricGroup(n), Group(gens)
                         : wrapper := wrapperName);
    ms := Int((NanosecondsSinceEpoch() - t) / 1000000);
    return rec(ms := ms, size := Size(N));
end;

# Time GAP + each Vole variant on (name, gens, n), log all results.
benchInput := function(name, gens, n)
    local timeoutRec, raw, gap_ms, gap_sz, v;
    timeoutRec := rec(seconds := PER_CALL_SECONDS);
    PrintFlush(Concatenation("\n## ", name, "  n=", String(n), "\n"));

    # GAP first
    raw := IO_CallWithTimeout(timeoutRec, _gapChild, gens, n);
    if Length(raw) >= 2 and raw[1] = true then
        gap_ms := raw[2].ms;
        gap_sz := raw[2].size;
        PrintFlush(Concatenation("  gap  ms=", String(gap_ms),
            "  |N|=", String(gap_sz), "\n"));
    else
        PrintFlush("  gap  TIMEOUT/CRASH\n");
        return;
    fi;

    # Vole refiner variants
    for v in ["Orbital", "OrbitalRegOrbit", "OrbitalRegOrbitChar"] do
        raw := IO_CallWithTimeout(timeoutRec, _voleRefiner, gens, n, v);
        if Length(raw) >= 2 and raw[1] = true then
            PrintFlush(Concatenation("  ", v, "  ms=",
                String(raw[2].ms), "  eq=",
                String(raw[2].size = gap_sz), "\n"));
        elif Length(raw) >= 1 and raw[1] = false then
            PrintFlush(Concatenation("  ", v, "  TIMEOUT\n"));
        else
            PrintFlush(Concatenation("  ", v, "  CRASH\n"));
        fi;
    od;

    # Vole wrappers (default refiner)
    for v in ["direct", "ByOrbits"] do
        raw := IO_CallWithTimeout(timeoutRec, _voleWrapper, gens, n, v);
        if Length(raw) >= 2 and raw[1] = true then
            PrintFlush(Concatenation("  wrap:", v, "  ms=",
                String(raw[2].ms), "  eq=",
                String(raw[2].size = gap_sz), "\n"));
        elif Length(raw) >= 1 and raw[1] = false then
            PrintFlush(Concatenation("  wrap:", v, "  TIMEOUT\n"));
        else
            PrintFlush(Concatenation("  wrap:", v, "  CRASH\n"));
        fi;
    od;
end;

# Default suite of slow-GAP inputs. Override INPUTS to test a different
# list — each entry rec(name, gens, n).
if not IsBoundGlobal("INPUTS") then
    INPUTS := [];
    # Chang JnP subdirects from probe-slow-gap.g.
    rs := RandomSource(IsMersenneTwister, 20260518);
    for spec in [[3, 10], [3, 12]] do
        p := spec[1]; k := spec[2];
        H := _BankJnPRandomSubdirect(p, k, rs);
        Add(INPUTS, rec(
            name := Concatenation("jnp_subdirect(", String(p), ",",
                                  String(k), ")"),
            gens := GeneratorsOfGroup(H),
            n := p * k));
    od;
    # Larger AGL.
    for spec in [[2, 5], [2, 7], [3, 3], [3, 5], [3, 7]] do
        d := spec[1]; p := spec[2]; n := p ^ d;
        if d = 1 then
            G := First(List([1..NrPrimitiveGroups(p)], i -> PrimitiveGroup(p, i)),
                       H -> Size(H) = p * (p-1));
        else
            G := First(List([1..NrPrimitiveGroups(n)], i -> PrimitiveGroup(n, i)),
                       H -> HasSize(H) and Size(H) = n * Size(GL(d, p)));
        fi;
        if G = fail then continue; fi;
        Add(INPUTS, rec(
            name := Concatenation("AGL(", String(d), ",", String(p), ")"),
            gens := GeneratorsOfGroup(G),
            n := n));
    od;
fi;

for input in INPUTS do
    benchInput(input.name, input.gens, input.n);
od;

PrintFlush("# DONE\n");
QUIT;
