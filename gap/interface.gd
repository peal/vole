Vole.FindGroup := function(refiners)
    ret := VoleGroupSolve(100, refiners)
    return ret.group;
end;

Vole.FindOne := function(refiners)
    ret := VoleCosetSolve(100, refiners)
    return ret.perm;
end;