# Assisted-by: OpenAI Codex (GPT-6), bug investigation and regression tests.
#@local cases, variants, savedShortcut, check, deductions, covariant, transport, proposals, savedData
gap> START_TEST("normaliser-regorbit.tst");
gap> LoadPackage("vole", false);
true
gap> cases := [
>     [6, Group((1,2,3)(4,5,6))],
>     [12, Group((1,2,3,4,5,6)(7,8)(9,10)(11,12))],
>     [8, Group((1,2,3,4)(5,6,7,8), (2,4)(6,8))],
>     [6, Image(RegularActionHomomorphism(SymmetricGroup(3)))]
> ];;
gap> variants := ["Orbital", "OrbitalRegOrbit", "OrbitalRegOrbitChar",
>     "OrbitalRegOrbitCross", "OrbitalRegOrbitCrossNoPropose"];;

# Check exact equality with the shortcut disabled as well as enabled.
# Conjugation mixes the orbit supports; redundant generators change the
# presentation without changing the subgroup.
gap> savedShortcut := _Vole.RootAutShortcut;;
gap> check := function()
>     local spec, H, G, expected, result, v, shortcut, s, gens;
>     for spec in cases do
>         for s in [(), (1,2,3,4,5)] do
>             H := spec[2] ^ s;
>             gens := GeneratorsOfGroup(H);
>             H := Group(Concatenation(Reversed(gens), [Product(gens)]));
>             for G in [SymmetricGroup(spec[1]), AlternatingGroup(spec[1])] do
>                 expected := Intersection(Normalizer(SymmetricGroup(spec[1]), H), G);
>                 for shortcut in [false, true] do
>                     _Vole.RootAutShortcut := shortcut;
>                     for v in variants do
>                         result := Vole.Normalizer(G, H : refiner := v);
>                         if result <> expected then
>                             Print("FAIL: n=", spec[1], " variant=", v,
>                                 " shortcut=", shortcut, " ambient_order=", Size(G),
>                                 " H=", H, " returned=", GeneratorsOfGroup(result), "\n");
>                             return false;
>                         fi;
>                     od;
>                 od;
>             od;
>         od;
>     od;
>     return true;
> end;;
gap> check();
true
gap> _Vole.RootAutShortcut := savedShortcut;;

# Check the deduction itself, independently of search pruning and shortcut
# generators. A valid transporter must preserve every emitted point label.
gap> deductions := function(H, points, n)
>     local ops;
>     ops := _BTKit.makeNormaliserRegOrbitDeduction(H, points, fail, n, false);
>     if ops[2] <> false then
>         Append(ops[1], _BTKit.makeNormaliserRegOrbitCrossDeduction(
>             H, points, fail, n, ops[2]));
>     fi;
>     return ops[1];
> end;;
gap> covariant := function(H, points, n, perms)
>     local left, right, s, i, p;
>     left := deductions(H, points, n);
>     for s in perms do
>         right := deductions(H ^ s, OnTuples(points, s), n);
>         if Length(left) <> Length(right) then return false; fi;
>         for i in [1 .. Length(left)] do
>             for p in [1 .. n] do
>                 if left[i](p) <> right[i](p ^ s) then return false; fi;
>             od;
>         od;
>     od;
>     return true;
> end;;
gap> covariant(cases[1][2], [1,2,4], 6,
>     Concatenation(AsList(Normalizer(SymmetricGroup(6), cases[1][2])),
>         [(1,2,4,5,3)]));
true
gap> covariant(cases[2][2], [2,3,8,10,12], 12,
>     Concatenation(GeneratorsOfGroup(Normalizer(SymmetricGroup(12), cases[2][2])),
>         [(1,8,4,11,7)]));
true
gap> covariant(cases[4][2], [2,3,5], 6,
>     Concatenation(GeneratorsOfGroup(Normalizer(SymmetricGroup(6), cases[4][2])),
>         [(2,3,4)]));
true

# Transporter searches have distinct left/right groups and can send the
# first regular orbit to another one. Characteristic selection is currently
# normaliser-only and is deliberately excluded here.
gap> transport := function()
>     local spec, H, K, G, s, v, p, ref;
>     _Vole.RootAutShortcut := false;
>     for spec in cases do
>         H := spec[2];
>         G := SymmetricGroup(spec[1]);
>         s := (1,2,3,4,5);
>         K := H ^ s;
>         for v in ["OrbitalRegOrbit", "OrbitalRegOrbitCross",
>             "OrbitalRegOrbitCrossNoPropose"] do
>             ref := GB_Con.(Concatenation("GroupConjugacy", v))(H, K);
>             p := VoleFind.Representative(G, ref);
>             if p = fail or not p in G or H ^ p <> K then return false; fi;
>         od;
>     od;
>     return VoleFind.Representative(SymmetricGroup(6),
>         GB_Con.GroupConjugacyOrbitalRegOrbitCross(
>             Group((1,2,3)(4,5,6)), Group((1,2,3)))) = fail;
> end;;
gap> transport();
true
gap> _Vole.RootAutShortcut := savedShortcut;;

# The former proposal bug also affected a proper characteristic subgroup
# (TransitiveGroup(8,33)). Check its opt-in proposals and every selector on
# the regular-S3 witness inside a proper ambient group.
gap> proposals := function()
>     local H, F, ref, G, v, selector, result;
>     _Vole.RootAutShortcut := false;
>     H := TransitiveGroup(8,33);
>     F := _BTKit.findRegularCharacteristicSubgroup(H, 1000);
>     if F = fail then return false; fi;
>     ref := _MakeGroupConjugacyOrbital(H, H, rec(orbitals := "always",
>         blocks := "root", regOrbit := "always", regOrbitGroup := F,
>         regOrbitPropose := true), "CharacteristicProposalRegression");
>     if VoleFind.Group(SymmetricGroup(8), ref)
>         <> Normalizer(SymmetricGroup(8), H) then return false; fi;
>     H := cases[4][2];
>     G := AlternatingGroup(6);
>     for selector in ["smallest", "largest", "first", "most-connected",
>         "most-connected-smallest", "most-connected-largest",
>         "smallest-most-connected"] do
>         for v in variants do
>             result := Vole.Normalizer(G, H : refiner := v, selector := selector);
>             if result <> Intersection(Normalizer(SymmetricGroup(6), H), G)
>                 then return false; fi;
>         od;
>     od;
>     return true;
> end;;
gap> proposals();
true
gap> _Vole.RootAutShortcut := savedShortcut;;

# External BacktrackKit 1.2.0 has a one-argument, first-orbit-only cache.
# Mixed dependency upgrades must still preserve interchangeable orbits.
gap> savedData := StabTreeRegularOrbitData;;
gap> StabTreeRegularOrbitData := function(group)
>     local data;
>     data := savedData(group);
>     if data = fail then return fail; fi;
>     data := ShallowCopy(data);
>     Unbind(data.regularPoints);
>     return data;
> end;;
gap> check();
true
gap> StabTreeRegularOrbitData := savedData;;
gap> _Vole.RootAutShortcut := savedShortcut;;
gap> STOP_TEST("normaliser-regorbit.tst");
