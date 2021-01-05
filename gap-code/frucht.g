Read("gap-code/vole-base.g");

frucht := [[1,2],
[1,3],
[1,4],
[2,5],
[2,6],
[4,7],
[4,8],
[5,9],
[5,10],
[6,11],
[6,12],
[3,7],
[7,8],
[8,12],
[12,11],
[11,9],
[9,10],
[10,3]];

neigh := List([1..12], x -> []);
for f in frucht do
    Add(neigh[f[1]], f[2]);
    Add(neigh[f[2]], f[1]);
od;

Comp(12, [con.DigraphStab(neigh)]);



