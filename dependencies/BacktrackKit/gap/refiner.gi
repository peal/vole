#
# BacktrackKit: An extensible, easy to understand backtracking framework
#
# Methods for refiner objects
#

InstallMethod(SaveState, [IsBTKitRefiner],
    function(con)
        if IsBound(con!.btdata) then
            return StructuralCopy(con!.btdata);
        else
            return fail;
        fi;
    end);

InstallMethod(RestoreState, [IsBTKitRefiner, IsObject],
    function(con, state)
        if state <> fail then
            con!.btdata := StructuralCopy(state);
        fi;
    end);

InstallMethod(DummyRefiner,
    "for a constraint object", [IsConstraint],
    {con} -> Objectify(
        BTKitRefinerType,
        rec(
            name := Concatenation("Dummy refiner for ", Name(con)),
            largest_required_point := LargestRelevantPoint(con),
            constraint := con,
            refine := rec(
                initialise := function(ps, buildingRBase)
                    return {x} -> 1;
                end)
        )
    )
);

InstallGlobalFunction(BTKit_RefinerFromConstraint,
function(con)
    local action, source, result;

    if HasIsEmptyConstraint(con) and IsEmptyConstraint(con) then
        return BTKit_Refiner.Nothing();
    elif con = Constraint.IsEven then
        return BTKit_Refiner.IsEven();
    elif con = Constraint.IsOdd then
        return BTKit_Refiner.IsOdd();

    # TODO Make an "in symmetric group" BTKit refiner

    # TODO review this: maybe we want the orbitals one as the default?
    elif IsInCosetByGensConstraint(con) then
        return BTKit_Refiner.InCoset(UnderlyingGroup(con), Representative(con));
    
    elif IsTransporterConstraint(con) then
        action := ActionFunc(con);
        source := SourceObject(con);
        result := ResultObject(con);

        if action = OnPoints and IsPosInt(source) then
            if IsStabiliserConstraint(con) then
                return BTKit_Refiner.TupleStab([source]);
            else
                return BTKit_Refiner.TupleTransporter([source], [result]);
            fi;

        elif action = OnTuples and ForAll(source, IsPosInt) then
            if IsStabiliserConstraint(con) then
                return BTKit_Refiner.TupleStab(source);
            else
                return BTKit_Refiner.TupleTransporter(source, result);
            fi;

        elif action = OnSets and ForAll(source, IsPosInt) then
            if IsStabiliserConstraint(con) then 
                return BTKit_Refiner.SetStab(source);
            else
                return BTKit_Refiner.SetTransporter(source, result);
            fi;

        elif action = OnPoints and IsPerm(source) then
            return BTKit_Refiner.PermTransporter(source, result);

        elif action = OnPoints and IsPermGroup(source) then
            return BTKit_Refiner.SimpleGroupConjugacy(source, result);

        elif action = OnDigraphs and IsDigraph(source) then
            return BTKit_Refiner.GraphTrans(source, result);

        fi;
    fi;

    # TODO: Give a severe warning!
    return DummyRefiner(con);
end);
