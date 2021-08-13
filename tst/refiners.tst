#@local
gap> START_TEST("refiners.tst");
gap> LoadPackage("vole", false);
true

# VoleRefiner.InSymmetricGroup
# TODO: this first one should probably given an error
gap> VoleRefiner.InSymmetricGroup(5);
rec( bounds := rec( largest_moved_point := 5, largest_required_point := 5 ), 
  con := rec( InSymmetricGroup := rec( points := 5 ) ) )
gap> VoleRefiner.InSymmetricGroup([1 .. 5]);
rec( bounds := rec( largest_moved_point := 5, largest_required_point := 5 ), 
  con := rec( InSymmetricGroup := rec( points := [ 1 .. 5 ] ) ) )
gap> VoleRefiner.InSymmetricGroup([2, 3, 5]);
rec( bounds := rec( largest_moved_point := 5, largest_required_point := 5 ), 
  con := rec( InSymmetricGroup := rec( points := [ 2, 3, 5 ] ) ) )

#
gap> STOP_TEST("refiners.tst");
