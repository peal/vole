VoleTestCanonical := function(maxpnt, grp, obj, VoleFunc, action)
    local p, newobj, ret, newret, image, newimage;
    p := Random(grp);
    newobj := action(obj, p);
    ret := VoleCanonicalSolve(maxpnt, grp, Flat([VoleFunc(obj)]));
    if not(ret.canonical in grp) then
        return StringFormatted("A -Not in group! {} {} {}", grp, obj, ret.canonical);
    fi;
    newret := VoleCanonicalSolve(maxpnt, grp, Flat([VoleFunc(newobj)]));
    if not(newret.canonical in grp) then
        return StringFormatted("B - Not in group! {} {} {}", grp, obj, ret);
    fi;
    
    image := action(obj, ret.canonical);
    newimage := action(newobj, newret.canonical);
    if image <> newimage then
        return StringFormatted("C - unequal canonical {} {} ({} {} {}) ({} {} {})", grp, p, obj, ret.canonical, image, newobj, newret.canonical, newimage);
    fi;
    return true;
end;
