# Vole: Backtrack search in permutation groups with graphs
# A GAP package by Mun See Chang, Christopher Jefferson, and Wilf A. Wilson.
#
# SPDX-License-Identifier: MPL-2.0
#
# Implementations: Wrappers for Vole functions that emulate GAP/images/Digraphs

################################################################################
# Wrapper for the GAP library

Vole.Intersection := function(permcolls...)
    local ret;
    if Length(permcolls) = 1 and IsList(permcolls[1]) then
        permcolls := permcolls[1];
    fi;
    if IsEmpty(permcolls) then
        ErrorNoReturn("Vole.Intersection: The arguments must specify at least ",
                      "one perm group or right coset");
    elif not ForAll(permcolls, x -> IsPermGroup(x) or IsRightCoset(x)) then
        ErrorNoReturn("Vole.Intersection: The arguments must be ",
                      "(a list containing) perm groups and/or ",
                      "right cosets of perm groups");
    elif ForAll(permcolls, IsPermGroup) then
        return VoleFind.Group(permcolls);
    else
        ret := VoleFind.Coset(permcolls);
        if ret <> fail then
            return ret;
        else
            return [];
        fi;
    fi;
end;

Vole.Stabilizer := function(G, object, action...)
    local con, ret;
    con := CallFuncList(Constraint.Stabilize, Concatenation([object], action));
    ret := VoleFind.Group(G, con);
    _Vole.setParent(ret, G);
    return ret;
end;
Vole.Stabiliser := Vole.Stabilizer;

# Wrapper family for Vole.Normalizer.
#
# A wrapper is an outer reduction that composes inner backtrack searches.
# Different wrappers exploit different structural properties of H. They
# share the same inner refiner family (default `Orbital`) but differ in
# how they decompose the problem before the search runs.
#
# Currently supported (selected via ValueOption "wrapper"):
#
#   "direct"   — no outer reduction. One backtrack search in G for
#                elements normalising H. Fastest when the inner refiner
#                already encodes all useful structure (e.g. full direct
#                products, where the orbital-graph widget captures the
#                wreath structure on its own).
#
#   "ByOrbits" — Chang [CJR22] L-overgroup decomposition. For
#                intransitive H ≤ S_n with orbits {Ω_1, …, Ω_k} the
#                normaliser N_{S_n}(H) is contained in an overgroup L
#                built from per-orbit data:
#                  * Let G_i = H|_{Ω_i} (i-th enveloping factor).
#                  * Group orbits into perm-isomorphism classes of
#                    their restrictions. N(H) can swap orbits within
#                    a class but not across classes.
#                  * For each class, pick a representative orbit Ω_r
#                    and compute N_r := N_{Sym(Ω_r)}(G_r). Lift to the
#                    other class members via witness perms φ : Ω_r → Ω_j
#                    conjugating G_r to G_j.
#                  * L := direct product over classes of (N_r ≀ S_{|c|}).
#                Then N(H) ≤ L by Lemma 2.8 of [CJR22], and the inner
#                search runs in G ∩ L. L = N(H) exactly when H is a
#                full direct product of its enveloping factors; the
#                inner search refines L whenever H is a strict
#                subdirect.
#
# All wrappers preserve the kept-algorithm contract: none of them is
# strictly stronger than the others on every input, and removing one
# would lose a benchmarking baseline. Default = "direct".
#
# Reference: M. S. Chang, C. Jefferson, C. M. Roney-Dougal,
# "Computing normalisers of intransitive groups",
# arXiv:2112.00388, §2.3 Lemma 2.8.

# Restriction of `H` to a single orbit `orb`, returned as a perm group
# acting on the original orb labelling (other points fixed).
_Vole.RestrictedGroup := function(H, orb)
    local gens;
    gens := List(GeneratorsOfGroup(H), h -> RestrictedPerm(h, orb));
    return Group(gens, ());
end;

# Canonicalisation record for a perm group acting on a specific point set.
# Returns rec(relabel, relabelInv, canonGroup, canonPerm) where:
#   relabel        — perm of S_n with orb mapped to [1..|orb|]
#   relabelInv     — its inverse
#   canonGroup     — Vole.CanonicalImage(Sym(|orb|), H ^ relabel)
#   canonPerm      — canonicalising perm γ with (H ^ relabel) ^ γ = canonGroup
#
# Two perm groups on (possibly different) orbits are permutation-
# isomorphic iff their canonGroups are equal as subgroups of Sym([1..m]).
# The forward bijection Ω_i → Ω_j conjugating G_i to G_j is given by
#     relabel_i · canonPerm_i · canonPerm_j^-1 · relabelInv_j
# restricted to Ω_i. `_Vole.PermIsoWitness` turns this restriction into
# an involution swapping Ω_i ↔ Ω_j and fixing the rest of [1..n].
_Vole.CanonicalisePermGroup := function(orb, H)
    local sortedOrb, m, sigma, Hrel, ret;
    sortedOrb := SortedList(orb);
    m := Length(sortedOrb);
    sigma := MappingPermListList(sortedOrb, [1 .. m]);
    Hrel := H ^ sigma;
    ret := rec(
        relabel    := sigma,
        relabelInv := sigma ^ -1,
        canonGroup := Vole.CanonicalImage(
            SymmetricGroup(m), Hrel, OnPoints),
        canonPerm  := Vole.CanonicalPerm(
            SymmetricGroup(m), Hrel, OnPoints)
    );
    return ret;
end;

# Witness perm w ∈ S_n with the following structure:
#   * w swaps Ω_i ↔ Ω_j as an involution (w|_Ω_i is a bijection
#     Ω_i → Ω_j; w|_Ω_j is its inverse).
#   * w fixes every point outside Ω_i ∪ Ω_j.
#   * Conjugation by w sends G_i (acting on Ω_i, fixing Ω_j) to G_j
#     (acting on Ω_j, fixing Ω_i).
#
# Construction: factor the bijection Ω_i → Ω_j through canonical-form
# space. The "raw" product
#     f = relabel_i · canonPerm_i · canonPerm_j^-1 · relabelInv_j
# correctly maps Ω_i to Ω_j and conjugates G_i to G_j on Ω_i, but it
# generally acts non-trivially on points in the relabel codomain
# [1..m] (which may belong to other orbits). We extract f restricted
# to Ω_i and build the involution from that restriction.
_Vole.PermIsoWitness := function(orb_i, canon_i, canon_j)
    local f, points, images, p, image;
    f := canon_i.relabel
         * canon_i.canonPerm
         * canon_j.canonPerm ^ -1
         * canon_j.relabelInv;
    points := [];
    images := [];
    for p in orb_i do
        image := p ^ f;
        Add(points, p);      Add(images, image);
        Add(points, image);  Add(images, p);
    od;
    return MappingPermListList(points, images);
end;

# Build the L overgroup from H's orbit data. Returns a perm group on
# the ambient point set; N_{S_n}(H) ≤ L.
_Vole.BuildLOvergroup := function(H, relevantPoints)
    local orbs, restrictions, canons, classes, Lgens,
          key, c, repIdx, repN, j, witness;

    orbs := Orbits(H, relevantPoints);
    restrictions := List(orbs, orb -> _Vole.RestrictedGroup(H, orb));
    canons := List([1 .. Length(orbs)],
                   i -> _Vole.CanonicalisePermGroup(
                            orbs[i], restrictions[i]));

    # Group orbit indices by (orbit length, canonical group elements).
    # Two orbits with the same key have perm-isomorphic restrictions
    # and may be swapped by an element of N(H). The canonical group
    # is represented by its sorted element list (hashable, equal-iff-
    # same-group; a perm group object directly isn't hashable).
    classes := _BTKit.partitionByKey(
        [1 .. Length(orbs)],
        i -> [Length(orbs[i]),
              Immutable(AsSortedList(canons[i].canonGroup))]);

    Lgens := [];
    for key in SortedList(Keys(classes)) do
        c := classes[key];
        repIdx := c[1];
        # Per-orbit normaliser of the representative restriction. The
        # restriction is transitive on its orbit, so this recursive
        # Vole.Normalizer call falls through to the direct path.
        repN := Vole.Normalizer(SymmetricGroup(orbs[repIdx]),
                                restrictions[repIdx]);
        Append(Lgens, GeneratorsOfGroup(repN));
        # For each other orbit in the class, add the witness perm and
        # the conjugated per-orbit normaliser. The witness perm swaps
        # the representative orbit with this one; the conjugated
        # generators act inside this orbit.
        for j in c{[2 .. Length(c)]} do
            witness := _Vole.PermIsoWitness(orbs[repIdx],
                                            canons[repIdx], canons[j]);
            Add(Lgens, witness);
            Append(Lgens, List(GeneratorsOfGroup(repN),
                               g -> g ^ witness));
        od;
    od;

    if IsEmpty(Lgens) then
        return Group(());
    fi;
    return Group(Lgens);
end;

# "direct" wrapper. One backtrack search in G with the normaliser
# constraint on H. The simplest baseline. Honours ValueOption "refiner"
# (string, key into `GB_Con.Normaliser<name>`) so different refiner
# variants can be exercised through this wrapper for benchmarking;
# default is "OrbitalRegOrbit" because the hunt benchmark shows it's
# 2-3x faster than Orbital across the input space and the regular-
# orbit deductions cost nothing when H has no regular orbit.
_Vole.NormalizerDirect := function(G, H)
    local refinerName, refiner, simple, ret;
    refinerName := ValueOption("refiner");
    if refinerName = fail then
        refinerName := _Vole.NormalizerDefaultRefiner;
    fi;
    refiner := GB_Con.(Concatenation("Normaliser", refinerName))(H);
    # Robustness: also push NormaliserSimple2 alongside the chosen
    # orbital refiner.  Simple2's block-system encoding (a 2-level
    # aux structure) gives the selector a different signal from
    # what `buildSetOfGraphsWidget` produces for orbital graphs,
    # and on imprimitive transitive inputs (e.g. TransGrp(20;1000))
    # branching on Simple2's block-aligned cells beats branching on
    # the sub-cells that orbital-graph refinement produces.  Cost:
    # one extra push per fixed-point event (~few ms on small inputs,
    # negligible on big ones).  Skip when the user explicitly asked
    # for "Simple"/"Simple2" — they'd be pushed twice otherwise.
    if refinerName <> "Simple" and refinerName <> "Simple2" then
        simple := GB_Con.NormaliserSimple2(H);
        ret := VoleFind.Group(G, simple, refiner);
    else
        ret := VoleFind.Group(G, refiner);
    fi;
    _Vole.setParent(ret, G);
    return ret;
end;

# "ByOrbits" wrapper (Chang [CJR22] L-overgroup). Recursive on the
# per-orbit normaliser (transitive on its single orbit so the
# recursion bottoms out cleanly on the next call). Returns the
# normaliser as a perm group. Honours ValueOption "refiner".
_Vole.NormalizerByOrbits := function(G, H)
    local relevantPoints, n, orbs, L, refinerName, refiner, ret;

    if IsTrivial(H) then
        # Every g normalises the trivial group. Just return G.
        return G;
    fi;

    # Decompose by orbits within G's moved-point set. Restricting to
    # MovedPoints(G) is the principled choice: an element of G can
    # only act on points G itself moves, so points outside G's
    # support contribute nothing to N_G(H). It also makes the
    # per-class recursion bottom out — a per-orbit normaliser
    # call on Sym(orb) sees `relevantPoints = orb` and immediately
    # hits the single-orbit base case.
    relevantPoints := MovedPoints(G);
    if IsEmpty(relevantPoints) then
        return G;
    fi;
    n := Maximum(relevantPoints);
    orbs := Orbits(H, relevantPoints);

    # Base case: H has at most one orbit within G's support. Hand off
    # to the direct path.
    if Length(orbs) <= 1 then
        return _Vole.NormalizerDirect(G, H);
    fi;

    L := _Vole.BuildLOvergroup(H, relevantPoints);

    refinerName := ValueOption("refiner");
    if refinerName = fail then
        refinerName := _Vole.NormalizerDefaultRefiner;
    fi;
    refiner := GB_Con.(Concatenation("Normaliser", refinerName))(H);

    # Inner search: find elements of G that lie in L AND normalise H.
    # N(H) ≤ L (Lemma 2.8) so this captures the full normaliser; the
    # search space is G ∩ L, much smaller than G when H has many
    # equivalent orbits.  See NormalizerDirect for why we also push
    # NormaliserSimple2 alongside the orbital refiner.
    if refinerName <> "Simple" and refinerName <> "Simple2" then
        ret := VoleFind.Group(SymmetricGroup(n),
                              Constraint.InGroup(G),
                              Constraint.InGroup(L),
                              GB_Con.NormaliserSimple2(H),
                              refiner);
    else
        ret := VoleFind.Group(SymmetricGroup(n),
                              Constraint.InGroup(G),
                              Constraint.InGroup(L),
                              refiner);
    fi;
    _Vole.setParent(ret, G);
    return ret;
end;

# Registry of all wrapper strategies. Adding one here makes it
# selectable via ValueOption "wrapper". Used by bank tests and
# benchmarks to iterate over the full set.
_Vole.NormalizerWrappers := rec(
    direct   := _Vole.NormalizerDirect,
    ByOrbits := _Vole.NormalizerByOrbits);

# Currently-selected default wrapper. Empirically "direct" wins on
# full-direct-product inputs because the orbital widget already
# encodes the wreath structure; ByOrbits is the principled choice
# for strict subdirect inputs and inhomogeneous classes (see jnp.g
# bank tests). When the benchmarks tell us which input class wins
# more often, swap this and document.
_Vole.NormalizerDefaultWrapper := "direct";

# Default refiner used inside the direct wrapper. The hunt benchmark
# rates OrbitalRegOrbit best by total wall time (2-3x over Orbital
# across the input space). OrbitalRegOrbitChar extends OrbitalRegOrbit
# with Phase D — regular characteristic subgroup deductions — which
# closes the AGL family gap (the biggest loss family in the hunt).
# Both refiners are canonical-unsafe; canonical-image dispatch stays
# at GroupConjugacyOrbital via refiners.gi:26.
_Vole.NormalizerDefaultRefiner := "OrbitalRegOrbitChar";

# Respects ValueOption "wrapper" (string, key into _Vole.NormalizerWrappers).
Vole.Normalizer := function(G, U)
    local wrapperName, wrapper;
    if not IsPermGroup(G) then
        ErrorNoReturn("Vole.Normalizer: ",
                      "The first argument must be a perm group");
    fi;
    if IsPerm(U) then
        U := Group(U);
    elif not IsPermGroup(U) then
        ErrorNoReturn("Vole.Normalizer: The second argument ",
                      "must a perm group or a permutation");
    fi;
    # Cheap pre-checks, matching GAP's NormalizerPermGroup
    # (stbcbckt.gi:2837+): trivial U, or U = G. GAP does NOT do a full
    # IsNormal(G, U) here — it relies on the backtrack (which is seeded with
    # U <= N(U)). A full IsNormal costs e.g. 1.2s at degree 200 for an answer
    # the search already reaches in ~0 nodes, so we drop it and use only the
    # O(1) checks GAP uses: IsSubset (cheap for natural S_n) + Size equality.
    if IsTrivial(U) then
        return G;
    fi;
    if IsSubset(G, U) and Size(G) = Size(U) then
        return G;
    fi;
    wrapperName := ValueOption("wrapper");
    if wrapperName = fail then
        wrapperName := _Vole.NormalizerDefaultWrapper;
    fi;
    if not IsBound(_Vole.NormalizerWrappers.(wrapperName)) then
        ErrorNoReturn("Vole.Normalizer: unknown wrapper '", wrapperName,
                      "'. Known wrappers: ",
                      RecNames(_Vole.NormalizerWrappers));
    fi;
    wrapper := _Vole.NormalizerWrappers.(wrapperName);
    return wrapper(G, U);
end;
Vole.Normaliser := Vole.Normalizer;

Vole.Centralizer := function(G, x)
    local ret;
    if not IsPermGroup(G) then
        ErrorNoReturn("Vole.Centralizer: ",
                      "The first argument must be a perm group");
    elif not (IsPermGroup(x) or IsPerm(x)) then
        ErrorNoReturn("Vole.Centralizer: The second argument ",
                      "must be a perm group or a permutation");
    fi;
    ret := VoleFind.Group(G, Constraint.Centralize(x));
    _Vole.setParent(ret, G);
    return ret;
end;
Vole.Centraliser := Vole.Centralizer;

Vole.IsConjugate := function(G, x, y)
    if not IsPermGroup(G) then
        ErrorNoReturn("Vole.IsConjugate: ",
                      "The first argument must be a perm group");
    elif not ForAll([x, y], IsPerm) and not ForAll([x, y], IsPermGroup) then
        ErrorNoReturn("Vole.IsConjugate: The second and third arguments ",
                      "must either be both permutations or both perm groups");
    fi;
    return Vole.RepresentativeAction(G, x, y) <> fail;
end;

Vole.RepresentativeAction := function(G, object1, object2, action...)
    if not IsPermGroup(G) then
        ErrorNoReturn("Vole.RepresentativeAction: ",
                      "The first argument must be a perm group");
    elif Length(action) > 1 then
        ErrorNoReturn("Vole.RepresentativeAction args: ",
                      "G, object1, object2[, action]");
    elif Length(action) = 1 then
        action := action[1];
    else
        action := OnPoints;
    fi;
    return VoleFind.Representative(G, Constraint.Transport(object1, object2, action));
end;

Vole.TwoClosure := function(G)
    local points, func, digraphs, digraph_con;
    if not IsPermGroup(G) then
        ErrorNoReturn("Vole.TwoClosure: ",
                      "The argument must be a perm group");
    fi;

    points := MovedPoints(G);
    if not IsPackageLoaded("orbitalgraphs") then
        ErrorNoReturn("Vole.TwoClosure requires the OrbitalGraphs package, ",
                      "which is not currently loaded");
        # The following is quite slow, we don't include it for now
        # orbitals := Orbits(G, Arrangements(points, 2), OnPairs);
        # digraphs := List(orbitals, DigraphByEdges);
    else
        func     := EvalString("OrbitalGraphs");  # Hack to avoid warnings
        digraphs := func(G);
    fi;

    if Length(digraphs) = 1 then
        # 1 OrbitalGraph -> complete digraph -> two-closure is symmetric group
        return SymmetricGroup(points);
    else
        digraph_con := Constraint.Stabilise(digraphs, OnTuplesDigraphs);
        return VoleFind.Group(Constraint.MovedPoints(points), digraph_con);
    fi;
end;

################################################################################
# Wrapper for the images package

Vole.CanonicalPerm := function(G, object, action...)
    local ret;
    if not IsPermGroup(G) then
        ErrorNoReturn("Vole.CanonicalPerm: ",
                      "The first argument must be a perm group");
    elif Length(action) > 1 then
        ErrorNoReturn("Vole.CanonicalPerm args: G, object[, action]");
    elif Length(action) = 1 then
        action := action[1];
    else
        action := OnPoints;
    fi;
    ret := VoleFind.Canonical(G, Constraint.Stabilize(object, action));
    return ret.canonical;
end;
Vole.CanonicalImagePerm := Vole.CanonicalPerm;

Vole.CanonicalImage := function(G, object, action...)
    local x;
    if Length(action) > 1 then
        ErrorNoReturn("Vole.CanonicalImage args: G, object[, action]");
    elif Length(action) = 1 then
        action := action[1];
    else
        action := OnPoints;
    fi;
    x := Vole.CanonicalPerm(G, object, action);
    return action(object, x);
end;

################################################################################
# Wrapper for the Digraphs package

Vole.AutomorphismGroup := function(D, colours...)
    if not IsDigraph(D) then
        ErrorNoReturn("Vole.AutomorphismGroup: ",
                      "The first argument must be a digraph");
    elif not IsEmpty(colours) then
        ErrorNoReturn("not yet implemented for vertex/edge colours");
    fi;
    return Vole.Stabilizer(SymmetricGroup(DigraphVertices(D)), D, OnDigraphs);
end;

Vole.CanonicalDigraph := function(D)
    if not IsDigraph(D) then
        ErrorNoReturn("Vole.AutomorphismGroup: ",
                      "The first argument must be a digraph");
    fi;
    return Vole.CanonicalImage(SymmetricGroup(DigraphVertices(D)), D, OnDigraphs);
end;

Vole.DigraphCanonicalLabelling := function(D, colours...)
    if not IsDigraph(D) then
        ErrorNoReturn("Vole.AutomorphismGroup: ",
                      "The first argument must be a digraph");
    elif not IsEmpty(colours) then
        ErrorNoReturn("not yet implemented for vertex/edge colours");
    fi;
    return Vole.CanonicalPerm(SymmetricGroup(DigraphVertices(D)), D, OnDigraphs);
end;

Vole.IsIsomorphicDigraph := function(D1, D2)
    if not IsDigraph(D1) or not IsDigraph(D2) then
        ErrorNoReturn("Vole.IsIsomorphicDigraph: ",
                      "The arguments must be digraphs");
    fi;
    return Vole.IsomorphismDigraphs(D1, D2) <> fail;
end;

Vole.IsomorphismDigraphs := function(D1, D2)
    local G;
    if not (IsDigraph(D1) and IsDigraph(D2)) then
        ErrorNoReturn("Vole.IsomorphismDigraphs: ",
                      "The arguments must be digraphs");
    fi;
    return VoleFind.Rep(Constraint.Transport(D1, D2, OnDigraphs));
end;
