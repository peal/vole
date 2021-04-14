Read("gap-code/vole-base.g");


multicycle := function(a,b)
    local l, i, j;
    l := List([1..a*b], x -> []);
    for i in [0,b..b*(a-1)] do
        for j in [1..b-1] do
            l[i+j] := [i+j+1];
        od;
        l[i+b] := [i+1];
    od;
    return l;
end;
