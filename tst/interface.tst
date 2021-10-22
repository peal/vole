#@local
gap> START_TEST("interface.tst");
gap> LoadPackage("vole", false);
true

# VoleFind.Representative
gap> VoleFind.Representative();
Error, VoleFind.Rep: At least one argument must be given
gap> VoleFind.Representative(1 : raw).sols[1] = ();
true

# VoleFind.Group
gap> VoleFind.Group();
Error, VoleFind.Group: At least one argument must be given

# VoleFind.Coset
gap> VoleFind.Coset();
Error, VoleFind.Coset: At least one argument must be given
gap> VoleFind.Coset(fail);
fail
gap> VoleFind.Coset(Group([(1,2)(3,4), (1,3)(2,4)]) * (1,2,3));
RightCoset(Group([ (1,2)(3,4), (1,3)(2,4) ]),(1,2,3))
gap> VoleFind.Coset(Group([(1,2)]) * (2,3));
RightCoset(Group([ (1,2) ]),(2,3))

# VoleFind.Canonical
gap> VoleFind.Canonical();
Error, Function: number of arguments must be at least 1 (not 0)
gap> VoleFind.Canonical(fail);
Error, VoleFind.Canonical: The first argument must be a perm group
gap> VoleFind.Canonical(Group(()));
Error, VoleFind.Canonical: At least two arguments must be given
gap> VoleFind.Canonical(Group(()), Group(()));
Error, VoleFind.Canonical: A perm group is not valid additional argument; to c\
anonise a group under conjugation, use the constraint VoleCon.Normalise, or gi\
ve a specific normaliser refiner;
gap> VoleFind.Canonical(Group(()), fail);
Error, VoleFind.Canonical: The additional arguments must be Vole constraints, \
or (potentially custom) Vole, GraphBacktracking, or BacktrackKit refiners;
gap> VoleFind.Canonical(
>        SymmetricGroup(5),
>        VoleCon.InGroup(AlternatingGroup(4)));
Error, VoleFind.Canonical: The additional arguments must not include any const\
raints/refiners that are (directly or indirectly) of the kind 'in-group-given-\
by-generators'; i.e. VoleCon.InGroup(H) and VoleCon.LargestMovedPoint(k) are n\
ot allowed. To canonise a group under conjugation, use the constraint VoleCon.\
Normalise, or give a specific normaliser refiner. To restrict the moved points\
, canonise in a different group;
gap> VoleFind.Canonical(
>        SymmetricGroup(5),
>        VoleCon.InGroup(SymmetricGroup(4)));
Error, VoleFind.Canonical: The additional arguments must not include any const\
raints/refiners that are (directly or indirectly) of the kind 'in-group-given-\
by-generators'; i.e. VoleCon.InGroup(H) and VoleCon.LargestMovedPoint(k) are n\
ot allowed. To canonise a group under conjugation, use the constraint VoleCon.\
Normalise, or give a specific normaliser refiner. To restrict the moved points\
, canonise in a different group;
gap> VoleFind.Canonical(
>        AlternatingGroup(5),
>        VoleCon.Transport([1,2,3], [3,4,5], OnTuples));
Error, VoleFind.Canonical: Each additional argument must be a constraint or re\
finer for the stabiliser of some object under some group action; constraints/r\
efiners for cosets that are groups are not allowed; Vole 'Transporter' constra\
ints/refiners are not allowed either;
gap> VoleFind.Canonical(
>        SymmetricGroup(4),
>        VoleCon.Normalise(AlternatingGroup(4))
>        : raw
>    ).group = SymmetricGroup(4);
true

#
gap> STOP_TEST("interface.tst");
