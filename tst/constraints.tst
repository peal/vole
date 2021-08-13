#@local
gap> START_TEST("constraints.tst");
gap> LoadPackage("vole", false);
true

# VoleCon.Stabilise
gap> VoleCon.Stabilise();
Error, Function: number of arguments must be at least 1 (not 0)
gap> VoleCon.Stabilise(1, 3);
Error, VoleCon.Stabilize args: object[, action]

#
gap> STOP_TEST("constraints.tst");
