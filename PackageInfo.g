# Vole: Backtrack search in permutation groups with graphs
# A GAP package by Mun See Chang, Christopher Jefferson, and Wilf A. Wilson.
#
# SPDX-License-Identifier: MPL-2.0

_STANDREWSCS := Concatenation("School of Computer Science, ",
                              "University of St Andrews, ",
                              "St Andrews, Fife, KY16 9SX, Scotland");
SetPackageInfo( rec(

PackageName := "Vole",
Subtitle := "Vole organises lengthy explorations: Backtrack search in permutation groups with graphs",
Version := "0.5.3",
Date := "21/12/2021", # dd/mm/yyyy format
License := "MPL-2.0",

Persons := [
  rec(
    FirstNames := "Mun See",
    LastName := "Chang",
    Email := "msc2@st-andrews.ac.uk",
    GitHubUsername := "Munsee",
    IsAuthor := true,
    IsMaintainer := false,
    Institution := "University of St Andrews",
    Place := "St Andrews",
    PostalAddress := _STANDREWSCS,
  ),
  rec(
    FirstNames := "Christopher",
    LastName := "Jefferson",
    WWWHome := "https://caj.host.cs.st-andrews.ac.uk",
    Email := "caj21@st-andrews.ac.uk",
    GitHubUsername := "ChrisJefferson",
    IsAuthor := true,
    IsMaintainer := true,
    Institution := "University of St Andrews",
    Place := "St Andrews",
    PostalAddress := _STANDREWSCS,
  ),
  rec(
    FirstNames := "Wilf A.",
    LastName := "Wilson",
    WWWHome := "https://wilf.me",
    GitHubUsername := "wilfwilson",
    Email := "gap@wilf-wilson.net",
    IsAuthor := true,
    IsMaintainer := true,
    Institution := "University of St Andrews",
    Place := "St Andrews",
    PostalAddress := _STANDREWSCS,
  ),
],

SourceRepository := rec(
    Type := "git",
    URL := "https://github.com/peal/vole",
),
IssueTrackerURL := Concatenation( ~.SourceRepository.URL, "/issues" ),
PackageWWWHome  := "https://peal.github.io/vole",
PackageInfoURL  := Concatenation( ~.PackageWWWHome, "/PackageInfo.g" ),
README_URL      := Concatenation( ~.PackageWWWHome, "/README.md" ),
ArchiveURL      := Concatenation( ~.SourceRepository.URL,
                                 "/releases/download/v", ~.Version,
                                 "/", LowercaseString(~.PackageName), "-", ~.Version ),

ArchiveFormats := ".tar.gz",

Status := "dev",

AbstractHTML := """
<B>Vole</B> is a <B>GAP</B> package that implements algorithms in
finite permutation groups, such as canonical images, stabilisers, and
subgroup intersection. These are all implemented as part of the general
'graph backtracking' framework.""",

PackageDoc := rec(
  BookName  := ~.PackageName,
  ArchiveURLSubset := ["doc"],
  HTMLStart := "doc/chap0_mj.html",
  PDFFile   := "doc/manual.pdf",
  SixFile   := "doc/manual.six",
  LongTitle := ~.Subtitle,
),

Dependencies := rec(
  GAP := ">= 4.13.0",
  NeededOtherPackages := [
    [ "Digraphs", ">= 1.1.1" ],
    # to enable GAP and rust to talk to each other
    [ "IO", ">= 4.7.0" ],
    [ "json", ">= 2.0.1" ],
    # required by BacktrackKit and Digraphs... so we may as well include it?
    [ "datastructures", ">= 0.2.6" ],
    ["images", ">=1.3.0"],   # For MinimalImagePerm
    ["primgrp", ">=3.4.0" ],
  ], # For the tests  ],
  SuggestedOtherPackages := [
    [ "AutoDoc", ">= 2019.09.04" ], # to compile documentation
    [ "ferret", ">= 1.0.2" ],       # used in tests
    [ "QuickCheck", ">= 0.1" ],     # used in tests
    [ "OrbitalGraphs", ">= 0.1" ],  # for Vole.TwoClosure
  ],
  ExternalConditions := [
    "To compile Vole, Rust needs to be installed and available.",
  ],
),

AvailabilityTest := function()
  local dirs;
  dirs := DirectoriesPackageLibrary("vole", "rust/target/release");
  if not (Length(dirs) >= 1 and ForAny(["vole", "vole.exe"], f -> f in DirectoryContents(dirs[1])) ) then
    LogPackageLoadingMessage(PACKAGE_WARNING,
      "Vole package is not compiled; please run `make` in the Vole directory");
    return fail;
  fi;
  return true;
end,

TestFile := "tst/testall.g",

Keywords := [
    "permutation group", "backtrack", "search", "backtracking", "graph",
    "digraph", "normaliser", "normalizer", "stabiliser", "stabilizer",
    "group", "subgroup", "intersection", "conjugacy", "coset", "transporter",
],

AutoDoc := rec(
   TitlePage := rec(
    Copyright := Concatenation(
      "&copyright; &VoleYear; by Christopher Jefferson, Mun See Chang, ",
      "and Wilf A. Wilson.",
      "<P/>",
      "&Vole; is licensed under the Mozilla Public License, version 2.0."
      ),
    Abstract := ~.AbstractHTML,
    Acknowledgements := Concatenation(
      "The authors would like to thank the ",
      "<URL><LinkText>Royal Society</LinkText>",
      "<Link>https://royalsociety.org</Link></URL> ",
      "(grant codes <B>RGF\\EA\\181005</B> and <B>URF\\R\\180015</B>) ",
      "for their financial support at the time that &Vole; was created."
    )
   )
),

));
