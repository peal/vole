Read("gap-code/graph.g");

times := List([5,10..40], {t} -> Comp(t*t, [con.DigraphStab(multicycle(t,t))]));
Print(times);