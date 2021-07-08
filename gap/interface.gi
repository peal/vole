

Vole.FindOne := function(constraints, conf...)
    local bounds,ret;
    conf := _Vole.getConfig(conf, rec(raw := false, points := infinity));
    bounds := _Vole.getBound(constraints, conf.points);
    ret := _Vole.CosetSolve(bounds.max, constraints);
    if conf.raw then
        return ret;
    else
        if Length(ret.sol) > 0 then
            return ret.sol[1];
        else
            return fail;
        fi;
    fi;
end;

Vole.FindGroup := function(constraints, conf...)
    local bounds,ret;
    conf := _Vole.getConfig(conf, rec(raw := false, points := infinity));
    bounds := _Vole.getBound(constraints, conf.points);
    ret := _Vole.GroupSolve(bounds.max, constraints);
    if conf.raw then
        return ret;
    else
        return ret.group;
    fi;
end;

Vole.CanonicalPerm := function(G, constraints, conf...)
    local bounds,ret, max;
    conf := _Vole.getConfig(conf, rec(raw := false, points := infinity));
    bounds := _Vole.getBound(Concatenation(constraints, [G]), conf.points);
    ret := _Vole.CanonicalSolve(bounds.max, G, constraints);
    if conf.raw then
        return ret;
    else
        return ret.canonical;
    fi;
end;
