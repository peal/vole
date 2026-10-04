# Assisted-by: OpenAI Codex (GPT-6), regular/coset-action correctness sweep.
if not IsBoundGlobal("BankCheckVariants") then Read("tst/bank/variants.g"); fi;

RunBank_regular_orbits := function(mode)
    local cap, order, k, A, reg, quotient, gens, H, n, specs, spec,
          rs, s, savedShortcut, variants;
    if mode = "quick" then cap := 8;
    elif mode = "nightly" then cap := 16;
    elif mode = "full" then cap := 32;
    else Error("Unknown bank mode: ", mode); fi;
    variants := ["OrbitalRegOrbit", "OrbitalRegOrbitChar",
        "OrbitalRegOrbitCross", "OrbitalRegOrbitCrossNoPropose"];
    rs := RandomSource(IsMersenneTwister, 20261004);
    savedShortcut := _Vole.RootAutShortcut;
    _Vole.RootAutShortcut := false;
    BankResetStats();
    for order in [2 .. cap] do
        for k in [1 .. NrSmallGroups(order)] do
            A := SmallGroup(order, k);
            reg := RegularActionHomomorphism(A);
            gens := List(GeneratorsOfGroup(A), g ->
                Image(reg, g) * BankShiftPerm(Image(reg, g), order));
            specs := [[2 * order, Group(gens), "two-regular"]];
            if not IsTrivial(DerivedSubgroup(A)) then
                quotient := ActionHomomorphism(A,
                    RightCosets(A, DerivedSubgroup(A)), OnRight);
                gens := List(GeneratorsOfGroup(A), g ->
                    Image(reg, g) * BankShiftPerm(Image(quotient, g), order));
                n := order + Index(A, DerivedSubgroup(A));
                Add(specs, [n, Group(gens), "regular-plus-quotient"]);
            fi;
            for spec in specs do
                n := spec[1];
                H := spec[2];
                for s in [(), Random(rs, SymmetricGroup(n))] do
                    BankCheckVariants(n, H ^ s, StringFormatted(
                        "SmallGroup({},{})/{}", order, k, spec[3]), variants);
                od;
            od;
        od;
    od;
    _Vole.RootAutShortcut := savedShortcut;
    BankReportStats("regular_orbits");
    return _BankStats.fail = 0;
end;
