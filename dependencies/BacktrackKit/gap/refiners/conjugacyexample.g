# The minimal requirements of a refiner -- give a 
# name, a 'check' function, and an empty record called 'refine'
BTKit_Refiner.MostBasicPermConjugacy := function(permL, permR)
    return Objectify(BTKitRefinerType,rec(
        name := "MostBasicPermConjugacy",
        largest_required_point := Maximum(LargestMovedPoint(permL),LargestMovedPoint(permR)),
        constraint := Constraint.Conjugate(permL, permR),
        refine := rec(
            initialise := function(ps, buildingRBase)
                return ReturnTrue;
            end
        )
    ));
end;

# Slightly cleverer refiner -- the function 'initialise' is called
# once at the start of search. It should return a function
BTKit_Refiner.BasicPermConjugacy := function(permL, permR)
    local mapToOrbitSize;

    mapToOrbitSize := function(p,n)
        local cycles, list, c, i;
        list := [];
        cycles := Cycles(p, [1..n]);
        for c in cycles do
            for i in c do
                list[i] := Size(c);
            od;
        od;
        return {x} -> list[x];
    end;

    return Objectify(BTKitRefinerType,rec(
        name := "BasicPermConjugacy",
        largest_required_point := Maximum(LargestMovedPoint(permL),LargestMovedPoint(permR)),
        constraint := Constraint.Conjugate(permL, permR),
        refine := rec(
            initialise := function(ps, buildingRBase)
                if buildingRBase then
                    return mapToOrbitSize(permL, PS_Points(ps));
                else
                    return mapToOrbitSize(permR, PS_Points(ps));
                fi;
            end)
    ));
end;

# Find the transporter of a permutation under conjugation
BTKit_Refiner.PermTransporter := function(fixedeltL, fixedeltR)
    local cyclepartL, cyclepartR,
          i, c, s, r,
          fixByFixed, pointMap, setupCycleparts;

    setupCycleparts := function(n)
        cyclepartL := [];
        for c in Cycles(fixedeltL, [1..n]) do
            s := Length(c);
            for i in c do
                cyclepartL[i] := s;
            od;
        od;

        cyclepartR := [];
        for c in Cycles(fixedeltR, [1..n]) do
            s := Length(c);
            for i in c do
                cyclepartR[i] := s;
            od;
        od;
    end;

    fixByFixed := function(pointlist, fixedElt, n)
        local part, s, p;
        part := [1..n] * 0;
        s := 1;
        for p in pointlist do
            if part[p] = 0 then
                repeat
                    part[p] := s;
                    p := p ^ fixedElt;
                    s := s + 1;
                until part[p] <> 0;
            fi;
        od;
        return part;
    end;


    r := rec(
        name := "PermTransporter",
        largest_required_point := Maximum(LargestMovedPoint(fixedeltL),LargestMovedPoint(fixedeltR)),
        constraint := Constraint.Conjugate(fixedeltL, fixedeltR),
        refine := rec(
            initialise := function(ps, buildingRBase)
                local points;
                setupCycleparts(PS_Points(ps));
                # Pass cyclepart just on the first call, for efficency
                if buildingRBase then
                    points := fixByFixed(PS_FixedPoints(ps), fixedeltL, PS_Points(ps));
                    return {x} -> [points[x], cyclepartL[x]];
                else
                    points := fixByFixed(PS_FixedPoints(ps), fixedeltR, PS_Points(ps));
                    return {x} -> [points[x], cyclepartR[x]];
                fi;
            end,
            changed := function(ps, buildingRBase)
                local points;
                if buildingRBase then
                     points := fixByFixed(PS_FixedPoints(ps), fixedeltL, PS_Points(ps));
                 else
                     points := fixByFixed(PS_FixedPoints(ps), fixedeltR, PS_Points(ps));
                 fi;
                return {x} -> points[x];
            end,
        )
    );
    return Objectify(BTKitRefinerType,r);
end;

BTKit_Refiner.PermCentralizer := function(fixedelt)
    return BTKit_Refiner.PermTransporter(fixedelt, fixedelt);
end;
