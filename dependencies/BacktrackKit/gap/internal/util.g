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
## Partition a list by a key function. Returns a record whose names are
## stringified keys and whose values are the corresponding sublists, in
## original list order.
##
_BTKit.partitionByKey := function(items, keyFunc)
    local res, item, k, name;
    res := rec();
    for item in items do
        k := keyFunc(item);
        if IsString(k) then
            name := k;
        else
            name := String(k);
        fi;
        if not IsBound(res.(name)) then
            res.(name) := [];
        fi;
        Add(res.(name), item);
    od;
    return res;
end;

#############################################################################
##
## Equivalence key for an orbital graph, used to group orbital graphs into
## families that the normaliser may permute among themselves.
##
## Phase-A: use the multiset of out-degrees (a coarse but sound invariant).
## Orbital graphs of a transitive group are arc-transitive on their support
## orbit, so vertices in the support all share the same out-degree (the
## valence); vertices outside have out-degree 0. Two orbital graphs with
## different valences cannot be permuted into each other by Sym(Ω).
##
## This can be tightened in Phase B with canonical-form hashing.
##
_BTKit.orbitalEquivalenceKey := function(og)
    # Canonical-form key via Bliss. Two orbital graphs go into the same
    # family iff they are isomorphic as digraphs on Ω — exactly the
    # equivalence class that the normaliser can permute among itself.
    #
    # IMPORTANT: BlissCanonicalDigraph returns a digraph whose edge SET
    # is canonical, but the adjacency lists are stored in arbitrary
    # order. Two equal digraphs may stringify differently. To produce
    # a deterministic key we serialise the sorted out-neighbour list.
    local canon, neighbours;
    canon := BlissCanonicalDigraph(og);
    neighbours := OutNeighbours(canon);
    return String(List(neighbours, Set));
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
