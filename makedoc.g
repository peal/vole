#
# Vole: Backtrack search in permutation groups with graphs
#
# This file is a script which compiles the package manual.
#
if fail = LoadPackage("AutoDoc", "2018.02.14") then
    Error("AutoDoc version 2018.02.14 or newer is required.");
fi;

AutoDoc(
    rec(
        autodoc := true,
        scaffold := rec(
            includes := [
                          "intro.xml",
                          "install.xml",
                          "_AutoDocMainFile.xml",
                          "tutorial.xml"
                        ],
            entities := rec(
                BacktrackKit := "<Package>BacktrackKit</Package>" ,
                datastructures := "<Package>datastructures</Package>" ,
                Digraphs := "<Package>Digraphs</Package>" ,
                ferret := "<Package>ferret</Package>",
                GraphBacktracking := "<Package>GraphBacktracking</Package>",
                IO := "<Package>IO</Package>",
                json := "<Package>json</Package>",
                QuickCheck := "<Package>QuickCheck</Package>",
            ),
            bib := "vole.bib",
            #MainPage := false,
        ),
    )
);

QUIT;
