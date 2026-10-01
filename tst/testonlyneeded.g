# Run in a fresh GAP session so suggested packages have not already been loaded.
if LoadPackage("vole" : OnlyNeeded) <> true then
    FORCE_QUIT_GAP(1);
fi;

# Exercise both bundled backtracking dependencies without optional packages.
if Vole.Stabiliser(SymmetricGroup(5), [1, 2], OnSets)
        <> Stabilizer(SymmetricGroup(5), [1, 2], OnSets) then
    FORCE_QUIT_GAP(1);
fi;
if Vole.Stabiliser(AlternatingGroup(5), CycleDigraph(5), OnDigraphs)
        <> Group((1, 2, 3, 4, 5)) then
    FORCE_QUIT_GAP(1);
fi;

FORCE_QUIT_GAP(0);
