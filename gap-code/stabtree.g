LoadPackage("datastructures");


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
    local orbmin, orbit, o, g, gens, newconj;
    orbmin := Minimum(List(sc.orbit, x -> x^conj));
    orbit := [orbmin];
    Assert(2, not(orbmin in tree.transversal));
    tree.transversal[orbmin] := ();
    gens := List(sc.generators, x -> x^conj);
    for o in orbit do
        for g in gens do
            if not IsBound(tree.transversal[o^g]) then
                tree.transversal[o^g] := (g^-1)*tree.transversal[o];
                Assert(2, (o^g)^(tree.transversal[o^g]) = orbmin);
                Assert(2, tree.orbitmin[o^g] = orbmin);
                Add(orbit, o^g);
            fi;
        od;
    od;
    #Print(tree.base, conj, "::", sc.orbit[1]^conj, "!", ((tree.transversal[sc.orbit[1]^conj])^(conj^-1)), sc.orbit, orbit, ":", sc.orbit[1],"\n");
    newconj := conj*tree.transversal[sc.orbit[1]^conj];
    tree.children[orbmin] := _ST.makeSTfromSC(sc.stabilizer, tree.size/Size(orbit), newconj, Concatenation(tree.base, [orbmin]));
end;

_ST.makeSTfromSC := function(sc, size, conj, base)
    local tree, grp, orbits, moved, orbitmin, orbitminmap, o, i, gens;
    if not IsBound(sc.orbit) then
        Assert(2, size = 1);
        return rec(size := 1, moved := [], orbitmin := [], orbitminmap := [], orbits := [], base := base);
    fi;
    gens := List(sc.generators, x -> x^conj);
    Assert(2, ForAll(base, {b} -> ForAll(gens, {g} -> b^g=b)));
    #Print(gens,"\n");
    grp := Group(gens);
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

    tree := rec(gens := gens, moved := moved, size := size, orbitmin := orbitmin, orbitminmap := orbitminmap, orbits := orbits, transversal := [], children := [], base := base);

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
    g := Group(tree.gens);
    SetSize(g, tree.size);
    _ST.fillTree(tree, StabChain(g, points), ());
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
        newperm := perm*tree.transversal[p];
        Assert(2, OnTuples(points{[1..i]},newperm) = minlist);
        tree := tree.children[baseminpnt];
        perm := newperm;
    od;
    return rec(minimage := minlist, minperm := perm, tree := tree);
end;

StabTreeStabilizer := function(group, points)
    return _ST.MinImage(StabTree(group), points);
end;

StabTreeStabilizerOrbits := function(group, points)
    local ret;
    ret := StabTreeStabilizer(group, points);
    return OnTuplesSets(ret.tree.orbits, ret.minperm);
end;