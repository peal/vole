#@local
gap> START_TEST("error.tst");
gap> LoadPackage("vole", false);
true

#
gap> VoleFind.Rep(VoleRefiner.SetStab([3, 4, 5, [2, 3]]) : points := 7);
Error, There was a fatal error in vole: Invalid problem specification. Does on\
e of your constraints have the wrong argument type?
gap> VoleFind.Group(VoleRefiner.SetSetStab([2, 3, 4]) : points := 7);
Error, There was a fatal error in vole: Invalid problem specification. Does on\
e of your constraints have the wrong argument type?

#
gap> STOP_TEST("error.tst");
