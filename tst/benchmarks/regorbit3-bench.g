# RegularOrbit3 cross-propagation benchmark.
# Compares: Orbital, RegOrbit, RegOrbitCross, RegOrbitCrossNoPropose
# Measures CPU time (via Runtime()), not wall time.
# Results appended to regorbit3-bench.csv in project root.
#
# Usage: gap -r tst/benchmarks/regorbit3-bench.g

Read("tst/test_functions.g");

BENCH_OUT := "regorbit3-bench.csv";
_benchOne := function(G, H, refinerName)
    local t, N, N_gap, ok;
    t := Runtime();
    # Call through wrapper to get proper option handling
    if refinerName = "Orbital" then
        N := Vole.Normalizer(G, H : refiner := "Orbital");
    elif refinerName = "OrbitalRegOrbit" then
        N := Vole.Normalizer(G, H : refiner := "OrbitalRegOrbit");
    elif refinerName = "OrbitalRegOrbitCross" then
        N := Vole.Normalizer(G, H : refiner := "OrbitalRegOrbitCross");
    elif refinerName = "OrbitalRegOrbitCrossNoPropose" then
        N := Vole.Normalizer(G, H
            : refiner := "OrbitalRegOrbitCrossNoPropose");
    fi;
    t := Runtime() - t;
    N_gap := Normalizer(G, H);
    if IsPermGroup(N) then
        ok := N = N_gap;
    else
        ok := "NOT_GROUP";
    fi;
    return [t, ok];
end;

_doGroup := function(label, G, H)
    local results, r, n, nreg, refinerNames, res;
    n := LargestMovedPoint(G);
    nreg := Length(Filtered(Orbits(H, [1..n]), o -> Length(o) = Size(H)));
    results := [];

    refinerNames := ["Orbital", "OrbitalRegOrbit",
                     "OrbitalRegOrbitCross",
                     "OrbitalRegOrbitCrossNoPropose"];
    for r in refinerNames do
        res := _benchOne(G, H, r);
        Add(results, rec(name := r, t := res[1], ok := res[2]));
    od;

    AppendTo(BENCH_OUT, label, ",", Size(H), ",", n, ",", nreg, ",");
    for r in results do
        AppendTo(BENCH_OUT, r.t, ",", r.ok, ",");
    od;
    AppendTo(BENCH_OUT, "\n");

    Print(label, " |H|=", Size(H), " n=", n, " reg=", nreg, " ",
          results[1].name, "=", results[1].t, "ms(",
          results[1].ok, ") ",
          results[2].name, "=", results[2].t, "ms(",
          results[2].ok, ") ",
          results[3].name, "=", results[3].t, "ms(",
          results[3].ok, ") ",
          results[4].name, "=", results[4].t, "ms(",
          results[4].ok, ")\n");
end;

Print("regorbit3-bench starting at ", Runtime(), "\n");

# Wipe and write header
PrintTo(BENCH_OUT,
    "label,|H|,n,regOrbits,",
    "Orbital_t,Orbital_ok,",
    "RegOrbit_t,RegOrbit_ok,",
    "RegOrbitCross_t,RegOrbitCross_ok,",
    "RegOrbitCrossNoPropose_t,RegOrbitCrossNoPropose_ok\n");

########################################################################
# CLASS 1: Regular cyclic groups (C_p on p points)
# Cross-propagation is redundant here (regular orbit = whole domain).
########################################################################
for p in [5, 7, 11, 13, 17, 19, 23, 29] do
    _doGroup(Concatenation("RegC", String(p)),
        SymmetricGroup(p),
        Group([MappingPermListList([1..p],
                Concatenation([2..p],[1]))]));
od;

########################################################################
# CLASS 2: Regular orbit + non-trivial other orbits.
# H acts regularly on one orbit and non-regularly (with kernel) on
# others.  This is where RegularOrbit3 should shine.
#
# Construction: for order m = a*b where b > 1, H = <gen> where
# gen is an a-cycle on {1..a} (regular!) and a product of b-cycles
# on {a+1..a+k*b}.  The orbit on {1..a} has size a = |H| → regular.
# The other orbits have size b < a → non-regular.
########################################################################
# C_6 = regular 6-cycle on {1..6} + three 2-cycles on {7..12}
_doGroup("Reg6+3x2", SymmetricGroup(12), Group([
    (1,2,3,4,5,6)(7,8)(9,10)(11,12)]));
# C_10 = regular 10-cycle on {1..10} + five 2-cycles on {11..20}
_doGroup("Reg10+5x2", SymmetricGroup(20), Group([
    MappingPermListList([1..10], Concatenation([2..10],[1]))
    * (11,12)(13,14)(15,16)(17,18)(19,20)]));
# C_12 = regular 12-cycle on {1..12} + 4-cycles on {13..16},{17..20}
_doGroup("Reg12+2x4", SymmetricGroup(20), Group([
    MappingPermListList([1..12], Concatenation([2..12],[1]))
    * (13,14,15,16)(17,18,19,20)]));
# C_14 = regular 14-cycle on {1..14} + 7-cycles on {15..21},{22..28}
_doGroup("Reg14+2x7", SymmetricGroup(28), Group([
    MappingPermListList([1..14], Concatenation([2..14],[1]))
    * MappingPermListList(15+[0..6], [16,17,18,19,20,21,15])
    * MappingPermListList(22+[0..6], [23,24,25,26,27,28,22])]));
# C_15 = regular 15-cycle on {1..15} + 5-cycles on {16..20},{21..25}
_doGroup("Reg15+2x5", SymmetricGroup(25), Group([
    MappingPermListList([1..15], Concatenation([2..15],[1]))
    * MappingPermListList(16+[0..4], [17,18,19,20,16])
    * MappingPermListList(21+[0..4], [22,23,24,25,21])]));

########################################################################
# CLASS 3: Regular C_p × S_k product groups
# C_p is regular on its orbit; S_k acts naturally on k points.
# Useful to see if cross-propagation helps on "mixed" intransitive.
########################################################################
# C5 regular + S4 on 4 extra points + trivial on 8 more
# (so there are non-trivial non-regular orbits for cross-prop)
_doGroup("C5reg_S4ext", SymmetricGroup(13), Group([
    (1,2,3,4,5),          # C5 regular on {1..5}
    (6,7,8,9), (6,7)       # S4 on {6..9}
    # plus trivial on {10..13} as fixed points
]));
# C7 regular + S5 on 5 extra points
_doGroup("C7reg_S5ext", SymmetricGroup(12), Group([
    (1,2,3,4,5,6,7),      # C7 regular on {1..7}
    (8,9,10,11,12), (8,9)   # S5 on {8..12}
]));

########################################################################
# CLASS 4: Transitive groups from the library (for general sanity)
########################################################################
for d in [5, 6, 7, 8, 9] do
    for k in [1 .. Minimum(NrTransitiveGroups(d), 10)] do
        _doGroup(Concatenation("T(", String(d), ",", String(k), ")"),
            SymmetricGroup(d), TransitiveGroup(d, k));
    od;
od;

########################################################################
# CLASS 5: AGL family — Phase D domain (no E-regular orbit)
########################################################################
_doGroup("AGL(2,3)", SymmetricGroup(9),
    Image(RegularActionHomomorphism(AbelianGroup([3,3]))));
# Note: this is elementary abelian C_3^2 regular; its normaliser is AGL(2,3).
# Phase C detects the regular orbit of C_3^2 itself.

_doGroup("AGL(1,7)_real", SymmetricGroup(7),
    TransitiveGroup(7, 4));  # 2F_42(7):2 = AGL(1,7)

Print("\nregorbit3-bench done at ", Runtime(), "\n");
QUIT;
