# The following series of refiners are based on Leon's normaliser refiners,
# but they do not implement all features (in particular, any parts which look
# at the base points of the group).

# The minimal requirements of a refiner -- give a 
# name, a 'check' function, and an empty record called 'refine'
BTKit_Refiner.MostBasicGroupConjugacy := function(grpL, grpR)
    return Objectify(BTKitRefinerType, rec(
        name := "MostBasicGroupPermConjugacy",
        largest_required_point := Maximum(LargestMovedPoint(grpL), LargestMovedPoint(grpR)),
        constraint := Constraint.Conjugate(grpL, grpR),
        refine := rec(
                initialise := function(ps, buildingRBase)
                    return ReturnTrue;
                end)
    ));
end;

# Slightly cleverer refiner -- the function 'initialise' is called
# once at the start of search. It should return a function
BTKit_Refiner.BasicGroupConjugacy := function(grpL, grpR)
    local mapToOrbitSize;

    mapToOrbitSize := function(g,n)
        local orbs, list, o, i;
        list := [];
        orbs := Orbits(g, [1..n]);
        for o in orbs do
            for i in o do
                list[i] := Size(o);
            od;
        od;
        return {x} -> list[x];
    end;

    return Objectify(BTKitRefinerType,rec(
        name := "BasicGroupConjugacy",
        largest_required_point := Maximum(LargestMovedPoint(grpL), LargestMovedPoint(grpR)),
        constraint := Constraint.Conjugate(grpL, grpR),
        refine := rec(
            initialise := function(ps, buildingRBase)
                if buildingRBase then
                    return mapToOrbitSize(grpL, PS_Points(ps));
                else
                    return mapToOrbitSize(grpR, PS_Points(ps));
                fi;
            end)
    ));
end;

# Even more slightly clever refiner -- now refine at every depth.
BTKit_Refiner.SimpleGroupConjugacy := function(grpL, grpR)
    local mapToOrbitSize;

    mapToOrbitSize := function(g,n)
        local orbs, list, o, i;
        list := [];
        orbs := Orbits(g, [1..n]);
        for o in orbs do
            for i in o do
                list[i] := Size(o);
            od;
        od;
        return {x} -> list[x];
    end;

    return Objectify(BTKitRefinerType,rec(
        name := "BasicGroupConjugacy",
        largest_required_point := Maximum(LargestMovedPoint(grpL), LargestMovedPoint(grpR)),
        constraint := Constraint.Conjugate(grpL, grpR),
        refine := rec(
            initialise := function(ps, buildingRBase)
                if buildingRBase then
                    return mapToOrbitSize(grpL, PS_Points(ps));
                else
                    return mapToOrbitSize(grpR, PS_Points(ps));
                fi;
            end,
            changed := function(ps, buildingRBase)
                local fixed, grp, ret;
                fixed := PS_FixedPoints(ps);
                if buildingRBase then
                    grp := grpL;
                else
                    grp := grpR;
                fi;

                ret := List([1..Length(fixed)], x -> mapToOrbitSize(Stabilizer(grp, fixed{[1..x]}, OnTuples), PS_Points(ps)));
                return {x} -> List(ret, func -> func(x));
            end)
    ));
end;


BTKit_Refiner.GroupNormaliser := function(grp)
    return BTKit_Refiner.SimpleGroupConjugacy(grp, grp);
end;
