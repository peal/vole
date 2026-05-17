# Intransitive sweep: products and wreath products of small transitive
# groups. The headline target for Phase E (orbit-by-orbit wrapper) and
# Phase F (DDPD); also a strong stressor of Phase A.
#
# Inputs are constructed combinatorially rather than from a library:
# direct products G_1 x G_2 on disjoint supports, and (later) wreath
# product images.

if not IsBoundGlobal("BankCompareNormaliser") then
    Read("tst/bank/helpers.g");
fi;

# Total degree cap (sum of factor degrees) per mode.
BankIntransitiveTotalCap := function(mode)
    if mode = "quick" then
        return 12;
    elif mode = "nightly" then
        return 18;
    elif mode = "full" then
        return 30;
    else
        Error("BankIntransitiveTotalCap: unknown mode ", mode);
    fi;
end;

# Build a permutation group on [1..a+b] that acts as G1 on [1..a] and
# G2 on [a+1..a+b]. We shift the second group's perms via conjugation by
# a renaming permutation.
_BankShiftPerm := function(p, shift)
    local lmp, sigma;
    lmp := LargestMovedPoint(p);
    if lmp = 0 then
        return ();
    fi;
    sigma := MappingPermListList([1 .. lmp], [shift + 1 .. shift + lmp]);
    return p ^ sigma;
end;

BankDirectProductOnPoints := function(G1, G2)
    local a, gens, gen;
    a := LargestMovedPoint(G1);
    gens := ShallowCopy(GeneratorsOfGroup(G1));
    for gen in GeneratorsOfGroup(G2) do
        Add(gens, _BankShiftPerm(gen, a));
    od;
    return Group(gens);
end;

RunBank_intransitive := function(mode)
    local total_cap, a, b, i, j, na, nb, G1, G2, P;
    total_cap := BankIntransitiveTotalCap(mode);
    BankResetStats();
    Print(StringFormatted("[intransitive] mode={}, total-degree cap={}\n",
                          mode, total_cap));
    for a in [2 .. total_cap - 2] do
        for b in [2 .. total_cap - a] do
            na := NrTransitiveGroups(a);
            nb := NrTransitiveGroups(b);
            for i in [1 .. na] do
                for j in [1 .. nb] do
                    G1 := TransitiveGroup(a, i);
                    G2 := TransitiveGroup(b, j);
                    P := BankDirectProductOnPoints(G1, G2);
                    BankCompareNormaliser(a + b, P);
                od;
            od;
        od;
    od;
    BankReportStats("intransitive");
    return _BankStats.fail = 0;
end;
