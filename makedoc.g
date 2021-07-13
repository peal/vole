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

# TODO make more robust
_voleinfo := PackageInfo("vole")[1];
_strip := function(str)
  str := ReplacedString(str, ">=", "");
  str := ReplacedString(str, " ", "");
  return str;
end;

_autodoc := rec(
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
            images            := "<Package>images</Package>",
            VoleVersion       := _strip(_voleinfo.Version),
            GAPVersion        := _strip(_voleinfo.Dependencies.GAP),
        ),
        bib := "vole.bib",
        index := true,
        MainPage := true,
    ),
);

_entities := _autodoc.scaffold.entities;
# TODO could extract the dependency URLs too from their own packageinfos
for _dep in Concatenation(_voleinfo.Dependencies.NeededOtherPackages,
                          _voleinfo.Dependencies.SuggestedOtherPackages) do
    _name := Concatenation(_dep[1], "Version");
    _entities.(_name) := _strip(_dep[2]);
    _entities.(_dep[1]) := StringFormatted("<Package>{}</Package>", _dep[1]);
od;

AutoDoc(_autodoc);

QUIT;
