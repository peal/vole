GB_RefinerFromConstraint := function(con)
    local action, source, result;

    if HasIsEmptyConstraint(con) and IsEmptyConstraint(con) then
        return BTKit_Refiner.Nothing();

    # TODO Deal properly with InSymmetricGroup

    elif IsInCosetByGensConstraint(con) then
        return GB_Con.InCoset(UnderlyingGroup(con), Representative(con));

    elif IsTransporterConstraint(con) then
        action := ActionFunc(con);
        source := SourceObject(con);
        result := ResultObject(con);

        # TODO Should have a digraph transporter refiner

        if action = OnPoints and IsPerm(source) then
            return GB_Con.PermConjugacy(source, result);

        elif action = OnTuples and ForAll(source, IsPerm) then
            return List([1 .. Length(source)], i -> GB_Con.PermConjugacy(source[i], result[i]));

        elif action = OnPoints and IsPermGroup(source) then
            return GB_Con.GroupConjugacySimple2(source, result);

        elif action = OnSetsDigraphs and ForAll(source, IsDigraph) then
            return GB_Con.SetDigraphs(source, result);

        fi;

    fi;

    return BTKit_RefinerFromConstraint(con);
end;
