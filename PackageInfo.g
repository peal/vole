#
# Vole: Backtrack search in permutation groups with graphs
#
# This file contains package meta data. For additional information on
# the meaning and correct usage of these fields, please consult the
# manual of the "Example" package as well as the comments in its
# PackageInfo.g file.
#

_STANDREWSCS := Concatenation(["Jack Cole Building, North Haugh, ",
                               "St Andrews, Fife, KY16 9SX, Scotland"]);
SetPackageInfo( rec(

PackageName := "Vole",
Subtitle := "Backtrack search in permutation groups with graphs",
Version := "0.1.1",
Date := "14/04/2021", # dd/mm/yyyy format
License := "MPL-2.0",

Persons := [
  rec(
    FirstNames := "Mun See",
    LastName := "Chang",
    Email := "msc2@st-andrews.ac.uk",
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
    Email := "gap@wilf-wilson.net",
    IsAuthor := true,
    IsMaintainer := true,
    Institution := "University of St Andrews",
    Place := "St Andrews",
    PostalAddress := _STANDREWSCS,
  ),
  # TODO Anyone else? Did "the interns" do anything?
],

SourceRepository := rec(
    Type := "git",
    URL := "https://github.com/peal/vole",
),
IssueTrackerURL := Concatenation( ~.SourceRepository.URL, "/issues" ),
PackageWWWHome  := "https://peal.github.io/vole",
PackageInfoURL  := Concatenation( ~.PackageWWWHome, "PackageInfo.g" ),
README_URL      := Concatenation( ~.PackageWWWHome, "README.md" ),
ArchiveURL      := Concatenation( ~.SourceRepository.URL,
                                 "/releases/download/v", ~.Version,
                                 "/", ~.PackageName, "-", ~.Version ),

ArchiveFormats := ".tar.gz",

##  Status information. Currently the following cases are recognized:
##    "accepted"      for successfully refereed packages
##    "submitted"     for packages submitted for the refereeing
##    "deposited"     for packages for which the GAP developers agreed
##                    to distribute them with the core GAP system
##    "dev"           for development versions of packages
##    "other"         for all other packages
##
Status := "dev",

AbstractHTML   :=  "TODO",

PackageDoc := rec(
  BookName  := "vole",
  ArchiveURLSubset := ["doc"],
  HTMLStart := "doc/chap0.html",
  PDFFile   := "doc/manual.pdf",
  SixFile   := "doc/manual.six",
  LongTitle := "Backtrack search in permutation groups with graphs",
),

Dependencies := rec(
  GAP := ">= 4.11.0",
  # TODO Move certain bits of GraphBacktracking/BacktrackKit into this package,
  # and then those packages should require Vole
  NeededOtherPackages := [
                           [ "BacktrackKit", ">= 0.3.1" ],
                           [ "GraphBacktracking", ">= 0.3.0" ],
                           [ "Digraphs", ">= 1.1.1" ],
                           [ "datastructures", ">= 0.2.6" ],
                           [ "json", ">= 2.0.1" ],
                           [ "IO", ">= 4.7.0" ],
                           [ "ferret", ">= 1.0.2" ],    # used in tests
                           [ "QuickCheck", ">= 0.1" ],  # used in tests
                           # TODO: dependencies of dependencies? Orb...
                           # Or at least list them so it's easy to see
                         ],
  SuggestedOtherPackages := [ ],
  ExternalConditions := [ ],
),

AvailabilityTest := ReturnTrue,

TestFile := "tst/testall.g",

#Keywords := [ "TODO" ],

));


