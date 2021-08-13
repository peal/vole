#@local
gap> START_TEST("interface.tst");
gap> LoadPackage("vole", false);
true

# VoleFind.Representative
gap> VoleFind.Representative();
Error, VoleFind.Rep: At least one argument must be given

#
gap> STOP_TEST("interface.tst");
