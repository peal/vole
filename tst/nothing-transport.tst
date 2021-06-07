#@local p
gap> START_TEST("nothing-transport.tst");
gap> LoadPackage("vole", false);;
gap> VoleCosetSolve(6,[BTKit_Con.Nothing()]).sol;
[  ]
gap> VoleCosetSolve(6,[BTKit_Con.Nothing2()]).sol;
[  ]

#
gap> STOP_TEST("nothing-transport.tst");
