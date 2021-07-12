#
# Vole: Backtrack search in permutation groups with graphs
#
# Helper functions for testing and benchmarking
#

GAPSolve :=
function(p, l)
    local c, g, lmp;
    p := Maximum(p, 1);
    g := SymmetricGroup(p);
    for c in l do
        # Unwrap a vole refiner first
        if IsRecord(c) and IsBound(c.con) then
            c := c.con;
        fi;
        
        if IsRefiner(c) then
            g := GB_SimpleSearch(PartitionStack(p), [GB_Con.InGroup(p, g), c]);
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
end);

# Check (and simply benchmark) that VoleSolve(p,false,c) and GAPSolve(p,c) agree
VoleBenchmark :=
function(p, c)
    local ret1, ret2, time1, time2;
    time1 := NanosecondsSinceEpoch();
    ret1 := Vole.FindGroup(c : conf := rec(points := p));
    time1 := NanosecondsSinceEpoch() - time1;
    time2 := NanosecondsSinceEpoch();
    ret2 := GAPSolve(p, c);
    time2 := NanosecondsSinceEpoch() - time2;
    if ret2 <> ret1 then
        Error(StringFormatted(Concatenation(
              "inconsistency between Vole and GAP! ",
              "Given args:\n{} [and false] and {},\n",
              "VoleSolve gave: {}\nGAPSolve gave:  {}\n"),
              p, c, ret1, ret2));
    fi;
    return rec(voletime := time1, gaptime := time2);
end);

# For quick mini-tests
VoleComp :=
function(p, c)
    VoleBenchmark(p, c);
    return;
end;
