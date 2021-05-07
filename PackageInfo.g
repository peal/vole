#
# Vole: Backtrack search in permutation groups with graphs

_STANDREWSCS := Concatenation("School of Computer Science, ",
                              "University of St Andrews, ",
                              "St Andrews, Fife, KY16 9SX, Scotland");
SetPackageInfo( rec(

PackageName := "Vole",
Subtitle := "Backtrack search in permutation groups with graphs",
Version := "0.4.0",
Date := "07/05/2021", # dd/mm/yyyy format
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

AbstractHTML :=  "TODO",

PackageDoc := rec(
  BookName  := ~.PackageName,
  ArchiveURLSubset := ["doc"],
  HTMLStart := "doc/chap0.html",
  PDFFile   := "doc/manual.pdf",
  SixFile   := "doc/manual.six",
  LongTitle := ~.Subtitle,
),

Dependencies := rec(
  GAP := ">= 4.11.0",
  NeededOtherPackages := [
                           [ "BacktrackKit", ">= 0.4.0" ],
                           [ "GraphBacktracking", ">= 0.4.0" ],
                           [ "Digraphs", ">= 1.1.1" ],
                           [ "datastructures", ">= 0.2.6" ],
                           [ "json", ">= 2.0.1" ],
                           [ "IO", ">= 4.7.0" ],
                           [ "ferret", ">= 1.0.2" ],    # used in tests
                           [ "QuickCheck", ">= 0.1" ],  # used in tests
                         ],
  SuggestedOtherPackages := [ ],
  ExternalConditions := [ ],
),

# FIXME: This might not work properly if the user has multiple Voles installed.
AvailabilityTest := function()
  if Filename(List(GAPInfo.PackagesInfo.vole, x -> Directory(Concatenation(
      x.InstallationPath, "/rust/target/release"))), "vole.d") = fail then
    LogPackageLoadingMessage(PACKAGE_WARNING,
      "Vole package is not compiled; please run `make` in the Vole directory");
    return fail;
  fi;
  return true;
end,

TestFile := "tst/testall.g",

# TODO: more/better keywords
Keywords := [
    "permutation group", "backtrack", "search", "backtracking", "graph",
    "digraph", "normaliser", "normalizer", "stabiliser", "stabilizer",
    "group", "subgroup", "intersection", "conjugacy", "coset", "transporter",
],

AutoDoc := rec(
   TitlePage := rec(
    Copyright := Concatenation(
      "&copyright; 20?? by ??",
      # TODO
      "\n"
      ),
    Abstract := Concatenation(
      "&Vole; is a &GAP; package that...",
      # TODO
      "\n"
      ),
    Acknowledgements := Concatenation(
      "GAPDoc? Autodoc? PackageMaker? Example package? People?",
      # TODO
      "<P/>\n"
      )
   )
),

));
