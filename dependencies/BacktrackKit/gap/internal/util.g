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
