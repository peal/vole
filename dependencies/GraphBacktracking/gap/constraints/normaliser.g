
GB_Con.NormaliserSimple := function(group)
    local orbList,getOrbits, orbMap, pointMap, r, invperm,minperm;

    getOrbits := function(pointlist, n)
        local G,orbs,graph,cols, orb;
        Info(InfoGB, 1, "Normaliser for pointlist", pointlist);
        G := Stabilizer(group, pointlist, OnTuples);

        orbs := Orbits(G, [1..n]);
        
        orbs := Filtered(orbs, o -> Length(o)>1);
        
        if Length(orbs) = 0 then
            return [];
        fi;

        if Length(orbs) = 1 then
            orb := Immutable(Set(orbs[1]));
            return [{x} -> x in orb];
        fi;

        graph := ListWithIdenticalEntries(n, []);
        cols := ListWithIdenticalEntries(n, 0);
        Append(graph, orbs);
        Append(cols, List(orbs, {x} -> Length(x)));
        Info(InfoGB, 2, "Made graph: ", Digraph(graph));
        return [rec( graph := Digraph(graph), vertlabels := cols)];
    end;

    r := rec(
        name := "NormaliserSimple",
        largest_required_point := LargestMovedPoint(group),
        constraint := Constraint.Stabilise(group, OnPoints),
        refine := rec(
            initialise := function(ps, buildingRBase)
                # Set 'seenDepth to -1 at the start. Note we always start searching at 'seenDepth + 1' which will be 0
                r!.btdata := rec(seenDepth := -1);
                return r!.refine.fixed(ps, buildingRBase);
            end,
            fixed := function(ps, buildingRBase)
                local fixedpoints, result;
                fixedpoints := PS_FixedPoints(ps);
                Assert(2, r!.btdata.seenDepth <= Length(fixedpoints));
                result := Concatenation(List([r!.btdata.seenDepth + 1..Length(fixedpoints)], x -> getOrbits(fixedpoints{[1..x]}, PS_Points(ps))));
                r!.btdata.seenDepth := Length(fixedpoints);
                return result;
            end)
        );
        return Objectify(GBRefinerType, r);
    end;

# A refiner based on Leon's Normaliser refiner (with added block structures)
GB_Con.GroupConjugacySimple2 := function(groupL, groupR)
    local orbList,getOrbits, buildGraph, orbMap, pointMap, r, invperm,minperm;

    buildGraph := function(G, n, outlist)
        local orbs, graph, cols, blocks, b, parts, curlength;

        orbs := Orbits(G, [1..n]);        
        orbs := Filtered(orbs, o -> Length(o)>1);

        if Length(orbs) = 1 then
            blocks := RepresentativesMinimalBlocks(G, orbs[1]);
            Info(InfoGB, 2, "Found blocks: ", blocks);
            graph := ListWithIdenticalEntries(n, []);
            for b in blocks do
                parts := Orbit(G, Set(b), OnSets);
                if Length(parts) > 1 then
                    curlength := Length(graph);
                    Append(graph, parts);
                    Add(graph, [curlength+1..curlength+Length(parts)]);
                fi;
            od;
            Info(InfoGB, 2, "Made block system graph: ", graph);
            Add(outlist, rec(graph := Digraph(graph)));
        else
            graph := ListWithIdenticalEntries(n, []);
            cols := ListWithIdenticalEntries(n, 0);
            Append(graph, orbs);
            Append(cols, List(orbs, {x} -> Length(x)));
            Info(InfoGB, 2, "Made graph: ", graph);
            Add(outlist, rec( graph := Digraph(graph), vertlabels := cols));
        fi;
    end;

    getOrbits := function(pointlist, n, group)
        local G,orbs,graph,cols, i, outlist;
        G := group;
        # Stop if the list is empty
        if IsEmpty(pointlist) then
            return [];
        fi;
        pointlist := Reversed(pointlist);
        # if the first point isn't moved, then we would just be repeating earlier work
        if ForAll(GeneratorsOfGroup(G), p -> pointlist[1]^p = pointlist[1]) then
            return [];
        fi;

        outlist := [];
        for i in pointlist do
            if ForAny(GeneratorsOfGroup(G), p -> i^p <> i) then
                G := Stabilizer(G, i);
                buildGraph(G, n, outlist);
            fi;
        od;
        return outlist;
    end;

    r := rec(
        name := "NormaliserSimpleLeon",
        largest_required_point := Maximum(LargestMovedPoint(groupL),LargestMovedPoint(groupR)),
        constraint := Constraint.Transport(groupL, groupR, OnPoints),
        refine := rec(
            initialise := function(ps, buildingRBase)
                # Set 'seenDepth to -1 at the start. Note we always start searching at 'seenDepth + 1' which will be 0
                r!.btdata := rec(seenDepth := -1);
                return r!.refine.fixed(ps, buildingRBase);
            end,
            fixed := function(ps, buildingRBase)
                local fixedpoints, result, group;
                if buildingRBase then
                    group := groupL;
                else
                    group := groupR;
                fi;
                fixedpoints := PS_FixedPoints(ps);
                Assert(2, r!.btdata.seenDepth <= Length(fixedpoints));
                result := Concatenation(List([r!.btdata.seenDepth + 1..Length(fixedpoints)], x -> getOrbits(fixedpoints{[1..x]}, PS_Points(ps), group)));
                
                # Handle first call
                if r!.btdata.seenDepth = -1 then
                    buildGraph(group, PS_Points(ps), result);
                fi;

                r!.btdata.seenDepth := Length(fixedpoints);
                return result;
            end)
        );
        return Objectify(GBRefinerType, r);
    end;

GB_Con.NormaliserSimple2 := {g} -> GB_Con.GroupConjugacySimple2(g,g);


# Phase A — orbital-graph refiner family using the set-of-graphs widget.
#
# Pushing individual orbital graphs as fixed digraphs would compute the
# 2-closure of E (the stabiliser of every orbital graph individually),
# not the normaliser. N(E) only preserves the SET of orbital graphs.
#
# Solution: build a single digraph encoding the set, with auxiliary
# vertices that the normaliser can permute among themselves. See
# _BTKit.buildSetOfGraphsWidget for the construction. Orbital graphs are
# partitioned by equivalence class (currently: valence); within a class
# they may be mutually permuted, across classes they are individually
# preserved. Singleton classes are pushed as plain digraphs (no widget).
#
# The family of refiners (controlled by the `strategy` argument):
#
#   strategy.orbitals = "always"  push orbital graphs at every stab-chain
#                                 step (the default — strongest pruning)
#                     = "root"    push orbital graphs only at the root
#                                 (cheap at deeper levels; matches the
#                                 spirit of GAP's stbcbckt.gi when only
#                                 one round is desired)
#                     = "never"   never push orbital graphs (equivalent
#                                 to GroupConjugacySimple2 — provided as
#                                 a baseline for empirical comparison)
#
#   strategy.blocks   = "root"    push minimal block systems only at the
#                                 root (the default — matches GAP)
#                     = "always"  push minimal block systems at every
#                                 step (experimental — Stab(E, fixed)
#                                 may have block systems E doesn't)
#                     = "never"   skip block-system pushes
#
# Named entry points wrap _MakeGroupConjugacyOrbital with the canonical
# strategies:
#   GroupConjugacyOrbital       — orbitals="always", blocks="root"
#   GroupConjugacyOrbitalRoot   — orbitals="root",   blocks="root"
#   GroupConjugacyOrbitalNone   — orbitals="never",  blocks="root"
#                                 (equivalent to Simple2 but routed through
#                                 the same widget framework, useful for
#                                 controlled benchmarking)
#
_BTKit.makeNormaliserOrbitalRecords := function(group, points, n, isRoot, strategy)
    # `group` is the base group (E for normaliser; the same on both
    # sides). `points` is the fixed-points prefix (covariant — different
    # on left and right). The actual stabiliser we work with is
    # Stab(group, points, OnTuples) but we never compute it directly;
    # everything flows through the stabtree cache so output orderings
    # are covariant on both sides of the search.
    #
    # Covariance: R(S)^g = R(S^g). For g taking left-fixedpoints to
    # right-fixedpoints, the orbital graphs / orbits / etc returned
    # here must be related by g. StabTreeStabilizerOrbits and
    # StabTreeStabilizerOrbitalGraphs guarantee that by storing
    # canonical-form results and conjugating to the current
    # representation. (See Chris's note on R(S)^g = R(S^g).)
    local out, orbs, graph, cols, blockSystems, ogList, families, key, fam,
          pushOrbitals, pushBlocks, ogOptions, sortedKeys, stabSize;
    out := [];

    # (1) Orbit-length-coloured partition. Always invariant under N(G);
    # always pushed (no strategy knob).
    orbs := StabTreeStabilizerOrbits(group, points, [1 .. n]);
    orbs := Filtered(orbs, o -> Length(o) > 1);
    if Length(orbs) > 0 then
        graph := ListWithIdenticalEntries(n, []);
        cols := ListWithIdenticalEntries(n, 0);
        Append(graph, orbs);
        Append(cols, List(orbs, o -> Length(o)));
        Add(out, rec(graph := Digraph(graph), vertlabels := cols));
    fi;

    # (2) Block-system widgets via stabtree (covariant at any depth).
    # Iterates over all transitive orbits internally; works on
    # intransitive Stab(E, points) by computing blocks per orbit.
    pushBlocks := (strategy.blocks = "always")
                  or (strategy.blocks = "root" and isRoot);
    if pushBlocks then
        blockSystems := StabTreeStabilizerBlockSystemGraphs(
            group, points, rec(maxval := n));
        if not IsEmpty(blockSystems) then
            families := _BTKit.partitionByKey(blockSystems, bs -> bs.key);
            # Iterate keys in sorted order so left and right traverse
            # families in the same order — required for trace consistency.
            for key in SortedList(RecNames(families)) do
                fam := List(families.(key), bs -> bs.graph);
                Append(out, _BTKit.buildSetOfGraphsWidget(fam, n));
            od;
        fi;
    fi;

    # (3) Orbital graphs grouped by canonical-form equivalence.
    #
    # IMPORTANT: skipOneLarge MUST be false. Group intersection (the
    # InGroup refiner) can safely drop one maximal orbital because the
    # remaining orbitals plus the diagonal determine it. The normaliser
    # case is different — dropping any one orbital costs us a
    # constraint not recoverable from the others.
    pushOrbitals := (strategy.orbitals = "always")
                    or (strategy.orbitals = "root" and isRoot);
    if pushOrbitals then
        ogOptions := rec(maxval := n, skipOneLarge := false);
        # Optional size-cutoff on orbital arcs. `strategy.cutoff` is
        # either `false` (no cutoff — include every orbital) or a
        # positive integer (skip orbitals with more than that many
        # arcs). See Theißen §3.5 for the broader selection problem.
        if IsBound(strategy.cutoff) and strategy.cutoff <> false then
            ogOptions.cutoff := strategy.cutoff;
        fi;
        ogList := StabTreeStabilizerOrbitalGraphs(group, points, ogOptions);
        if not IsEmpty(ogList) then
            families := _BTKit.partitionByKey(ogList,
                og -> _BTKit.orbitalEquivalenceKey(og));
            for key in SortedList(RecNames(families)) do
                Append(out,
                    _BTKit.buildSetOfGraphsWidget(families.(key), n));
            od;
        fi;
    fi;

    return out;
end;

# Underlying constructor. `strategy` is a record with fields
# `orbitals` ∈ {"always", "root", "never"} and
# `blocks`   ∈ {"always", "root", "never"}. See module-level comment.
_MakeGroupConjugacyOrbital := function(groupL, groupR, strategy, name)
    local r;
    r := rec(
        name := name,
        largest_required_point :=
            Maximum(LargestMovedPoint(groupL), LargestMovedPoint(groupR)),
        constraint := Constraint.Transport(groupL, groupR, OnPoints),
        refine := rec(
            initialise := function(ps, buildingRBase)
                r!.btdata := rec(seenDepth := -1);
                return r!.refine.fixed(ps, buildingRBase);
            end,
            fixed := function(ps, buildingRBase)
                local fixedpoints, result, group, n, i;
                if buildingRBase then
                    group := groupL;
                else
                    group := groupR;
                fi;
                fixedpoints := PS_FixedPoints(ps);
                n := PS_Points(ps);
                Assert(2, r!.btdata.seenDepth <= Length(fixedpoints));
                result := [];

                # Root push: stabilise no points (i.e. group itself).
                if r!.btdata.seenDepth = -1 then
                    Append(result,
                        _BTKit.makeNormaliserOrbitalRecords(
                            group, [], n, true, strategy));
                fi;

                # One push per newly-fixed point. We never compute
                # `Stabilizer(group, ...)` directly — the helper drives
                # stabtree for covariance.
                for i in [Maximum(r!.btdata.seenDepth + 1, 1)
                         .. Length(fixedpoints)] do
                    Append(result,
                        _BTKit.makeNormaliserOrbitalRecords(
                            group, fixedpoints{[1 .. i]}, n,
                            false, strategy));
                od;

                r!.btdata.seenDepth := Length(fixedpoints);
                return result;
            end)
    );
    return Objectify(GBRefinerType, r);
end;

# Named entry points. Strategy choices documented above.
GB_Con.GroupConjugacyOrbital := function(groupL, groupR)
    return _MakeGroupConjugacyOrbital(groupL, groupR,
        rec(orbitals := "always", blocks := "root"),
        "GroupConjugacyOrbital");
end;
GB_Con.GroupConjugacyOrbitalRoot := function(groupL, groupR)
    return _MakeGroupConjugacyOrbital(groupL, groupR,
        rec(orbitals := "root", blocks := "root"),
        "GroupConjugacyOrbitalRoot");
end;
GB_Con.GroupConjugacyOrbitalNone := function(groupL, groupR)
    return _MakeGroupConjugacyOrbital(groupL, groupR,
        rec(orbitals := "never", blocks := "root"),
        "GroupConjugacyOrbitalNone");
end;
GB_Con.GroupConjugacyOrbitalDeep := function(groupL, groupR)
    return _MakeGroupConjugacyOrbital(groupL, groupR,
        rec(orbitals := "always", blocks := "always"),
        "GroupConjugacyOrbitalDeep");
end;

# OrbitalSmall: only push orbital graphs with at most O(n log n) arcs.
# For transitive G every orbital has n*a arcs (a = valence), so this
# is equivalent to "keep valence ≤ 2*⌈log₂ n⌉". Theißen §3.5
# (selection of refinements) plus the observation that orbital graphs
# of complementary valence often encode the same row-structure
# constraint, so prefer the small ones. getOrbitalListWithOptions
# already drops the valence-(n-1) "removed-one-point" case via its
# own filter; this cutoff additionally drops intermediate-valence
# heavies. Cache automatically separates this cutoff from the
# uncapped variant — _BTKit.orbitalOptions includes `cutoff` in the
# options record used as a HashMap key for `reducedOrbitals`.
GB_Con.GroupConjugacyOrbitalSmall := function(groupL, groupR)
    local n, logn;
    n := Maximum(LargestMovedPoint(groupL), LargestMovedPoint(groupR), 2);
    # ⌈log₂ n⌉ for n ≥ 2.
    logn := LogInt(n - 1, 2) + 1;
    return _MakeGroupConjugacyOrbital(groupL, groupR,
        rec(orbitals := "always", blocks := "root",
            cutoff := 2 * n * logn),
        "GroupConjugacyOrbitalSmall");
end;

GB_Con.NormaliserOrbital      := {g} -> GB_Con.GroupConjugacyOrbital(g, g);
GB_Con.NormaliserOrbitalRoot  := {g} -> GB_Con.GroupConjugacyOrbitalRoot(g, g);
GB_Con.NormaliserOrbitalNone  := {g} -> GB_Con.GroupConjugacyOrbitalNone(g, g);
GB_Con.NormaliserOrbitalDeep  := {g} -> GB_Con.GroupConjugacyOrbitalDeep(g, g);
GB_Con.NormaliserOrbitalSmall := {g} -> GB_Con.GroupConjugacyOrbitalSmall(g, g);
