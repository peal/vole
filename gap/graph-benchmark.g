multicycle := {a,b} -> OutNeighbours(DigraphDisjointUnion(ListWithIdenticalEntries(a, CycleDigraph(b))));
times := List([5,10..40], {t} -> Comp(t*t, [VoleCon.DigraphStab(multicycle(t,t))]));
Print(times);
