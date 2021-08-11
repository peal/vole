# Vole, chapter 5
#
# DO NOT EDIT THIS FILE - EDIT EXAMPLES IN THE SOURCE INSTEAD!
#
# This file has been generated by AutoDoc. It contains examples extracted from
# the package documentation. Each example is preceded by a comment which gives
# the name of a GAPDoc XML file and a line range from which the example were
# taken. Note that the XML file in turn may have been generated by AutoDoc
# from some other input.
#
gap> START_TEST("vole05.tst");

# doc/_Chapter_Constraints.xml:103-109
gap> LoadPackage("vole", false);;
gap> Set(RecNames(VoleCon));
[ "Centralise", "Centralize", "Conjugate", "InCoset", "InGroup", 
  "InLeftCoset", "InRightCoset", "LargestMovedPoint", "MovedPoints", "None", 
  "Normalise", "Normalize", "Stabilise", "Stabilize", "Transport" ]

# doc/_Chapter_Constraints.xml:187-192
gap> con1 := VoleCon.InGroup(DihedralGroup(IsPermGroup, 8));;
gap> con2 := VoleCon.InGroup(AlternatingGroup(4));;
gap> VoleFind.Group(con1, con2) = Group([(1,3)(2,4), (1,4)(2,3)]);
true

# doc/_Chapter_Constraints.xml:210-217
gap> U := PSL(2,5) * (3,4,6);
RightCoset(Group([ (3,5)(4,6), (1,2,5)(3,4,6) ]),(3,4,6))
gap> x := VoleFind.Coset(VoleCon.InCoset(U), AlternatingGroup(6));
RightCoset(Group([ (3,5)(4,6), (2,4)(5,6), (1,2,6,5,4) ]),(1,5)(2,3,4,6))
gap> x = Intersection(U, AlternatingGroup(6));
true

# doc/_Chapter_Constraints.xml:234-240
gap> x := VoleFind.Coset(VoleCon.InRightCoset(PSL(2,5), (3,4,6)),
>                        VoleCon.InGroup(AlternatingGroup(6)));
RightCoset(Group([ (3,5)(4,6), (2,4)(5,6), (1,2,6,5,4) ]),(1,5)(2,3,4,6))
gap> x = Intersection(PSL(2,5) * (3,4,6), AlternatingGroup(6));
true

# doc/_Chapter_Constraints.xml:257-263
gap> x := VoleFind.Rep(VoleCon.InLeftCoset(PSL(2,5), (3,4,6)),
>                      VoleCon.InGroup(AlternatingGroup(6)));
(1,6,2,3,4)
gap> SignPerm(x) = 1 and ForAny(PSL(2,5), g -> x = (3,4,6) * g);
true

# doc/_Chapter_Constraints.xml:291-300
gap> con1 := VoleCon.Stabilise(CycleDigraph(6), OnDigraphs);;
gap> con2 := VoleCon.Stabilise([2,4,6], OnSets);;
gap> VoleFind.Group(con1, 6);
Group([ (1,2,3,4,5,6) ])
gap> VoleFind.Group(con2, 6);
Group([ (4,6), (2,4,6), (3,5)(4,6), (1,3,5)(2,4,6) ])
gap> VoleFind.Group(con1, con2, 6);
Group([ (1,3,5)(2,4,6) ])

# doc/_Chapter_Constraints.xml:330-340
gap> setofsets1 := [[1, 3, 6], [2, 3, 6], [2, 4, 7], [4, 5, 7]];;
gap> setofsets2 := [[1, 2, 5], [1, 5, 7], [3, 4, 6], [4, 6, 7]];;
gap> con := VoleCon.Transport(setofsets1, setofsets2, OnSetsSets);;
gap> VoleFind.Rep(con);
(1,2,7,6)(3,5)
gap> VoleFind.Rep(con, AlternatingGroup(7) * (1,2));
(1,2,7,6,5,3)
gap> VoleFind.Rep(con, DihedralGroup(IsPermGroup, 14));
fail

# doc/_Chapter_Constraints.xml:359-369
gap> con := VoleCon.Normalise(PSL(2,5));;
gap> N := VoleFind.Group(con, SymmetricGroup(6));
Group([ (3,4,5,6), (2,3,5,6), (1,2,4,3,6) ])
gap> (3,4,5,6) in N and not (3,4,5,6) in PSL(2,5);
true
gap> Index(N, PSL(2,5));
2
gap> PSL(2,5) = VoleFind.Group(con, AlternatingGroup(6));
true

# doc/_Chapter_Constraints.xml:388-397
gap> D12 := DihedralGroup(IsPermGroup, 12);;
gap> VoleFind.Group(6, VoleCon.Centralise(D12));
Group([ (1,4)(2,5)(3,6) ])
gap> x := (1,6)(2,5)(3,4);;
gap> G := VoleFind.Group(AlternatingGroup(6), VoleCon.Centralise(x));
Group([ (2,3)(4,5), (2,4)(3,5), (1,2,3)(4,6,5) ])
gap> ForAll(G, g -> SignPerm(g) = 1 and g * x = x * g);
true

# doc/_Chapter_Constraints.xml:421-427
gap> con := VoleCon.Conjugate((3,4)(2,5,1), (1,2,3)(4,5));;
gap> VoleFind.Rep(con);
(1,2,3,5)
gap> VoleFind.Rep(con, PSL(2,5));
(1,3,4,5,2)

# doc/_Chapter_Constraints.xml:442-447
gap> con1 := VoleCon.MovedPoints([1..5]);;
gap> con2 := VoleCon.MovedPoints([2,6,4,5]);;
gap> VoleFind.Group(con1, con2) = SymmetricGroup([2,4,5]);
true

# doc/_Chapter_Constraints.xml:462-466
gap> con := VoleCon.LargestMovedPoint(5);;
gap> VoleFind.Group(con) = SymmetricGroup(5);
true

# doc/_Chapter_Constraints.xml:481-484
gap> VoleFind.Rep(VoleCon.None());
fail

#
gap> STOP_TEST("vole05.tst", 1);
