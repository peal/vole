#@local p
gap> START_TEST("nothing-transport.tst");
gap> LoadPackage("vole", false);;

#
gap> VoleFind.Rep(BTKit_Con.Nothing() : points := 6);
fail
gap> VoleFind.Rep(BTKit_Con.Nothing2() : points := 6);
fail

#
gap> STOP_TEST("nothing-transport.tst");
