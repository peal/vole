#@local
gap> START_TEST("refiners.tst");
gap> LoadPackage("vole", false);
true

# VoleRefiner.InSymmetricGroup
gap> VoleRefiner.InSymmetricGroup(0);
rec( bounds := rec( largest_moved_point := 0, largest_required_point := 0 ), 
  con := rec( InSymmetricGroup := rec( points := [  ] ) ) )
gap> VoleRefiner.InSymmetricGroup([]);
rec( bounds := rec( largest_moved_point := 0, largest_required_point := 0 ), 
  con := rec( InSymmetricGroup := rec( points := [  ] ) ) )
gap> VoleRefiner.InSymmetricGroup([4, 2, 1]);
rec( bounds := rec( largest_moved_point := 4, largest_required_point := 4 ), 
  con := rec( InSymmetricGroup := rec( points := [ 1, 2, 4 ] ) ) )
gap> VoleRefiner.InSymmetricGroup(5);
rec( bounds := rec( largest_moved_point := 5, largest_required_point := 5 ), 
  con := rec( InSymmetricGroup := rec( points := [ 1 .. 5 ] ) ) )
gap> VoleRefiner.InSymmetricGroup([1 .. 5]);
rec( bounds := rec( largest_moved_point := 5, largest_required_point := 5 ), 
  con := rec( InSymmetricGroup := rec( points := [ 1 .. 5 ] ) ) )
gap> VoleRefiner.InSymmetricGroup([2, 3, 5]);
rec( bounds := rec( largest_moved_point := 5, largest_required_point := 5 ), 
  con := rec( InSymmetricGroup := rec( points := [ 2, 3, 5 ] ) ) )

#
gap> STOP_TEST("refiners.tst");
