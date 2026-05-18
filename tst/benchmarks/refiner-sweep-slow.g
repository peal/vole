# Sweep refiner choices across the 4 Vole-SLOW subdirect cases, with
# and without the ByOrbits L-overgroup. The hypothesis from the
# D_8^3 case is that the default refiner `OrbitalRegOrbitChar` is
# pathological on these inputs and every other refiner is fine.

LoadPackage("vole", false);
LoadPackage("io", false);
Read("tst/bank/helpers.g");
Read("tst/bank/subdirect.g");

_ReproduceMixer := function(spec_idx, sample_idx)
    local rs, specs, spec, n_total, deg_cap, samples, mixer, i, k;
    rs := RandomSource(IsMersenneTwister, 20260518);
    deg_cap := 28; samples := 2;
    specs := [
        rec(transitives := [DihedralGroup(IsPermGroup, 10),
                            DihedralGroup(IsPermGroup, 10)], num_gens := 3),
        rec(transitives := [DihedralGroup(IsPermGroup, 14),
                            DihedralGroup(IsPermGroup, 14)], num_gens := 3),
        rec(transitives := [SymmetricGroup(5), SymmetricGroup(5)], num_gens := 3),
        rec(transitives := [DihedralGroup(IsPermGroup, 8),
                            DihedralGroup(IsPermGroup, 8),
                            DihedralGroup(IsPermGroup, 8)], num_gens := 3),
        rec(transitives := [DihedralGroup(IsPermGroup, 12),
                            DihedralGroup(IsPermGroup, 12),
                            DihedralGroup(IsPermGroup, 12)], num_gens := 4),
        rec(transitives := [SymmetricGroup(4), SymmetricGroup(4),
                            SymmetricGroup(4)], num_gens := 4),
        rec(transitives := [SymmetricGroup(4), SymmetricGroup(5),
                            SymmetricGroup(6)], num_gens := 4),
        rec(transitives := [CyclicGroup(IsPermGroup, 5),
                            CyclicGroup(IsPermGroup, 5),
                            CyclicGroup(IsPermGroup, 5)], num_gens := 2),
        rec(transitives := [CyclicGroup(IsPermGroup, 7),
                            CyclicGroup(IsPermGroup, 7),
                            CyclicGroup(IsPermGroup, 7)], num_gens := 2),
        rec(transitives := [DihedralGroup(IsPermGroup, 8),
                            DihedralGroup(IsPermGroup, 8),
                            DihedralGroup(IsPermGroup, 8),
                            DihedralGroup(IsPermGroup, 8)], num_gens := 4),
        rec(transitives := [DihedralGroup(IsPermGroup, 12),
                            DihedralGroup(IsPermGroup, 12),
                            DihedralGroup(IsPermGroup, 12),
                            DihedralGroup(IsPermGroup, 12)], num_gens := 5),
        rec(transitives := [SymmetricGroup(4), SymmetricGroup(4),
                            SymmetricGroup(4), SymmetricGroup(4)], num_gens := 5),
        rec(transitives := [DihedralGroup(IsPermGroup, 8),
                            DihedralGroup(IsPermGroup, 8),
                            DihedralGroup(IsPermGroup, 8),
                            DihedralGroup(IsPermGroup, 8),
                            DihedralGroup(IsPermGroup, 8)], num_gens := 5),
        rec(transitives := [SymmetricGroup(3), SymmetricGroup(3),
                            SymmetricGroup(3), SymmetricGroup(3),
                            SymmetricGroup(3)], num_gens := 4),
        rec(transitives := [DihedralGroup(IsPermGroup, 10),
                            DihedralGroup(IsPermGroup, 10),
                            DihedralGroup(IsPermGroup, 10),
                            DihedralGroup(IsPermGroup, 10),
                            DihedralGroup(IsPermGroup, 10)], num_gens := 6) ];
    for i in [1 .. Length(specs)] do
        spec := specs[i];
        n_total := Sum(spec.transitives, LargestMovedPoint);
        if n_total > deg_cap then continue; fi;
        for k in [1 .. samples] do
            mixer := BankBuildSubdirectMixer(
                rs, spec.transitives, spec.num_gens,
                Length(spec.transitives) - 1, 40);
            if i = spec_idx and k = sample_idx then return mixer; fi;
        od;
    od;
    return fail;
end;

cases := [
    rec(label := "D_8^3 sample 2", spec := 4,  sample := 2),
    rec(label := "S_4^4 sample 1", spec := 12, sample := 1),
    rec(label := "S_4^4 sample 2", spec := 12, sample := 2),
    rec(label := "D_8^5 sample 2", spec := 13, sample := 2) ];

_time_refiner := function(case_label, n, fn)
    local raw;
    Print("  ", case_label, ": ");
    raw := IO_CallWithTimeout(rec(seconds := 30), fn);
    if Length(raw) >= 2 and raw[1] = true then
        Print("|N|=", raw[2][1], "  ", raw[2][2], " ms\n");
    else
        Print("TIMEOUT(>30s)\n");
    fi;
end;

for case in cases do
    Print("\n=== ", case.label, " ===\n");
    mixer := _ReproduceMixer(case.spec, case.sample);
    H := mixer.group;
    n := LargestMovedPoint(H);
    Print("|H|=", Size(H), " n=", n, " orbits=",
          SortedList(List(Orbits(H, [1..n]), Length)),
          " GAP_|N|=", Size(Normalizer(SymmetricGroup(n), H)), "\n");

    _H := H; _n := n;
    _time_refiner("Simple        ", n, function() local t,sz;
        t := NanosecondsSinceEpoch();
        sz := Size(VoleFind.Group(SymmetricGroup(_n),
                   GB_Con.NormaliserSimple(_H)));
        return [sz, Int((NanosecondsSinceEpoch()-t)/1000000)]; end);
    _time_refiner("Orbital       ", n, function() local t,sz;
        t := NanosecondsSinceEpoch();
        sz := Size(VoleFind.Group(SymmetricGroup(_n),
                   GB_Con.NormaliserOrbital(_H)));
        return [sz, Int((NanosecondsSinceEpoch()-t)/1000000)]; end);
    _time_refiner("OrbitalRegOrbit", n, function() local t,sz;
        t := NanosecondsSinceEpoch();
        sz := Size(VoleFind.Group(SymmetricGroup(_n),
                   GB_Con.NormaliserOrbitalRegOrbit(_H)));
        return [sz, Int((NanosecondsSinceEpoch()-t)/1000000)]; end);
    _time_refiner("OrbRegOrbChar (default)", n, function() local t,sz;
        t := NanosecondsSinceEpoch();
        sz := Size(VoleFind.Group(SymmetricGroup(_n),
                   GB_Con.NormaliserOrbitalRegOrbitChar(_H)));
        return [sz, Int((NanosecondsSinceEpoch()-t)/1000000)]; end);
    _time_refiner("plain Constraint.Normalise", n, function() local t,sz;
        t := NanosecondsSinceEpoch();
        sz := Size(VoleFind.Group(SymmetricGroup(_n),
                   Constraint.Normalise(_H)));
        return [sz, Int((NanosecondsSinceEpoch()-t)/1000000)]; end);
od;

QUIT;
