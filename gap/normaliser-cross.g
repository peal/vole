# Vole: experimental regular-orbit cross-propagation normaliser refiners.
#
# These refiners are NOT part of GraphBacktracking. They sit on top of the
# regular-orbit machinery in
# GraphBacktracking's gap/constraints/normaliser.g (the GroupConjugacyOrbital
# family and _MakeGroupConjugacyOrbital), extending it via the documented
# `extraRegOrbitDeduction` strategy hook. They live here, in Vole, because
# the cross-propagation is still research-grade: it has not been validated
# across the input space the way the GraphBacktracking refiners have, and it
# is not selected by the canonical-image dispatch.
#
# Both _MakeGroupConjugacyOrbital and the GB_Con / _BTKit namespaces are
# provided by GraphBacktracking (the real package or Vole's bundled copy),
# which is always loaded before this file.

# RegularOrbit3 cross-propagation (Theißen §3.7.2).
#
# The fixed regular points determine corresponding generators of K ≤ E.
# For each fixed anchor y, ordered BFS labels on yK correspond too.
# Using E's original generators, an orbit minimum, or numerical orbit
# offsets does not preserve this correspondence.
#
# Arguments as for makeNormaliserRegOrbitDeduction.  `phaseC_D` is the
# BFS-orbit record from the Phase C deduction (the set D above); if
# empty, no cross-propagation is possible.
_BTKit.makeNormaliserRegOrbitCrossDeduction :=
    function(group, points, ps, n, phaseC_D)
    local gens, regOrbit, b1, positions, covered, y, bfs;

    if IsEmpty(phaseC_D.orbit) then
        return [];
    fi;

    if IsBound(phaseC_D.generators) then
        gens := phaseC_D.generators;
    else
        # Compatible with external GraphBacktracking's older hook record.
        b1 := phaseC_D.orbit[1];
        regOrbit := Orbit(group, b1);
        gens := List(Filtered(points, p -> p in regOrbit),
            p -> RepresentativeAction(group, b1, p));
    fi;
    if IsEmpty(gens) then return []; fi;

    positions := [];
    covered := Set(phaseC_D.orbit);
    for y in points do
        if y in covered then continue; fi;
        bfs := _BTKit.bfsOrbit(y, gens);
        UniteSet(covered, bfs.orbit);
        if Length(bfs.orbit) > 1 then Add(positions, bfs.position); fi;
    od;
    if IsEmpty(positions) then return []; fi;
    # A tuple retains the fixed-anchor order without numerical orbit IDs.
    return [function(p)
        return List(positions, function(pos)
            if p in pos then return pos[p]; fi;
            return 0;
        end);
    end];
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
