       
BindGlobal("VoleCon",
rec());

VoleCon.Stabilize := function(s, action...)
    if Length(action) = 1 then
        action := action[1];
    elif Length(action) = 0 then
        action := OnPoints;
    else
        ErrorNoReturn("VoleCon.Stabilizer args: obj [, action]");
    fi;

    if action = OnSets then
        return VoleRefiner.SetStab(s);
    elif action = OnTuples then
        return VoleRefiner.TupleStab(s);
    elif action = OnSetsSets then 
        return VoleRefiner.SetSetStab(s);
    elif action = OnSetsTuples then
        return VoleRefiner.SetTupleStab(s);
    elif action = OnDigraphs then
        return VoleRefiner.DigraphStab(s);
    else
        ErrorNoReturn("Invalid action: ", action);
    fi;
end;

VoleCon.Transport := function(s, t, action...)
    if Length(action) = 1 then
        action := action[1];
    elif Length(action) = 0 then
        action := OnPoints;
    else
        ErrorNoReturn("VoleCon.Transport args: obj1, obj2 [, action]");
    fi;

    if action = OnSets then
        return VoleRefiner.SetTransporter(s,t);
    elif action = OnTuples then
        return VoleRefiner.TupleTransporter(s,t);
    elif action = OnSetsSets then 
        return VoleRefiner.SetSetTransporter(s,t);
    elif action = OnTuples then
        return VoleRefiner.SetTupleTransporter(s,t);
    elif action = OnDigraphs then
        return VoleRefiner.DigraphTransporter(s,t);
    else
        ErrorNoReturn("Invalid action: ", action);
    fi;
end;


VoleCon.InGroup := function(g)
    return rec(bounds := rec(largest_required_point :=_Vole.lmp(g), largest_moved_point := _Vole.lmp(g), con := GB_Con.InGroupSimple(g)));
end;
