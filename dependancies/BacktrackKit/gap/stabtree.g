### STABILISER TREES
# A stabiliser tree represents many different stabiliser chains for a group, represented as a tree.
# The way they are stored makes several operations very cheap (hopefully), currently:
#
# For a group G and tuple T:
# * MinimalImage(G, T, OnTuples)
# * Stabilizer(G,T,OnTuples)
# * The orbits of Stabilizer(G,T,OnTuples), given as a tuple of sets, such that@
# * Orbits(G,T,OnTuples)^g = Orbits(G,T^g,OnTuples), for g in G.
#
# Stabilizer Trees are always stored by, at each level, taking the smallest point
# in each orbit and stabilizing it -- stabilizer chains for other points in the orbit
# can be reached by conjugating these stabilizer chains. New levels are created on
# demand.
#
# USAGE:
#
# The main function is StabTreeStabilizer(G,T) for a group G and tuple T.
#
# This returns a record containing:
# 
# minimage: The minimum image of T under G.
# minperm: The permutation which maps T to it's minimum image under G
# tree: The stabilizer tree for Stabilizer(G,T^minperm).
# This stabilizer tree contains:
#
# gens: Generators for this group
# base: The base up to this level
# moved: Moved points for this group
# size: Size of the group
# orbits: The orbits (as a set of sets)
# transversal: A transversal
# orbitmin: A map from each moved point to the smallest point in it's orbit
# orbitminmap: A map from each moved point to it's orbit
# children: The (currently known) subgroups -- there will (possibly) be one
#           for each smallest point in an orbit.
# Call "StabTree(G)" to get a stabilizer tree for a group G

_ST := rec();

if not IsBound(InfoST) then
    InfoST := NewInfoClass("InfoST");
fi;


_ST.fillTree := function(tree, sc, conj)
    local orbmin, orbit, o, g, gens, newconj, depthlist, depth;
    orbmin := Minimum(List(sc.orbit, x -> x^conj));
    orbit := [orbmin];
    Assert(2, not(orbmin in tree.transversal));
    tree.transversal[orbmin] := ();
    gens := List(sc.generators, x -> x^conj);
    depthlist := [];
    depthlist[orbmin] := 0;
    for o in orbit do
        for g in gens do
            if not IsBound(tree.transversal[o^g]) then
                # Limit depth getting too deep
                if depthlist[o] > 1 + Log2Int(Length(orbit)) then
                    tree.transversal[o] := _ST.getBasePerm(tree, o);
                    depthlist[o] := 0;
                    Add(gens, tree.transversal[o]);
                fi;
                depthlist[o^g] := depthlist[o] + 1;

                tree.transversal[o^g] := (g^-1);#(g^-1)*tree.transversal[o];
#                Assert(2, (o^g)^(tree.transversal[o^g]) = orbmin);
#                Assert(2, tree.orbitmin[o^g] = orbmin);
                Add(orbit, o^g);
            fi;
        od;
    od;
    #Print(tree.base, conj, "::", sc.orbit[1]^conj, "!", ((tree.transversal[sc.orbit[1]^conj])^(conj^-1)), sc.orbit, orbit, ":", sc.orbit[1],"\n");
    newconj := conj*_ST.getBasePerm(tree, sc.orbit[1]^conj);
    tree.children[orbmin] := _ST.makeSTfromSC(sc.stabilizer, tree.size/Size(orbit), newconj, Concatenation(tree.base, [orbmin]));
end;


_ST.getBasePerm := function(sc, point)
    local minval, perm;
    minval := sc.orbitmin[point];
    perm := sc.transversal[point];
    while point^perm <> minval do
        perm :=  perm * sc.transversal[point^perm];
    od;
    # If we make a new perm, fill it in
    sc.transversal[point] := perm;
    return perm;
end;

_ST.makeSTfromSC := function(sc, size, conj, base)
    local tree, grp, orbits, moved, orbitmin, orbitminmap, o, i, gens;
    if not IsBound(sc.orbit) then
        Assert(2, size = 1);
        return rec(gens := [()], group := Group([()]), size := 1, moved := [], orbitmin := [], orbitminmap := [], orbits := [], base := base);
    fi;
    gens := List(sc.generators, x -> x^conj);
    if IsEmpty(gens) then
        gens := [()];
    fi;
    Assert(2, ForAll(base, {b} -> ForAll(gens, {g} -> b^g=b)));
    #Print(gens,"\n");
    grp := Group(gens);
    SetSize(grp, size);
    orbits := Set(Orbits(grp), Set);
    moved := Immutable(Set(Flat(orbits)));

    orbitmin := HashMap();
    orbitminmap := HashMap();
    for o in orbits do
        for i in o do
            orbitminmap[i] := o;
            orbitmin[i] := o[1];
        od;
    od;

    tree := rec(group := grp, gens := gens, moved := moved, size := size, orbitmin := orbitmin, orbitminmap := orbitminmap, orbits := orbits, transversal := [], children := [], base := base);

    _ST.fillTree(tree, sc, conj);
    return tree;
end;


StabTree := function(group)
    if not IsBound(group!.stabTree) then
        group!.stabTree := _ST.makeSTfromSC(StabChainMutable(group), Size(group), (), []);
    fi;
    return group!.stabTree;
end;

_fillTreeFromPoints := function(tree, points)
    local g;
    _ST.fillTree(tree, StabChain(tree.group, points), ());
end;

_ST.MinImage := function(tree, points)
    local i,p, perm, minpnt, minlist, baseminpnt, newperm;
    perm := ();
    minlist := [];
    for i in [1..Length(points)] do
        p := points[i]^perm;
        Info(InfoST, 2, "Considering ", points{[1..i]}, " as ", OnTuples(points{[1..i]}, perm), " via ", perm);
        # Skip point if not moved
        if not(p in tree.moved) then
            Info(InfoST, 2, "Fixed point: ", p);
            Add(minlist, p);
            Assert(2, OnTuples(points{[1..i]},perm) = minlist);
            continue;
        fi;
        baseminpnt := tree.orbitmin[p];
        Info(InfoST, 2, "New minimal image: ", baseminpnt);
        Add(minlist,baseminpnt);
        
        if not IsBound(tree.transversal[p]) then
            _fillTreeFromPoints(tree, OnTuples(points{[i..Length(points)]}, perm));
        fi;
        newperm := perm*_ST.getBasePerm(tree, p);
        Assert(2, OnTuples(points{[1..i]},newperm) = minlist);
        tree := tree.children[baseminpnt];
        perm := newperm;
    od;
    return rec(minimage := minlist, minperm := perm, tree := tree);
end;

StabTreeStabilizer := function(group, points)
    return _ST.MinImage(StabTree(group), points);
end;

StabTreeStabilizerOrbits := function(group, points, omega)
    local ret, fixpnts;
    ret := StabTreeStabilizer(group, points);
    fixpnts := Difference(omega, Flat(ret.tree.orbits));
    Sort(fixpnts);
    fixpnts := List(fixpnts, x -> [x]);
    return OnTuplesSets(Concatenation(ret.tree.orbits, fixpnts), ret.minperm^-1);
end;




# Options: rec(skipOneLarge := false, cutoff := false, maxval := false)
StabTreeStabilizerOrbitalGraphs := function(group, points, options...)
    local ret, fixpnts, g, ondigraphs_extraverts, graphs, retval;
    ret := StabTreeStabilizer(group, points);
    options := _BTKit.orbitalOptions(options);
    if not IsBound(ret.tree.reducedOrbitals) then
        ret.tree.reducedOrbitals := HashMap();
    fi;

    if not (options in ret.tree.reducedOrbitals) then
        ret.tree.reducedOrbitals[options] :=  _BTKit.getOrbitalListWithOptions(ret.tree.group, options);
    fi;

    retval := ret.tree.reducedOrbitals[options];

    #ondigraphs_extraverts := function(g,p)
    #    if Size(DigraphVertices(g)) < LargestMovedPoint(p) then
    #        g := DigraphAddVertices(g, LargestMovedPoint(p) - DigraphVertices(g));
    #    fi;
    #    return OnDigraphs(g,p);
    #end;
    graphs := List(retval, g -> OnDigraphs(g, ret.minperm^-1));
    Assert(5, ForAll(graphs, graph -> ForAll(GeneratorsOfGroup(Stabilizer(group, points, OnTuples)), p -> OnDigraphs(graph,p) = graph)));
    return graphs;
end;

StabTreeStabilizerReducedOrbitalGraphs := function(group, points, omega)
    return StabTreeStabilizerOrbitalGraphs(group, points, rec(maxval := Maximum(omega), skipOneLarge := true));
end;