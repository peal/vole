LoadPackage("vole", false);
LoadPackage("quickcheck", false);
LoadPackage("ferret", false);

_Vole.LoadFullDependencies();

VoleTestCanonical := function(grp, obj, VoleFunc, action)
    local p, newobj, ret, newret, image, newimage;
    p := Random(grp);
    newobj := action(obj, p);
    ret := VoleFind.CanonicalPerm(grp, Flat([VoleFunc(obj)]));
    if not(ret in grp) then
        return StringFormatted("A - Not in group! {} {} {}", grp, obj, ret);
    fi;
    newret := VoleFind.CanonicalPerm(grp, Flat([VoleFunc(newobj)]));
    if not(newret in grp) then
        return StringFormatted("B - Not in group! {} {} {}", grp, obj, ret);
    fi;

    image := action(obj, ret);
    newimage := action(newobj, newret);
    if image <> newimage then
        return StringFormatted("C - unequal canonical {} {} ({} {} {}) ({} {} {})", grp, p, obj, ret, image, newobj, newret, newimage);
    fi;
    return true;
end;

FerretSolve := function(p, l)
    local c, g, lmp;
    p := Maximum(p, 1);
    g := SymmetricGroup(p);
    for c in l do
        if IsConstraint(c) then
            c := VoleRefiner.FromConstraint(c);
        fi;

        # Unwrap a vole refiner first
        if IsVoleRefiner(c) and IsBound(c!.con) then
            c := c!.con;
        fi;
        if IsBTKitRefiner(c) or IsGBRefiner(c) then
            g := GB_SimpleSearch(PartitionStack(p), [GB_Con.InGroup(g), c]);
        elif IsBound(c.SetStab) then
            g := Solve([ConInGroup(g), ConStabilize(c.SetStab.points, OnSets)]);
        elif IsBound(c.TupleStab) then
            g := Solve([ConInGroup(g), ConStabilize(c.TupleStab.points, OnTuples)]);
        elif IsBound(c.SetSetStab) then
            g := Solve([ConInGroup(g), ConStabilize(c.SetSetStab.points, OnSetsSets)]);
        elif IsBound(c.SetTupleStab) then
            g := Solve([ConInGroup(g), ConStabilize(c.SetTupleStab.points, OnSetsTuples)]);
        elif IsBound(c.DigraphStab) then
            if MovedPoints(g) = [1 .. p] and IsNaturalSymmetricGroup(g) then
                g := AutomorphismGroup(Digraph(c.DigraphStab.edges));
            else
                g := Intersection(g, AutomorphismGroup(Digraph(c.DigraphStab.edges)));
            fi;
        else
            Error("Unknown constraint for ferret: ", c);
        fi;
    od;
    return g;
end;

# For use with QuickCheck
QuickChecker := function(p, c)
    local ret1, ret2;
    ret1 := VoleFind.Group(c : points := p);
    ret2 := FerretSolve(p, c);
    return ret2 = ret1;
end;


GAPSolve :=
function(p, l)
    local c, g, lmp;
    p := Maximum(p, 1);
    g := SymmetricGroup(p);
    for c in l do
        if IsConstraint(c) then
            c := VoleRefiner.FromConstraint(c);
        fi;

        # Unwrap a vole refiner first
        if IsVoleRefiner(c) and IsBound(c!.con) then
            c := c!.con;
        fi;

        if IsBTKitRefiner(c) or IsGBRefiner(c) then
            g := GB_SimpleSearch(PartitionStack(p), [GB_Con.InGroup(g), c]);
        elif IsBound(c.SetStab) then
            g := Stabilizer(g, c.SetStab.points, OnSets);
        elif IsBound(c.TupleStab) then
            g := Stabilizer(g, c.TupleStab.points, OnTuples);
        elif IsBound(c.SetSetStab) then
            g := Stabilizer(g, c.SetSetStab.points, OnSetsSets);
        elif IsBound(c.SetTupleStab) then
            g := Stabilizer(g, c.SetTupleStab.points, OnSetsTuples);
        elif IsBound(c.DigraphStab) then
            if MovedPoints(g) = [1 .. p] and IsNaturalSymmetricGroup(g) then
                g := AutomorphismGroup(Digraph(c.DigraphStab.edges));
            else
                g := Intersection(g, AutomorphismGroup(Digraph(c.DigraphStab.edges)));
            fi;
        else
            Error("Unknown constraint: ", c);
        fi;
    od;
    return g;
end;

# Check (and simply benchmark) that VoleFind.Group(p,c) and GAPSolve(p,c) agree
VoleBenchmark :=
function(p, c)
    local ret1, ret2, time1, time2;
    time1 := NanosecondsSinceEpoch();
    ret1  := VoleFind.Group(p, c);
    time1 := NanosecondsSinceEpoch() - time1;
    time2 := NanosecondsSinceEpoch();
    ret2  := GAPSolve(p, c);
    time2 := NanosecondsSinceEpoch() - time2;
    if ret2 <> ret1 then
        Error(StringFormatted(Concatenation(
              "inconsistency between Vole and GAP! ",
              "Given args:\n{} [and false] and {},\n",
              "VoleSolve gave: {}\nGAPSolve gave:  {}\n"),
              p, c, ret1, ret2));
    fi;
    return rec(voletime := time1, gaptime := time2);
end;

# For quick mini-tests
VoleComp :=
function(p, c)
    VoleBenchmark(p, c);
    return;
end;
