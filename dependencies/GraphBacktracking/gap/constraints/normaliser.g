
# Global node counter for diagnostics.  Incremented once per refine.fixed
# call (left + right).  Read with _BTKit.NormaliserNodeCount().
_BTKit._NORMALISER_NODE_COUNT := 0;
_BTKit.NormaliserNodeCount := function()
    return _BTKit._NORMALISER_NODE_COUNT;
end;
_BTKit.ResetNormaliserNodeCount := function()
    _BTKit._NORMALISER_NODE_COUNT := 0;
end;

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
#   strategy.regOrbit = "never"   no regular-orbit deductions (default —
#                                 behaviour pre-Phase C)
#                     = "always"  Theißen §3.7: if E has a regular orbit
#                                 O, force the selector to branch on O
#                                 first (in canonical BFS order) and
#                                 emit forced-refinement labels for the
#                                 subset of O whose images are deducible
#                                 from the fixed points so far. After
#                                 s+1 well-chosen branches (s = #gens E
#                                 acting on O) the entire orbit is
#                                 isolated. Inert when E has no regular
#                                 orbit.
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
          pushOrbitals, pushBlocks, ogOptions, sortedKeys, stabSize, comp, idxs;
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
            for key in SortedList(Keys(families)) do
                fam := List(families[key], bs -> bs.graph);
                # Block-system graphs are unions of cliques (intra-block
                # complete digraphs); compress a singleton to its clique-star
                # gadget. Multi-member families keep the set widget.
                if Length(fam) = 1 then
                    Add(out, _BTKit.compressGraph(fam[1]));
                else
                    Append(out, _BTKit.buildSetOfGraphsWidget(fam, n));
                fi;
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
            # Compress each orbital graph (clique / complete-multipartite
            # components -> compact gadgets), then group by the equivalence
            # key of the COMPRESSED form. A clique gadget and a multipartite
            # gadget have different structure, so this also stops the (coarse,
            # over-merging) 1-WL key from bundling non-isomorphic orbital
            # graphs together: distinct gadgets land in singleton families and
            # are pushed compressed. Genuinely isomorphic orbitals still group
            # and fall back to the set widget on the original graphs.
            comp := List(ogList, _BTKit.compressGraph);
            families := _BTKit.partitionByKey([1 .. Length(ogList)],
                i -> _BTKit.orbitalEquivalenceKey(comp[i].graph));
            for key in SortedList(Keys(families)) do
                idxs := families[key];
                if Length(idxs) = 1 then
                    Add(out, comp[idxs[1]]);
                else
                    Append(out, _BTKit.buildSetOfGraphsWidget(
                        List(idxs, i -> ogList[i]), n));
                fi;
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
                local fixedpoints, result, group, n, i, regGroup, regOrbOps;
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

                # Phase C/D: regular-orbit deduction (Theißen §3.7).
                # Phase C (`strategy.regOrbit = "always"`): use E's own
                # regular orbit. Inert when E has none (e.g. AGL(1,p)).
                # Phase D (`strategy.regOrbitGroup` is bound to F ≤ E
                # characteristic): use F's regular orbit instead. Sound
                # because N(E) ≤ N(F) for characteristic F, so any
                # label-deduction valid for N(F) is valid for N(E).
                # Useful exactly when E is 2-transitive (or just lacks a
                # regular orbit) but contains a regular characteristic
                # subgroup, e.g. C_p ≤ AGL(1, p).
                if IsBound(strategy.regOrbit)
                   and strategy.regOrbit = "always" then
                    regGroup := _BTKit.regOrbitDeductionGroup(
                        group, strategy);
                    regOrbOps := _BTKit.makeNormaliserRegOrbitDeduction(
                        regGroup, fixedpoints, ps, n,
                        _BTKit.regOrbitProposeEnabled(strategy));
                    Append(result, regOrbOps[1]);
                    # Optional caller-supplied extra deduction, run after
                    # the Phase C regular-orbit deduction and handed its
                    # BFS-orbit record (regOrbOps[2], the deduced subset D
                    # of the regular orbit). An extension point for
                    # downstream code that wants to build further deductions
                    # on top of the regular-orbit machinery (e.g. Theißen
                    # §3.7.2 RegularOrbit3 cross-orbit propagation) without
                    # this constructor depending on it. Inert unless
                    # `extraRegOrbitDeduction` is supplied and the Phase C
                    # deduction produced a non-empty D.
                    if IsBound(strategy.extraRegOrbitDeduction)
                       and regOrbOps[2] <> false then
                        Append(result,
                            strategy.extraRegOrbitDeduction(
                                regGroup, fixedpoints, ps, n,
                                regOrbOps[2]));
                    fi;
                fi;

                r!.btdata.seenDepth := Length(fixedpoints);
                _BTKit._NORMALISER_NODE_COUNT :=
                    _BTKit._NORMALISER_NODE_COUNT + 1;
                return result;
            end)
    );
    return Objectify(GBRefinerType, r);
end;

# Phase C/D dispatch: returns the group whose regular-orbit data should
# feed the deduction. Phase C: group itself. Phase D:
# strategy.regOrbitGroup (a characteristic subgroup F ≤ E) if bound.
_BTKit.regOrbitDeductionGroup := function(group, strategy)
    if IsBound(strategy.regOrbitGroup) then
        return strategy.regOrbitGroup;
    fi;
    return group;
end;

# Whether to emit a proposeBranchPoint hint from the regular-orbit
# deduction. Phase C: yes (sound, gives ~50% speedup on AGL(1,p)).
# Phase D: no by default — the propose currently has a soundness bug
# on some inputs (e.g. TransGrp(8,33)); the regOrbit-set passed via
# strategy.regOrbitGroup = F can have the L/R selector picking
# non-corresponding cells when F is properly contained in E. The forced
# labels remain sound and are kept. TODO: trace the bug and re-enable.
_BTKit.regOrbitProposeEnabled := function(strategy)
    if IsBound(strategy.regOrbitPropose) then
        return strategy.regOrbitPropose;
    fi;
    if IsBound(strategy.regOrbitGroup) then
        # Phase D path — propose disabled until the soundness bug is
        # fixed (see above).
        return false;
    fi;
    # Phase C path (regOrbitGroup unbound): propose enabled.
    return true;
end;

# Phase D helper: search for a regular characteristic subgroup F ≤ E.
# Returns either E (if E is itself regular on some orbit — Phase C
# path), F ≤ E (a proper regular characteristic subgroup) — or `fail`
# if neither exists.
#
# Tries candidates in cost order:
#   1. E itself.
#   2. DerivedSubgroup(E), FittingSubgroup(E), Centre(E) — all
#      characteristic in E, cheap to compute.
#   3. Socle(E) when E is primitive on its support — characteristic.
#   4. CharacteristicSubgroups(E) — exhaustive but expensive; gated by
#      Size(E) ≤ sizeCap to keep things bounded.
#
# A subgroup F is "uniquely regular" here if it has EXACTLY ONE orbit
# O on MovedPoints(E) with |O| = |F| (other orbits may exist but must
# be strictly smaller). This is the soundness condition for the
# Phase D deduction: the regular-orbit labels we force are only
# g-equivariant under candidates g that map O to itself. When F has
# multiple regular orbits, N(E) (acting on F's orbit set) can permute
# them; the search would reject valid g's that swap regular orbits.
# Unique-regular-orbit F's avoid that pitfall — the unique O is
# necessarily g-invariant since it's the only orbit of its size.
_BTKit.findRegularCharacteristicSubgroup := function(group, sizeCap)
    local mp, _hasUniqueReg, orbLens, candidates, F, cs;

    mp := MovedPoints(group);

    _hasUniqueReg := function(F)
        local orbs, regOrbs;
        if IsTrivial(F) then return false; fi;
        orbs := Orbits(F, mp);
        regOrbs := Filtered(orbs, o -> Length(o) = Size(F));
        return Length(regOrbs) = 1;
    end;

    if _hasUniqueReg(group) then
        return group;
    fi;

    # Early-skip for intransitive H with ≥ 2 equal-length orbits.
    # Reasoning: if two H-orbits Ω_i, Ω_j have the same length, then
    # generically Aut(H) contains a swap between them, and any
    # characteristic F ≤ H must respect that swap. So F can't be
    # regular on Ω_i without also being regular on Ω_j — and the
    # uniqueness check fails. Skipping early also dodges a GAP-internal
    # performance pathology in which CharacteristicSubgroups hangs
    # after Size/Orbits have been called on Derived/Fitting/Centre
    # subgroups.
    # This is a heuristic: there exist exotic H where two equal-length
    # orbits have non-isomorphic H-actions and no Aut(H)-swap exists,
    # in which case we may miss a usable F. But those cases are rare
    # in practice and the bank doesn't include any.
    orbLens := List(Orbits(group, mp), Length);
    if Length(Set(orbLens)) < Length(orbLens) then
        return fail;
    fi;

    # DerivedSubgroup and Centre are cheap for any permutation group.
    candidates := [DerivedSubgroup(group)];
    # FittingSubgroup is the natural regular-characteristic-subgroup
    # candidate for a SOLVABLE group (its nilpotent radical), and is cheap
    # to compute via the solvable-group machinery. For a large NON-solvable
    # group FittingSubgroup can cost orders of magnitude more than the whole
    # normaliser problem (measured: 7.6 s on S_2 wr S_4 wr S_7, |H|≈6·10^21,
    # vs 74 ms for the entire normaliser) while never being regular — so
    # gate it on solvability. This mirrors GAP, whose NormalizerParentSA
    # dispatch only reaches the regular-characteristic-subgroup machinery in
    # the solvable / primitive-affine regime (GAP calls FittingSubgroup zero
    # times on that wreath). IsSolvableGroup is ~5 ms here.
    if IsSolvableGroup(group) then
        Add(candidates, FittingSubgroup(group));
    fi;
    Add(candidates, Centre(group));
    # Socle is the relevant candidate for primitive groups (the AGL/affine
    # case, F = regular socle); cheap on primitive inputs.
    if IsTransitive(group, mp) and IsPrimitive(group, mp) then
        Add(candidates, Socle(group));
    fi;
    for F in candidates do
        if _hasUniqueReg(F) then return F; fi;
    od;

    if Size(group) <= sizeCap then
        cs := CharacteristicSubgroups(group);
        for F in cs do
            if _hasUniqueReg(F) then return F; fi;
        od;
    fi;

    return fail;
end;

# Phase C deduction: forced-refinement labels for the points of E's
# regular orbit whose images are determined by the already-fixed
# points, plus a proposed branch point for the selector.
#
# At each refine.fixed event with fp = [b_1, .., b_d]:
#   - Filter regOrbFPs = fp ∩ regOrbit (preserving order).
#   - If |regOrbFPs| ≥ 2, let b = regOrbFPs[1] and form the generators
#     h_i = treeE[regOrbFPs[i]] · treeE[b]^-1 for i = 2..k. These are
#     the elements of E sending b to the other fixed regular-orbit
#     points. The BFS orbit D of b under <h_i> is the set whose
#     g-images are deducible from the fp ∩ regOrbit data alone. We
#     label each p ∈ D with its BFS position (so all D points get
#     distinct labels and the refinement isolates them).
#   - Propose the first non-singleton-cell point in the cached
#     canonical BFS-from-omega1 order as the next branch target.
#
# Covariance: regOrbit / treeE come from StabTreeRegularOrbitData,
# cached on the group itself (L = R for normaliser, so both sides see
# identical structural data). For valid g ∈ N(E), g maps regOrbit to
# regOrbit, fp_R = g(fp_L), and the deduction-set D_R = g(D_L). The
# labels match between sides because BFS-position(p) on the left
# equals BFS-position(g(p)) on the right (the generator-correspondence
# h_i^g = h_i' under conjugation by g).
# The branch-point proposal points to corresponding cells (same cell
# index) on both sides since cell indices are g-equivariant for valid
# candidates.
_BTKit.makeNormaliserRegOrbitDeduction := function(group, points, ps, n,
                                                   proposeEnabled)
    local data, regOrbFPs, b1, gens, i, bfs, out, p, ci, best_idx, best_p;
    data := StabTreeRegularOrbitData(group);
    if data = fail then
        return [[], false];
    fi;

    out := [];
    regOrbFPs := Filtered(points, p -> p in data.regOrbitSet);

    if IsEmpty(regOrbFPs) then
        # No regular-orbit point branched on yet. Propose the first
        # regOrbit point whose cell is the smallest-index non-singleton
        # cell containing any regOrbit point. Cell indices are
        # g-equivariant (they're determined by trace-matching splits);
        # point values are not, which is why we don't iterate over
        # sorted points and pick the first.
        if not proposeEnabled then return [[], false]; fi;
        best_idx := infinity;
        best_p := fail;
        for p in data.regOrbit do
            ci := PS_CellOfPoint(ps, p);
            if PS_CellLen(ps, ci) > 1 and ci < best_idx then
                best_idx := ci;
                best_p := p;
            fi;
        od;
        if best_p <> fail then
            Add(out, rec(proposeBranchPoint := best_p));
        fi;
        return [out, false];
    fi;

    # D = orbit of b_1 under <gens>. Build gens for i = 2..|regOrbFPs|.
    # Element of E sending b_1 to regOrbFPs[i] is
    # treeE[b_1]^-1 * treeE[regOrbFPs[i]] in GAP's left-to-right
    # convention (x^(g*h) = (x^g)^h).
    b1 := regOrbFPs[1];
    gens := [];
    for i in [2 .. Length(regOrbFPs)] do
        Add(gens, data.treeE[b1] ^ -1 * data.treeE[regOrbFPs[i]]);
    od;
    bfs := _BTKit.bfsOrbit(b1, gens);

    # Forced-refinement labels: each p ∈ D = orbit of b_1 under <gens>
    # gets a unique BFS-position label, others get 0. Canonical-safe
    # (label values are intrinsic to D's structure, not to specific
    # point values).
    if Length(regOrbFPs) >= 2 then
        Add(out, function(p)
            if p in bfs.position then
                return bfs.position[p];
            else
                return 0;
            fi;
        end);
    fi;

    if proposeEnabled then
        best_idx := infinity;
        best_p := fail;
        for p in data.regOrbit do
            if not (p in bfs.position) then
                ci := PS_CellOfPoint(ps, p);
                if PS_CellLen(ps, ci) > 1 and ci < best_idx then
                    best_idx := ci;
                    best_p := p;
                fi;
            fi;
        od;
        if best_p <> fail then
            Add(out, rec(proposeBranchPoint := best_p));
        fi;
    fi;

    return [out, bfs];
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

# Phase C variant: orbital widget + Theißen §3.7 regular-orbit deductions.
# When E has a regular orbit, the selector is steered onto that orbit
# in canonical BFS order, and once enough generators are "tied down"
# the rest of the orbit is forced to isolate. When E has no regular
# orbit (e.g. AGL(1,p)), the regular-orbit refiner is inert and
# behaviour matches GroupConjugacyOrbital. The eventual Phase D will
# search for a regular characteristic subgroup F ≤ E and feed F to
# this same machinery — keeping that extension easy is why the
# data is fetched from StabTreeRegularOrbitData(group) rather than
# anything tied to E specifically.
#
# KNOWN LIMITATION: this variant is NOT canonical-safe. The
# selector-hook proposal (smallest cell index containing a regOrbit
# point) depends on data.regOrbit, a point set in the original Ω
# labelling. For conjugate inputs U vs U^σ this set is σ-conjugate,
# not equal, so the search trajectories diverge in a way the
# canonical-trace minimiser can't reconcile — a canonical-image search
# with this variant can return different (conjugate) groups for U
# and U^σ. Symmetry-mode (normaliser equality) is correct; canonical
# mode is not. Use `GroupConjugacyOrbital` for canonical applications
# until a canonical-safe proposal is designed.
GB_Con.GroupConjugacyOrbitalRegOrbit := function(groupL, groupR)
    return _MakeGroupConjugacyOrbital(groupL, groupR,
        rec(orbitals := "always", blocks := "root",
            regOrbit := "always"),
        "GroupConjugacyOrbitalRegOrbit");
end;

# Phase D: Theißen §3.7.3 — when E itself has no regular orbit, search
# for a regular characteristic subgroup F ≤ E and run the §3.7
# deductions against F instead. N(E) ≤ N(F) for characteristic F, so
# every label produced from F is valid for any g ∈ N(E).
#
# When E has a regular orbit, this is identical to OrbitalRegOrbit
# (F = E). When E has none and no regular characteristic subgroup
# either, the regular-orbit refiner is inert and behaviour matches
# Orbital. The expected payoff is on AGL-like inputs where E is
# 2-transitive (no orbital pruning, no regular orbit of E) but F = C_p
# (the radical) is regular.
#
# Same canonical-unsafety caveat as OrbitalRegOrbit applies (regOrbit
# point set depends on the labelling; conjugate inputs see conjugate
# regOrbits).
#
# `sizeCap` parameter on the exhaustive CharacteristicSubgroups search
# defaults to 10^3, chosen by measuring the cost crossover.
#
# CharacteristicSubgroups(H) is implemented in GAP as
#   Filtered(NormalSubgroups(H), x -> IsCharacteristicSubgroup(H, x))
# so the dominant cost is the normal-subgroup lattice (and one
# AutomorphismGroup(H)-invariance check per candidate). That lattice
# scales with the SUBGROUP STRUCTURE of H — exponential for nilpotent
# H — rather than with the partition-backtrack search space, which
# is bounded by orbit structure inside S_n. So for the subdirect /
# wreath-style inputs that motivate Phase D in the first place,
# computing CharacteristicSubgroups can easily cost more than the
# normaliser problem we want to solve.
#
# Empirical (clean-state timings, this file's commit message):
#   |H|=64    NormalSubgroups 21 ms  CS 14 ms     Normalizer 27 ms
#   |H|=32768 NormalSubgroups did not finish in >40 s; Normalizer 47 ms.
# At |H|=10^3 the lattice has been comfortably small in everything I
# have tried; at |H|=10^4 it starts to be a coin-flip; beyond that
# the auxiliary cost dominates. 10^5 was the original default and was
# wrong for the inputs we actually care about (subdirect mixers etc.).
# Caller can override via ValueOption "regCharSizeCap".
#
# The structural candidate list (DerivedSubgroup, Centre always;
# FittingSubgroup only when solvable; Socle only when primitive) is tried
# regardless of sizeCap; only the exhaustive CS scan is gated by sizeCap.
# Theißen's primary motivating case (AGL family, where F = the regular
# socle) is caught by the cheap Socle path, so neither cut loses those.
# FittingSubgroup is gated on solvability because it is the pathologically
# expensive candidate on large non-solvable groups (see
# findRegularCharacteristicSubgroup).
GB_Con.GroupConjugacyOrbitalRegOrbitChar := function(groupL, groupR)
    local F, sizeCap;
    Assert(0, IsIdenticalObj(groupL, groupR),
           "Phase D is normaliser-only; expect L = R");
    sizeCap := ValueOption("regCharSizeCap");
    if sizeCap = fail then sizeCap := 10 ^ 3; fi;
    F := _BTKit.findRegularCharacteristicSubgroup(groupL, sizeCap);
    if F = fail then
        # No regular characteristic subgroup; fall back to Phase C
        # (which is also inert in this case, so this matches Orbital).
        return _MakeGroupConjugacyOrbital(groupL, groupR,
            rec(orbitals := "always", blocks := "root",
                regOrbit := "always"),
            "GroupConjugacyOrbitalRegOrbitChar");
    fi;
    return _MakeGroupConjugacyOrbital(groupL, groupR,
        rec(orbitals := "always", blocks := "root",
            regOrbit := "always",
            regOrbitGroup := F),
        "GroupConjugacyOrbitalRegOrbitChar");
end;

GB_Con.NormaliserOrbital                 := {g} -> GB_Con.GroupConjugacyOrbital(g, g);
GB_Con.NormaliserOrbitalRoot             := {g} -> GB_Con.GroupConjugacyOrbitalRoot(g, g);
GB_Con.NormaliserOrbitalNone             := {g} -> GB_Con.GroupConjugacyOrbitalNone(g, g);
GB_Con.NormaliserOrbitalDeep             := {g} -> GB_Con.GroupConjugacyOrbitalDeep(g, g);
GB_Con.NormaliserOrbitalSmall            := {g} -> GB_Con.GroupConjugacyOrbitalSmall(g, g);
GB_Con.NormaliserOrbitalRegOrbit         := {g} -> GB_Con.GroupConjugacyOrbitalRegOrbit(g, g);
GB_Con.NormaliserOrbitalRegOrbitChar     := {g} -> GB_Con.GroupConjugacyOrbitalRegOrbitChar(g, g);
