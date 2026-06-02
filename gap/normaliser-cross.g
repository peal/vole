# Vole: experimental regular-orbit cross-propagation normaliser refiners.
#
# These refiners are NOT part of GraphBacktracking. They sit on top of the
# polished regular-orbit machinery in
# GraphBacktracking's gap/constraints/normaliser.g (the GroupConjugacyOrbital
# family and _MakeGroupConjugacyOrbital), extending it via the documented
# `extraRegOrbitDeduction` strategy hook. They live here, in Vole, because
# the cross-propagation is still research-grade: it has not been validated
# across the input space the way the GraphBacktracking refiners have, and it
# inherits the same canonical-unsafety as the underlying RegOrbit variant.
#
# Both _MakeGroupConjugacyOrbital and the GB_Con / _BTKit namespaces are
# provided by GraphBacktracking (the real package or Vole's bundled copy),
# which is always loaded before this file.

# RegularOrbit3 cross-propagation (Theißen §3.7.2).
#
# Once the regular-orbit deduction (Phase C) has isolated a subset D of
# the regular orbit, the images of points in OTHER orbits can sometimes
# be deduced.  For a fixed point y (whose g-image is known) and any
# yh in yE, if bh = ω₁^(h⁻¹) is in D, then yh^g = y^g · h^g is also
# known, because h^g is determined by the regular-orbit map on bh.
#
# This function emits label functions that isolate such yh, extending
# the regular-orbit deduction across E-orbits.  It is the Vole
# equivalent of GAP's Refinements.RegularOrbit3 (stbcbckt.gi:1867).
#
# Arguments as for makeNormaliserRegOrbitDeduction.  `phaseC_D` is the
# BFS-orbit record from the Phase C deduction (the set D above); if
# empty, no cross-propagation is possible.
_BTKit.makeNormaliserRegOrbitCrossDeduction :=
    function(group, points, ps, n, phaseC_D)
    local data, D_set, E_orbits, processed_orbits, out, bfs_y, labelMap,
          omega1, genE, orbMin, orb, p, h, bh, orbitOffset;

    if IsEmpty(phaseC_D.orbit) then
        return [];
    fi;

    data := StabTreeRegularOrbitData(group);
    if data = fail then
        return [];
    fi;

    omega1 := data.omega1;
    genE := GeneratorsOfGroup(group);
    D_set := Set(phaseC_D.orbit);

    # Collect E-orbits.  For efficiency we only process orbits that
    # contain at least one fixed point (anchored orbits).
    E_orbits := Orbits(group, [1 .. n]);

    out := [];
    processed_orbits := HashMap();
    labelMap := HashMap();
    orbitOffset := 0;

    for orb in E_orbits do
        if Length(orb) = 1 then continue; fi;
        if not ForAny(orb, p -> p in points) then continue; fi;

        # One BFS tree per anchored orbit, cached by orbit-minimum.
        orbMin := Minimum(orb);
        if orbMin in processed_orbits then
            bfs_y := processed_orbits[orbMin];
        else
            bfs_y := _BTKit.bfsOrbitWithTrace(orbMin, genE);
            processed_orbits[orbMin] := bfs_y;
        fi;

        for p in orb do
            h := bfs_y.treeElement[p];
            # bh = ω₁^(h⁻¹) — the regular-orbit preimage under h.
            bh := omega1 / h;
            if bh in D_set then
                labelMap[p] := orbitOffset + bfs_y.position[p];
            fi;
        od;

        orbitOffset := orbitOffset + Length(orb) + 1;
    od;

    if not IsEmpty(Keys(labelMap)) then
        Add(out, function(p)
            if p in labelMap then
                return labelMap[p];
            fi;
            return 0;
        end);
    fi;

    return out;
end;

# Phase C + RegularOrbit3 cross-propagation.
# Full Theißen §3.7.1-§3.7.2: regular-orbit branching proposal,
# forced-refinement labels for the Phase-C-deduced subset D of the
# regular orbit, and cross-orbit labels for every E-orbit anchored by
# a fixed point (once D is non-empty).  Inert when the group has no
# regular orbit.
GB_Con.GroupConjugacyOrbitalRegOrbitCross := function(groupL, groupR)
    return _MakeGroupConjugacyOrbital(groupL, groupR,
        rec(orbitals := "always", blocks := "root",
            regOrbit := "always",
            extraRegOrbitDeduction :=
                _BTKit.makeNormaliserRegOrbitCrossDeduction),
        "GroupConjugacyOrbitalRegOrbitCross");
end;

# Phase C + cross-propagation, without the regular-orbit branching
# proposal.  The Phase-C forced-refinement labels and the cross-orbit
# labels are still emitted; only the selector hint is suppressed.
# This isolates the effect of the cross-propagation labels from the
# proposal-driven base change.
GB_Con.GroupConjugacyOrbitalRegOrbitCrossNoPropose := function(groupL, groupR)
    return _MakeGroupConjugacyOrbital(groupL, groupR,
        rec(orbitals := "always", blocks := "root",
            regOrbit := "always",
            regOrbitPropose := false,
            extraRegOrbitDeduction :=
                _BTKit.makeNormaliserRegOrbitCrossDeduction),
        "GroupConjugacyOrbitalRegOrbitCrossNoPropose");
end;

GB_Con.NormaliserOrbitalRegOrbitCross    := {g} -> GB_Con.GroupConjugacyOrbitalRegOrbitCross(g, g);
GB_Con.NormaliserOrbitalRegOrbitCrossNoPropose := {g} -> GB_Con.GroupConjugacyOrbitalRegOrbitCrossNoPropose(g, g);
