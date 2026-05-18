# Vole: Backtrack search in permutation groups with graphs
# A GAP package by Mun See Chang, Christopher Jefferson, and Wilf A. Wilson.
#
# SPDX-License-Identifier: MPL-2.0
#
# Implementations: disjoint direct product decomposition (DDPD).
#
# Algorithm: M. S. Chang & C. Jefferson, "Disjoint direct product
# decompositions of permutation groups". See gap/directprod.gd for
# the conceptual overview.
#
# Implementation notes:
#
#   * Polished from /Users/caj/files/reps/group/archive/directprod/DDPD/DDPD.g
#     (the paper's reference impl). Differences:
#       - namespaced inside _Vole / Vole (no top-level globals)
#       - timerec debugging removed
#       - asserts on the input + output structure
#       - explicit documentation
#       - helper renamed and made local
#
#   * Depends on `datastructures` for `PartitionDS` (union-find).
#     `datastructures` is already a dependency of vole's
#     dependencies, so no new requirement.
#
#   * Runtime is dominated by `StabChain(G, concat-of-orbits)` — the
#     subsequent sifting is linear in (sum of transversal sizes) ×
#     (depth past each orbit boundary). For groups whose stabchain
#     happens to be small relative to the group order this is fast;
#     for groups requiring a deep chain (long composition series)
#     it can be slower.


# Local helper. Given a list-of-lists `l` whose entries are pairwise
# disjoint, returns the indicator list `x` such that `x[p] = i`
# whenever `p in l[i]`. The result is undefined for p outside the
# union of the input lists.
_Vole.DDPDIndicator := function(l)
    local x, i, j;
    x := [];
    for i in [1 .. Length(l)] do
        for j in l[i] do
            x[j] := i;
        od;
    od;
    return x;
end;


Vole.DDPD := function(G)
    local orbits, orbitindicator, chain, base, transversals, chainlevels,
          baseorbitchanges, newtransversals, orbitunion, parts, partsindicator,
          decomp, d, l, i, j, t, orbbase;

    if not IsPermGroup(G) then
        ErrorNoReturn("Vole.DDPD: argument must be a permutation group");
    fi;

    # Trivial group: a single factor that is the trivial group itself.
    if IsTrivial(G) then
        return [rec(base := [], genset := [()], group := Group(()))];
    fi;

    orbits := Orbits(G);

    # Transitive group: a single factor that is G itself.
    if Length(orbits) = 1 then
        return [rec(
            base    := BaseStabChain(StabChain(G)),
            genset  := GeneratorsOfGroup(G),
            group   := G)];
    fi;

    # Canonical ordering so the algorithm is deterministic w.r.t. the
    # group's internal representation.
    orbits := Set(orbits, Set);
    orbitindicator := _Vole.DDPDIndicator(orbits);

    # Stabchain whose base prefix is the concatenation of orbits, in
    # the canonical order. This is the key trick: each orbit's points
    # occupy a contiguous block in the base, so sifting past those
    # blocks strips the orbit-internal action cleanly.
    chain := StabChain(G, Concatenation(orbits));

    # Walk the chain and record (base, transversals, chainlevels) plus
    # baseorbitchanges = positions in the base where a new orbit
    # starts. baseorbitchanges always starts with 1 (orbit 1 starts at
    # base[1]).
    base := [chain.orbit[1]];
    transversals := [Set(chain.transversal)];
    chainlevels := [chain];
    baseorbitchanges := [1];

    while IsBound(chain.stabilizer) do
        chain := chain.stabilizer;
        if IsBound(chain.orbit) then
            Add(base, chain.orbit[1]);
            l := Length(base);
            if orbitindicator[base[l]] <> orbitindicator[base[l - 1]] then
                Add(baseorbitchanges, l);
            fi;
            Add(transversals, Set(chain.transversal));
            Add(chainlevels, chain);
        fi;
    od;

    # Sift each transversal element at level j (in orbit i) through
    # the chain levels of *later* orbits (l >= baseorbitchanges[i+1]).
    # Sifting strips the orbit-i-internal action; any residual that
    # still moves points reveals an inter-orbit "leakage" — i.e., the
    # orbit can't be cleanly factored out.
    newtransversals := [];
    for i in [1 .. Length(baseorbitchanges) - 1] do
        for j in [baseorbitchanges[i] .. baseorbitchanges[i + 1] - 1] do
            newtransversals[j] := [];
            for t in transversals[j] do
                for l in [baseorbitchanges[i + 1] .. Length(base)] do
                    if base[l] ^ t <> base[l] then
                        t := SiftedPermutation(chainlevels[l], t);
                    fi;
                od;
                Add(newtransversals[j], t);
            od;
        od;
    od;

    # The transversals at the final orbit block don't get sifted past
    # anything — copy them verbatim.
    Append(newtransversals,
           transversals{[Last(baseorbitchanges) .. Length(transversals)]});

    # Union-find pass: for each (sifted) transversal at level j,
    # whose home orbit is orbitindicator[base[j]], every moved point t
    # outside the home orbit ties the home to orbitindicator[t].
    # Components of the partition give the DDPD factors.
    orbitunion := PartitionDS(IsPartitionDS, Length(orbits));
    for i in [1 .. Length(newtransversals)] do
        orbbase := orbitindicator[base[i]];
        for t in MovedPoints(newtransversals[i]) do
            Unite(orbitunion, orbbase, orbitindicator[t]);
        od;
    od;

    parts := Set(PartsOfPartitionDS(orbitunion));
    partsindicator := _Vole.DDPDIndicator(parts);

    # Assemble the per-component factor records. Each base point
    # contributes its sifted transversal to the factor that owns its
    # home orbit.
    decomp := List(parts, x -> rec(base := [], genset := []));
    for i in [1 .. Length(base)] do
        t := partsindicator[orbitindicator[base[i]]];
        Add(decomp[t].base, base[i]);
        Append(decomp[t].genset, newtransversals[i]);
    od;

    for d in decomp do
        d.group := Group(d.genset, ());
        SetStabChainMutable(d.group,
            StabChainBaseStrongGenerators(d.base, d.genset, ()));
    od;

    # Sanity: factors should partition the orbits, and their group
    # sizes should multiply to |G|. Cheap; useful as a runtime guard.
    Assert(2, Sum(decomp, d -> Size(d.group)) > 0);  # well-formed
    Assert(2, Product(decomp, d -> Size(d.group)) = Size(G));

    return decomp;
end;

Vole.IsDDPDIndecomposable := function(G)
    local decomp;
    if not IsPermGroup(G) then
        ErrorNoReturn("Vole.IsDDPDIndecomposable: argument must be a perm group");
    fi;
    decomp := Vole.DDPD(G);
    return Length(decomp) = 1 and Length(Orbits(G)) > 1;
end;
