#
# Vole: Backtrack search in permutation groups with graphs
#
# This file is a script which compiles the package manual.
#
if LoadPackage("AutoDoc", "2019.09.04") = fail then
    Error("AutoDoc version 2019.09.04 or newer is required.");
fi;

AutoDoc(
    rec(
        autodoc := true,
        extract_examples := rec(
            skip_empty_in_numbering := false,
        ),
        gapdoc := rec(
            gap_root_relative_path := true,
        ),
        scaffold := rec(
            includes := [
                          "intro.xml",
                          "install.xml",
                          "_AutoDocMainFile.xml",
                          "tutorial.xml"
                        ],
            entities := rec(
                BacktrackKit      := "<Package>BacktrackKit</Package>" ,
                Digraphs          := "<Package>Digraphs</Package>" ,
                GraphBacktracking := "<Package>GraphBacktracking</Package>",
                IO                := "<Package>IO</Package>",
                QuickCheck        := "<Package>QuickCheck</Package>",
                datastructures    := "<Package>datastructures</Package>" ,
                ferret            := "<Package>ferret</Package>",
                json              := "<Package>json</Package>",
            ),
            bib := "vole.bib",
            #MainPage := false,
        ),
    )
);

QUIT;
