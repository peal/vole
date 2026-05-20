# Bigger normaliser benchmarks where wall time should clear Vole's
# ~5 ms IPC floor by a wide margin.  Each entry is sized to land
# above 100 ms total on one side or the other so the timing reads
# real search work, not framework overhead.
#
# Three regimes:
#   (A) Big (C_p)^k abelian regular.  Shortcut closes at the root
#       for every one of these, so Vole stays ~constant; GAP's
#       partition backtrack work grows.
#   (B) Big direct products of dihedrals and symmetrics.  Mix of
#       transitive constituents — shortcut closes some, not others.
#   (C) Transitive-only on big degree.  Worst case for the shortcut
#       because nothing factors; pure backtrack vs backtrack.
#
# Wall budget per call: 60 s.  Outputs label, |H|, Vole ms, GAP ms,
# and the |N|s for cross-check.

LoadPackage("vole", false);
LoadPackage("io", false);
LoadPackage("primgrp", false);
LoadPackage("transgrp", false);

_Shift := function(p, shift)
    local lmp, sigma;
    lmp := LargestMovedPoint(p);
    if lmp = 0 then return (); fi;
    sigma := MappingPermListList([1 .. lmp], [shift + 1 .. shift + lmp]);
    return p ^ sigma;
end;

_Disjoint := function(groups)
    local gens, shift, G, g;
    gens := []; shift := 0;
    for G in groups do
        for g in GeneratorsOfGroup(G) do Add(gens, _Shift(g, shift)); od;
        shift := shift + LargestMovedPoint(G);
    od;
    if IsEmpty(gens) then return Group(()); fi;
    return Group(gens);
end;

_TimeOne := function(label, fn)
    local raw, ms, val;
    raw := IO_CallWithTimeout(rec(seconds := 60),
        function()
            local t0, v;
            t0 := NanosecondsSinceEpoch();
            v := fn();
            return [v, Int((NanosecondsSinceEpoch() - t0) / 1000000)];
        end);
    if Length(raw) >= 2 and raw[1] = true then
        val := raw[2][1]; ms := raw[2][2];
    else
        val := fail; ms := -1;
    fi;
    return rec(val := val, ms := ms);
end;

_TimeBoth := function(label, H)
    local n, g, v;
    n := LargestMovedPoint(H);
    g := _TimeOne(label, {} -> Size(Normalizer(SymmetricGroup(n), H)));
    v := _TimeOne(label, {} -> Size(Vole.Normalizer(SymmetricGroup(n), H)));
    Print(label, "  n=", n, "  |H|=", Size(H),
          "  GAP=", g.ms, "ms", "  Vole=", v.ms, "ms");
    if g.val = fail then Print("  *gap timeout*"); fi;
    if v.val = fail then Print("  *vole timeout*"); fi;
    if g.val <> fail and v.val <> fail and g.val <> v.val then
        Print("  *** |N| mismatch: GAP=", g.val, " Vole=", v.val);
    fi;
    Print("\n");
end;

Print("=== (A) (C_p)^k abelian regular, deg up to 150 ===\n");
for spec in [[3,15], [3,20], [5,10], [5,15], [7,10], [7,15], [11,10]] do
    if spec[1] * spec[2] > 200 then continue; fi;
    _TimeBoth(Concatenation("(C_", String(spec[1]), ")^", String(spec[2])),
              _Disjoint(List([1..spec[2]],
                  i -> CyclicGroup(IsPermGroup, spec[1]))));
od;

Print("\n=== (B) Big direct products of dihedrals / symmetrics ===\n");
for spec in [[10,8], [12,8], [12,10]] do
    _TimeBoth(Concatenation("D_", String(spec[1]), "^", String(spec[2])),
              _Disjoint(List([1..spec[2]],
                  i -> DihedralGroup(IsPermGroup, spec[1]))));
od;
for spec in [[5,10], [6,10]] do
    _TimeBoth(Concatenation("S_", String(spec[1]), "^", String(spec[2])),
              _Disjoint(List([1..spec[2]],
                  i -> SymmetricGroup(spec[1]))));
od;

Print("\n=== (C) Big wreath products (transitive constituents) ===\n");
for spec in [[5,5], [5,6], [6,5], [7,4], [8,4]] do
    if spec[1] * spec[2] > 60 then continue; fi;
    _TimeBoth(Concatenation("S_", String(spec[1]), "wrS_", String(spec[2])),
              WreathProduct(SymmetricGroup(spec[1]), SymmetricGroup(spec[2])));
od;
for spec in [[10,4], [12,4]] do
    if QuoInt(spec[1], 2) * spec[2] > 60 then continue; fi;
    _TimeBoth(Concatenation("D_", String(spec[1]), "wrS_", String(spec[2])),
              WreathProduct(DihedralGroup(IsPermGroup, spec[1]), SymmetricGroup(spec[2])));
od;

Print("\n=== (D) Big TransGrp entries (transitive, not affine) ===\n");
# TransGrp degrees 20-30 with random selections.  Pick ones with
# small order so GAP's DoNormalizerSA doesn't dispose them via
# NormalizerParentSA — keep them at backtrack-territory size.
for spec in [[20, 100], [20, 500], [20, 1000], [22, 50], [24, 100], [24, 500]] do
    if spec[2] > NrTransitiveGroups(spec[1]) then continue; fi;
    _TimeBoth(Concatenation("TG(", String(spec[1]), ";", String(spec[2]), ")"),
              TransitiveGroup(spec[1], spec[2]));
od;

QUIT;
