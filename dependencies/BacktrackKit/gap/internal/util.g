# These functions are copied from Ferret.
# We don't use the OrbitalGraphs package, as it doesn't let us specify a 'maxval'.

_BTKit.fillRepElements := function(G, orb)
  local val, g, reps, buildorb, gens;
  reps := [];
  reps[orb[1]] := ();
  buildorb := [orb[1]];
  gens := GeneratorsOfGroup(G);
  for val in buildorb do
        for g in gens do
          if not IsBound(reps[val^g]) then
                reps[val^g] := reps[val] * g;
                Add(buildorb, val^g);
          fi;
        od;
  od;
  return reps;
end;

_BTKit.options := function(default, useroptions)
    local name, ret;
    ret := rec();

    if IsList(useroptions) then
      if IsEmpty(useroptions) then
        return default;
      elif Length(useroptions) = 1 then
        useroptions := useroptions[1];
      else
        ErrorNoReturn("Too many arguments for function");
      fi;
    fi;

    if not IsRecord(useroptions) then
      ErrorNoReturn("Options should be a record");
    fi;

    ret := ShallowCopy(default);

    for name in RecNames(useroptions) do
      if not IsBound(default.(name)) then
        ErrorNoReturn(Concatenation("Unknown option: " , name));
      else
        ret.(name) := useroptions.(name);
      fi;
    od;

    return ret;
  end;

_BTKit.orbitalOptions := function(options)
    return _BTKit.options(rec(skipOneLarge := false, cutoff := false, maxval := false), options);
end;

_BTKit.getOrbitalList := function(sc, maxval)
    return _BTKit.getOrbitalListWithOptions(sc, rec(maxval := maxval, skipOneLarge := true));
end;

_BTKit.getOrbitalListWithOptions := function(sc, options...)
    local G, maxval,
        orb, orbitsG, iorb, graph, graphlist, val, p, i, orbsizes, orbpos, innerorblist, orbitsizes,
            biggestOrbit, skippedOneLargeOrbit, orbreps, cutoff;
    
    options := _BTKit.orbitalOptions(options);

    if options.cutoff = false then
        cutoff := infinity;
    else
        cutoff := options.cutoff;
    fi;


    if IsGroup(sc) then
        G := sc;
    else
        G := GroupStabChain(sc);
    fi;

    if options.maxval = false then
        maxval := LargestMovedPoint(G);
    else
        maxval := options.maxval;
    fi;

    # Catch stupid case early
    if Size(G) = 1 then
        return [];
    fi;

    graphlist := [];
    # Make sure orbits are sorted, so we always get the same list of graphs
    orbitsG := Set(Orbits(G,[1..maxval]), Set);
    
    orbsizes := [];
    orbpos := [];
    # Efficently store size of orbits of values
    for orb in [1..Length(orbitsG)] do
        for i in orbitsG[orb] do
            orbsizes[i] := Size(orbitsG[orb]);
            orbpos[i] := orb;
        od;
    od;
    
    innerorblist := List(orbitsG, o -> Set(Orbits(Stabilizer(G, o[1]), [1..LargestMovedPoint(G)]), Set));

    orbitsizes := List([1..Length(orbitsG)], x -> List(innerorblist[x], y -> Size(orbitsG[x])*Size(y)));
    
    biggestOrbit := Maximum(Flat(orbitsizes));

    skippedOneLargeOrbit := false;

    for i in [1..Size(orbitsG)] do
        orb := orbitsG[i];
        orbreps := [];
        for iorb in innerorblist[i] do
            if (Size(orb) * Size(iorb) = biggestOrbit and options.skipOneLarge and not skippedOneLargeOrbit) then
                skippedOneLargeOrbit := true;
            else
                if (Size(orb) * Size(iorb) <= cutoff) and
                # orbit size unchanged
                not(Size(iorb) = orbsizes[iorb[1]]) and
                # orbit size only removed one point
                not(orbpos[orb[1]] = orbpos[iorb[1]] and Size(iorb) + 1 = orbsizes[iorb[1]]) and
                # don't want to take the fixed point orbit
                not(orb[1] = iorb[1] and Size(iorb) = 1)
                    then
                    graph := List([1..maxval], x -> []);
                    if IsEmpty(orbreps) then
                      orbreps := _BTKit.fillRepElements(G, orb);
                    fi;
                    for val in orb do
                        p := orbreps[val];
                        graph[val] := OnTuples(iorb, p);
                    od;
                    Add(graphlist, graph);
                fi;
            fi;
        od;
    od;
    #Print(sc, ":", maxval, ":", graphlist, "\n");
    # Use NC because we trust our graphs, and it takes a long time for 'Digraph' to check.
    return List(graphlist, DigraphNC);
end;

_BTKit.InNeighboursSafe := function(graph, v)
    if v in DigraphVertices(graph) then
        return InNeighbours(graph)[v];
    else
        return [];
    fi;
end;

_BTKit.OutNeighboursSafe := function(graph, v)
    if v in DigraphVertices(graph) then
        return OutNeighbours(graph)[v];
    else
        return [];
    fi;
end;

#############################################################################
##
## Set-of-graphs widget.
##
## Given a list `graphs` of labelled digraphs on [1..n] that the normaliser
## (or similar coset-stabiliser) preserves AS A SET (not individually),
## build a single labelled digraph whose Sym(Ω)-automorphism group equals
## the setwise stabiliser of `graphs` in Sym(Ω).
##
## Encoding:
##   - Vertices 1..n: original points, label 0.
##   - Vertices n+1..n+k: family-member vertices w_1..w_k, label 1.
##   - Vertices n+k+1..: arc-vertices u_{i,α,β}, label 2.
## For each arc (α, β) in graphs[i], add directed edges
##   α → u_{i,α,β},   u_{i,α,β} → β,   w_i → u_{i,α,β}.
##
## Returns a list of records: either a single set-widget record, or (in the
## singleton-family fast path) a single record pushing the graph directly.
## Returns the empty list if the input is empty.
##
_BTKit.buildSetOfGraphsWidget := function(graphs, n)
    local k, adj, labels, wBase, uBase, i, w, arc, u, edges, nextAux, g;

    k := Length(graphs);
    if k = 0 then
        return [];
    fi;

    # Contract: every input digraph must live entirely on [1..n].
    # If you have a graph with auxiliary vertices, encode the structure
    # as a graph on [1..n] (e.g. block systems as intra-block complete
    # digraphs) before passing here.
    for g in graphs do
        Assert(0, DigraphNrVertices(g) <= n);
    od;

    # Singleton fast path: a graph in a class by itself is preserved
    # individually by the normaliser, so we push it as a plain digraph.
    if k = 1 then
        return [rec(graph := graphs[1])];
    fi;

    # Multi-member family: build the widget.
    adj := List([1..n], i -> []);
    labels := ListWithIdenticalEntries(n, 0);

    # Append k family-member vertices.
    for i in [1..k] do
        Add(adj, []);
        Add(labels, 1);
    od;
    wBase := n;            # vertex w_i = wBase + i
    nextAux := n + k;

    for i in [1..k] do
        w := wBase + i;
        edges := DigraphEdges(graphs[i]);
        for arc in edges do
            nextAux := nextAux + 1;
            u := nextAux;
            Add(adj, [arc[2]]);        # u → β
            Add(labels, 2);
            Add(adj[arc[1]], u);       # α → u
            Add(adj[w], u);            # w_i → u
        od;
    od;

    return [rec(graph := Digraph(adj), vertlabels := labels)];
end;

#############################################################################
##
## Graph compression: replace big "futile" substructures with compact
## auxiliary-vertex gadgets that have the SAME automorphism group, so the
## engine sends and refines far fewer arcs.  This is a post-processing pass
## over any digraph we build — the graph-construction code stays oblivious.
##
## We only touch WHOLE connected components (of the underlying undirected
## graph) that are themselves a complete graph or a complete multipartite
## graph.  Working at the component level makes the choice canonical
## (components are unique) and symmetry-safe: we never pick one overlapping
## clique over another, which would break the graph's symmetry.
##
##   - clique component C (|C| >= 3): drop its |C|(|C|-1) internal arcs, add
##     one COMPRESS_CLIQUE vertex z, and an arc c -> z for each c in C.
##     Aut = Sym(C), matching the clique; |C| arcs instead of |C|(|C|-1).
##   - complete-multipartite component with parts P_1..P_t: drop its arcs,
##     add a COMPRESS_MP_PART vertex m_j per part with arcs p -> m_j, and a
##     single COMPRESS_MP_TOP vertex T with arcs m_j -> T.  Aut matches
##     (within-part Sym, equal-size parts permuted); |C|+t arcs instead of
##     |C|^2 - sum|P_j|^2.
##
## Real vertices keep colour 0; only equal-size cliques/parts share a colour
## so they stay permutable.  A component is compressed only when the gadget
## has strictly fewer arcs, so tiny cliques (K_2) and small multipartite
## graphs are left untouched.  Returns rec(graph := <Digraph>, vertlabels)
## with vertlabels omitted when nothing compressed (a plain graph on [1..n]).
##
_BTKit.COMPRESS_REAL    := 0;
_BTKit.COMPRESS_CLIQUE  := 1;
_BTKit.COMPRESS_MP_PART := 2;
_BTKit.COMPRESS_MP_TOP  := 3;

# Kill-switch (also lets us A/B the pass). When false, compressGraph is the
# identity (returns the graph unchanged on [1..n]).
_BTKit.COMPRESS_ENABLE := true;

_BTKit.compressGraph := function(D)
    local n, out, comps, comp, Cset, nbrC, v, u, symmetric, isClique,
          partOf, partsOK, parts, origE, gadgetE, t,
          newadj, labels, nextAux, changed, z, mj, T, partVerts, P, p;

    if not _BTKit.COMPRESS_ENABLE then
        return rec(graph := D);
    fi;

    n := DigraphNrVertices(D);
    out := OutNeighbours(D);
    comps := DigraphConnectedComponents(
                 DigraphSymmetricClosure(
                     DigraphRemoveLoops(DigraphMutableCopy(D)))).comps;

    newadj := List([1 .. n], v -> ShallowCopy(out[v]));
    labels := ListWithIdenticalEntries(n, _BTKit.COMPRESS_REAL);
    nextAux := n;
    changed := false;

    for comp in comps do
        if Length(comp) < 3 then continue; fi;
        Cset := Set(comp);

        # within-component out-neighbours (excluding self)
        nbrC := HashMap();
        for v in comp do
            nbrC[v] := Difference(Intersection(Set(out[v]), Cset), [v]);
        od;

        # clique/multipartite are undirected: require symmetry in-component
        symmetric := true;
        for v in comp do
            for u in nbrC[v] do
                if not (v in nbrC[u]) then symmetric := false; break; fi;
            od;
            if not symmetric then break; fi;
        od;
        if not symmetric then continue; fi;

        origE := Sum(comp, v -> Length(nbrC[v]));

        # clique: every vertex adjacent to all others in the component
        isClique := ForAll(comp, v -> Length(nbrC[v]) = Length(comp) - 1);

        if isClique then
            gadgetE := Length(comp);                 # c -> z
            if gadgetE >= origE then continue; fi;
            for v in comp do
                newadj[v] := Filtered(newadj[v], w -> not (w in Cset));
            od;
            nextAux := nextAux + 1; z := nextAux;
            newadj[z] := []; labels[z] := _BTKit.COMPRESS_CLIQUE;
            for v in comp do Add(newadj[v], z); od;
            changed := true;
            continue;
        fi;

        # complete multipartite: non-adjacency (within the component) is an
        # equivalence relation, i.e. non-adjacent vertices share a part and
        # have identical in-component neighbour sets.
        partsOK := true;
        for v in comp do
            for u in comp do
                if u <> v and not (u in nbrC[v]) then     # u, v non-adjacent
                    if nbrC[u] <> nbrC[v] then partsOK := false; break; fi;
                fi;
            od;
            if not partsOK then break; fi;
        od;
        if not partsOK then continue; fi;

        # parts = classes of "C minus my neighbours" (each contains its v)
        parts := Set(comp, v -> Difference(Cset, nbrC[v]));
        t := Length(parts);
        gadgetE := Length(comp) + t;                 # p -> m_j , m_j -> T
        if gadgetE >= origE then continue; fi;

        for v in comp do
            newadj[v] := Filtered(newadj[v], w -> not (w in Cset));
        od;
        partVerts := [];
        for P in parts do
            nextAux := nextAux + 1; mj := nextAux;
            newadj[mj] := []; labels[mj] := _BTKit.COMPRESS_MP_PART;
            Add(partVerts, mj);
            for p in P do Add(newadj[p], mj); od;
        od;
        nextAux := nextAux + 1; T := nextAux;
        newadj[T] := []; labels[T] := _BTKit.COMPRESS_MP_TOP;
        for mj in partVerts do Add(newadj[mj], T); od;
        changed := true;
    od;

    if not changed then
        return rec(graph := D);
    fi;
    return rec(graph := DigraphNC(newadj), vertlabels := labels);
end;

#############################################################################
##
## Partition a list by a key function. Returns a HashMap from key to
## sublist (in original list order). HashMap (rather than a record) so
## keys may be arbitrary immutable values — including long structured
## keys like canonical-form digraph data, which exceed GAP's 1023-char
## record-name limit when stringified.
##
_BTKit.partitionByKey := function(items, keyFunc)
    local res, item, k;
    res := HashMap();
    for item in items do
        k := keyFunc(item);
        if not (k in res) then
            res[k] := [];
        fi;
        Add(res[k], item);
    od;
    return res;
end;

#############################################################################
##
## Equivalence key for an orbital graph, used to group orbital graphs into
## families that the normaliser may permute among themselves.
##
## We compute a 1-dimensional Weisfeiler-Leman (colour-refinement) invariant
## of the digraph rather than a full canonical form. Two orbital graphs get
## the same key iff they have the same stable 1-WL colouring. This is an
## isomorphism *invariant*, not a complete isomorphism test: 1-WL can assign
## the same key to two non-isomorphic graphs (it fails to separate e.g.
## regular graphs of the same parameters). That is sound here — over-merging
## only ever lets the normaliser *attempt* to permute graphs it could not in
## fact swap, which the engine then rejects per-graph. It never excludes a
## legitimate permutation, so the normaliser stays correct. We choose 1-WL
## over a Bliss canonical form deliberately: BlissCanonicalDigraph was the
## dominant GAP-side cost on root-heavy groups (~88% of refiner time), and
## it pulls in the external Digraphs/Bliss graph tooling, which muddies
## experiments. 1-WL is O(rounds·(n+m)) with no external call.
##
_BTKit.orbitalEquivalenceKey := function(og)
    local out, inn, n, colour, sigs, distinct, rank, i,
          numColours, prevNum, rounds;

    out := OutNeighbours(og);
    inn := InNeighbours(og);
    n := Length(out);

    # Initial colour: (out-degree, in-degree). Canonicalise the labels by
    # ranking signatures in sorted order, so the integer ids are themselves
    # isomorphism-invariant (insertion order must not leak in).
    colour := List([1 .. n], i -> [Length(out[i]), Length(inn[i])]);
    distinct := SortedList(DuplicateFreeList(colour));
    rank := HashMap();
    for i in [1 .. Length(distinct)] do rank[distinct[i]] := i; od;
    colour := List(colour, c -> rank[c]);
    numColours := Length(distinct);

    # Refine: a vertex's new colour is its old colour together with the
    # sorted multisets of its out- and in-neighbour colours. Iterate until
    # the number of colour classes stops growing (the stable colouring), or
    # n rounds as a hard cap (it cannot take more than n).
    rounds := 0;
    repeat
        prevNum := numColours;
        sigs := List([1 .. n], i -> [colour[i],
                    SortedList(List(out[i], j -> colour[j])),
                    SortedList(List(inn[i], j -> colour[j]))]);
        distinct := SortedList(DuplicateFreeList(sigs));
        rank := HashMap();
        for i in [1 .. Length(distinct)] do rank[distinct[i]] := i; od;
        colour := List(sigs, s -> rank[s]);
        numColours := Length(distinct);
        rounds := rounds + 1;
    until numColours = prevNum or rounds >= n;

    # Key = histogram of the canonical stable colours. Isomorphic graphs
    # produce the identical stable colouring, hence the identical histogram.
    return Immutable(Collected(colour));
end;

#############################################################################
##
## Block systems of G on orbit `orb`, packaged with a family-equivalence
## key. Each entry is rec(graph := <digraph>, key := <block-size multiset>).
##
## The digraph for one block system is the "intra-block complete digraph"
## on [1..n]: two points have arcs both ways iff they belong to the same
## block. This encoding stays entirely on [1..n] (no aux vertices), so
## block-system graphs compose correctly with buildSetOfGraphsWidget.
## Connected components recover the blocks exactly, so no information is
## lost.
##
_BTKit.blockSystemsAsGraphs := function(G, orb, n)
    local result, blocks, b, parts, adj, p, q, blk, key;
    result := [];
    blocks := RepresentativesMinimalBlocks(G, orb);
    for b in blocks do
        parts := Orbit(G, Set(b), OnSets);
        if Length(parts) > 1 then
            adj := List([1..n], i -> []);
            for blk in parts do
                for p in blk do
                    for q in blk do
                        if p <> q then
                            Add(adj[p], q);
                        fi;
                    od;
                od;
            od;
            # Family key: (block-size, number-of-blocks).
            key := [Length(parts[1]), Length(parts)];
            Add(result, rec(graph := Digraph(adj), key := key));
        fi;
    od;
    return result;
end;

#############################################################################
##
## Generic BFS orbit traversal under a list of generating permutations.
## Returns rec(orbit, position) where:
##   orbit    — list of points in BFS-visitation order starting from `seed`,
##   position — HashMap from point to its 1-indexed position in `orbit`.
## The traversal is deterministic given (seed, gens) — same on left and right
## search sides when called with the same arguments.
##
_BTKit.bfsOrbit := function(seed, gens)
    local orbit, position, i, x, g, y;
    orbit := [seed];
    position := HashMap();
    position[seed] := 1;
    i := 1;
    while i <= Length(orbit) do
        x := orbit[i];
        for g in gens do
            y := x ^ g;
            if not (y in position) then
                Add(orbit, y);
                position[y] := Length(orbit);
            fi;
        od;
        i := i + 1;
    od;
    return rec(orbit := orbit, position := position);
end;

# Variant of bfsOrbit that also tracks, for each point, an element of
# <gens> sending the seed to that point.  treeElement[p] is a word in
# the generators such that seed ^ treeElement[p] = p.
_BTKit.bfsOrbitWithTrace := function(seed, gens)
    local orbit, position, treeElement, i, x, g, y;
    orbit := [seed];
    position := HashMap();
    position[seed] := 1;
    treeElement := HashMap();
    treeElement[seed] := ();
    i := 1;
    while i <= Length(orbit) do
        x := orbit[i];
        for g in gens do
            y := x ^ g;
            if not (y in position) then
                Add(orbit, y);
                position[y] := Length(orbit);
                treeElement[y] := treeElement[x] * g;
            fi;
        od;
        i := i + 1;
    od;
    return rec(orbit := orbit, position := position,
               treeElement := treeElement);
end;

#############################################################################
##
## Build Schreier-tree data for `group` on a regular orbit `regOrb`:
## for each point ω ∈ regOrb, the unique element of `group` sending the
## orbit-minimum to ω. Returns rec(omega1, regOrbit, regOrbitSet,
## regOrbitBFS, treeE), where:
##   omega1       — min(regOrb), the canonical base point,
##   regOrbit     — `regOrb` as a sorted list,
##   regOrbitSet  — `regOrb` as a sorted set (immutable),
##   regOrbitBFS  — orbit in BFS order from omega1 under `gens` (canonical
##                  branching order for the selector hook),
##   treeE        — HashMap from point ω ∈ regOrb to the element of
##                  `group` with omega1 ^ treeE[ω] = ω.
##
_BTKit.regularOrbitSchreierTreeData := function(group, regOrb)
    local omega1, gens, treeE, queue, x, g, y, bfs;
    omega1 := Minimum(regOrb);
    gens := GeneratorsOfGroup(group);
    treeE := HashMap();
    treeE[omega1] := ();
    queue := [omega1];
    while not IsEmpty(queue) do
        x := Remove(queue, 1);
        for g in gens do
            y := x ^ g;
            if not (y in treeE) then
                treeE[y] := treeE[x] * g;
                Add(queue, y);
            fi;
        od;
    od;
    bfs := _BTKit.bfsOrbit(omega1, gens);
    return rec(
        omega1      := omega1,
        regOrbit    := Immutable(SortedList(regOrb)),
        regOrbitSet := Immutable(Set(regOrb)),
        regOrbitBFS := Immutable(bfs.orbit),
        treeE       := treeE);
end;

_BTKit.LargestRelevantPoint := function(obj...)
    if Length(obj) = 1 then
        obj := obj[1];
    fi;
    if IsList(obj) then
        if IsEmpty(obj) then
            return 0;
        else
            return MaximumList(List(obj, _BTKit.LargestRelevantPoint));
        fi;
    elif IsPosInt(obj) or obj = 0 then
        return obj;
    elif IsInt(obj) then
        ErrorNoReturn("unexpected negative integer...");
    elif IsPermGroup(obj) or IsPerm(obj) or IsRightCoset(obj) then
        return LargestMovedPoint(obj);
    elif IsTransformation(obj) then
        return DegreeOfTransformation(obj);
    elif IsPartialPerm(obj) then
        return Maximum(DegreeOfPartialPerm(obj), CodegreeOfPartialPerm(obj));
    elif IsDigraph(obj) then
        return Maximum(DigraphVertices(obj));
    else
        # Do not recognise the type of object. Or error?
        return infinity;
    fi;
end;
