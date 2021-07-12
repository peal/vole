# Vole: Backtrack search in permutation groups with graphs
# A GAP package by Mun See Chang, Christopher Jefferson, and Wilf A. Wilson.
#
# SPDX-License-Identifier: MPL-2.0
#
# This file is a script which compiles the package manual.

if LoadPackage("AutoDoc", "2019.09.04") = fail then
    ErrorNoReturn("AutoDoc version 2019.09.04 or newer is required to compile ",
                  "the manual.");
fi;

AutoDoc(
    rec(
        autodoc := rec(
            files := [
                       "doc/intro.autodoc",
                       "doc/install.autodoc",
                       "doc/tutorial.autodoc",
                       "gap/wrapper.gd",
                       "gap/interface.gd",
                       "gap/constraints.gd",
                       "gap/refiners.gd",
                       "doc/expert.autodoc",
                     ],
            scan_dirs := [
                           "doc",
                           "gap",
                         ],
        ),
        extract_examples := false,
        #extract_examples := rec(
        #    skip_empty_in_numbering := false,
        #),
        gapdoc := rec(
            gap_root_relative_path := true,
        ),
        scaffold := rec(
            appendix := [
                        ],
            includes := [
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
            index := true,
            MainPage := true,
        ),
    )
);

QUIT;
