#@local g, s, p, func, ret1, ret2
gap> START_TEST("canonical-grp.tst");
gap> ReadPackage("vole", "tst/test_functions.g");
true

#
gap> QC_Check([IsPermGroup, IsPermGroup],
> function(g,s)
>   local lmp;
>   lmp := Maximum([LargestMovedPoint(g), LargestMovedPoint(s),2]);
>   return VoleTestCanonical(lmp, g, s, x -> GB_Con.NormaliserSimple(x), OnPoints);
> end, rec(limit := 7));
true

# This examples used to give a wrong result, caused by a problem where one
# trace is a prefix of another.
gap> g := Group([(1,2,3,4,5,6,7), (1,2,4)(3,6,5)]);;
gap> s := Group([(2,4,6), (1,5)(2,4), (1,4,5,2)(3,6)]);;
gap> p := (1,3,7)(2,5,4);;
gap> func := x -> GB_Con.NormaliserSimple(x);;
gap> ret1 := VoleFind.CanonicalPerm(g, Flat([func(s)]));;
gap> ret2 := VoleFind.CanonicalPerm(g, Flat([func(s ^ p)]));;
gap> s ^ ret1 = (s ^ p) ^ ret2;
true

#
gap> STOP_TEST("canonical-grp.tst");
