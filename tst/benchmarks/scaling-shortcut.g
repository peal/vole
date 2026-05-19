# Benchmark the root_aut_shortcut on / off on the abelian-regular
# (C_p)^k family. The shortcut runs one sub-search to find
# Aut(post-init digraph stack), then checks each returned generator
# against the outer refiners. For 2-closed inputs (which every
# (C_p)^k is — see probe-orbital-set-aut.g) the shortcut succeeds
# at the root and the main partition backtrack is skipped.
#
# Whether that's actually a win depends on how the cost of the
# Aut sub-search compares with the cost of the direct N(H) search.
# This benchmark surfaces the trade-off.

LoadPackage("vole", false);
LoadPackage("io", false);

_TimeBoth := function(label, H)
    local n, gN, gms, vmsOff, vmsOn, vN, t;
    n := LargestMovedPoint(H);
    t := NanosecondsSinceEpoch();
    gN := Size(Normalizer(SymmetricGroup(n), H));
    gms := Int((NanosecondsSinceEpoch() - t) / 1000000);

    _Vole.RootAutShortcut := false;
    t := NanosecondsSinceEpoch();
    vN := Size(Vole.Normalizer(SymmetricGroup(n), H));
    vmsOff := Int((NanosecondsSinceEpoch() - t) / 1000000);
    if vN <> gN then
        Print(label, "  *** MISMATCH (shortcut off): |N|=", vN, "\n");
        return;
    fi;

    _Vole.RootAutShortcut := true;
    t := NanosecondsSinceEpoch();
    vN := Size(Vole.Normalizer(SymmetricGroup(n), H));
    vmsOn := Int((NanosecondsSinceEpoch() - t) / 1000000);
    if vN <> gN then
        Print(label, "  *** MISMATCH (shortcut on): |N|=", vN, "\n");
        return;
    fi;

    Print(label, "  deg=", n, "  |H|=", Size(H), "  |N|=", gN,
          "  GAP=", gms, "ms  Vole(off)=", vmsOff,
          "ms  Vole(on)=", vmsOn, "ms\n");
end;

# (C_p)^k abelian regular: pk points, k disjoint p-cycles, |H|=p^k.
# Limit to small p/k for shortcut-on — the Rust sub-search's cost
# scales with digraph stack size, which grows with p (number of
# orbital graphs per orbit) and k (number of orbits). Beyond
# (p, k) ≈ (5, 4) the shortcut-on case explodes (162s on C_5^5,
# minutes on C_7^k).
for spec in [[3,2],[3,3],[3,4],[3,5],[3,6],[3,7],
             [5,2],[5,3],[5,4],
             [7,2]] do
    if spec[1] * spec[2] > 25 then continue; fi;
    _TimeBoth(Concatenation("C_", String(spec[1]), "^", String(spec[2])),
              Group(List([0 .. spec[2]-1],
                  i -> CycleFromList([i*spec[1]+1 .. (i+1)*spec[1]]))));
od;

QUIT;
