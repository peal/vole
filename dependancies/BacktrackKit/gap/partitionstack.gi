##
##  This file defines partition stacks.
##

## An ordered partition of length n is a list of disjoint sublists of [1..n]
## whose union is [1..n]. A partition stack is a list of ordered partitions,
## each of which is a refinement of the last.

## The data structure used here to encode partition stacks is best demonstrated
## by example. The partition stack:

## [ [ [1,2,3,4,5] ],
##   [ [3,5], [1,2,4] ],
##   [ [3,5], [1,2], [4] ] ]

## can be represented by the following pieces of information:

## vals:   [5,3,4,1,2]    - A permutation of [1..n].
## marks:  [1,0,3,2,0,6]  - marks[i] = j means cell 'j' starts at index 'i' of
##                          vals. The n+1th element of the array is always n+1.
## splits: [-1,1,2]       - splits[i] is the cell which was split to create
##                          cell i (or -1 for splits[1])
## Note that:
##   * The values within a cell do not have to sorted.
##   * The list of cells do not have to be sorted in any particular order.


## The main allowed operation for a partition stack is splitting a cell to form
## a new, finer partition to add onto the end of the partition stack. This is
## done by adding a new integer to 'marks', which splits a current cell.

## There are some other data structures provided for efficient lookup:

## invvals:   [4,5,2,3,1]  - The inverse of vals, to find where a value exists
##                           in vals.
## cellstart: [1,4,3]      - marks[cellstart[i]] = i.
## cellsize:  [2,2,1]      - The length of cell i.
## fixed:     [3]          - A list of cells of size 1, in the order that they
##                           become fixed. When a cell of size 2 is split into
##                           two cells of size 1, the original cell comes first.
## cellof:   [2,2,1,3,1]     i is in cell[i]. This technically makes adding/removing
##                           a cell into an O(n) instead of an O(1) operation,
##                           but can be done very efficiently. In more complex
##                           implementations this can be done lazily

InstallGlobalFunction(PartitionStack,
function(n)
    local marks;
    if n < 1 then
        Error("Partition Stack: <n> must be a positive integer");
    fi;
    
    # Make array full of n+1 0s
    marks := ListWithIdenticalEntries(n + 1, 0);
    marks[1] := 1;
    marks[n+1] := n+1;
    return Objectify(PartitionStackTypeMutable,
        rec(len := n,
            original_len := n,
            vals := [1..n],
            invvals := [1..n],
            marks := marks,
            cellstart := [1],
            cellsize := [n],
            fixed := [],
            splits := [-1],
            cellof := ListWithIdenticalEntries(n, 1)));
end);

InstallMethod(IsInternallyConsistent, [IsPartitionStack],
    function(ps)
        local n, i, j, fixedcells;
        n := ps!.len;
        if Length(ps!.marks) <> n+1 then return false; fi;
        if ps!.marks[1] <> 1 or ps!.marks[n+1] <> n+1 then return false; fi;

        if Length(ps!.cellstart) <> Length(ps!.cellsize) then return false; fi;
        if ForAny([1..n],
            {i} -> (ps!.marks[i] <> 0 and
                     (ps!.cellstart[ps!.marks[i]] <> i or
                      ps!.cellstart[ps!.marks[i]] +
                        ps!.cellsize[ps!.marks[i]] - 1 = 0)
                   )) then
            return false;
        fi;

        for i in [1..Length(ps!.cellstart)] do
            for j in [ps!.cellstart[i]..ps!.cellstart[i]+ps!.cellsize[i]-1] do
                if ps!.cellof[j] <> i then
                    return false;
                fi;
            od;
        od;

        if ForAny([1..Length(ps!.cellstart)],
             {i} -> ps!.marks[ps!.cellstart[i]] <> i) then
             return false;
        fi;

        if Sum(ps!.cellsize) <> n then return false; fi;

        fixedcells := Filtered([1..Length(ps!.cellsize)], x -> ps!.cellsize[x] = 1 and ps!.vals[ps!.cellstart[x]] <= ps!.original_len);
        if Set(ps!.fixed) <> Set(fixedcells) or
           Length(Set(ps!.fixed)) <> Length(ps!.fixed) then
            return false;
        fi;

        if Set(ps!.vals) <> [1..n] or Set(ps!.invvals) <> [1..n] then
            return false;
        fi;
        if ForAny([1..n], {i} -> ps!.vals[ps!.invvals[i]] <> i) then
            return false;
        fi;

        return true;
    end);

InstallMethod(PS_AsPartition, [IsPartitionStack],
    {ps} -> List([1..PS_Cells(ps)], c -> Set(PS_CellSlice(ps, c))) );

InstallMethod(ViewString, "for a partition stack",
    [ IsPartitionStack ],
    {ps} -> STRINGIFY(PS_AsPartition(ps)) );

InstallMethod(PS_Points, [IsPartitionStackRep],
    {ps} -> ps!.original_len);

InstallMethod(PS_ExtendedPoints, [IsPartitionStackRep],
    {ps} -> ps!.len);

InstallMethod(PS_Extend, [IsPartitionStackRep, IsPosInt],
    function(ps, pnts)
        local curlen, newlen;
        curlen := ps!.len;
        newlen := ps!.len + pnts;
        Append(ps!.vals, [curlen+1..newlen]);
        Append(ps!.invvals, [curlen+1..newlen]);
        Append(ps!.marks, [curlen+1..newlen]*0);
        ps!.marks[curlen+1] := Length(ps!.cellstart) + 1;
        ps!.marks[newlen+1] := newlen+1;
        Add(ps!.cellstart, curlen+1);
        Add(ps!.cellsize, pnts);
        # Don't add to ps!.fixed, even if size 1, as we only
        # add points which are "in the original set"
        Add(ps!.splits, -2);
        Append(ps!.cellof, ListWithIdenticalEntries(pnts, Length(ps!.cellstart)));
        ps!.len := newlen;
        return Length(ps!.cellstart);
    end);

InstallMethod(PS_Cells, [IsPartitionStackRep],
    {ps} -> Length(ps!.cellstart));

InstallMethod(PS_Fixed, [IsPartitionStackRep],
    {ps} -> PS_ExtendedPoints(ps) = PS_Cells(ps) );

InstallMethod(PS_CellLen, [IsPartitionStackRep, IsPosInt],
    {ps, cell} -> ps!.cellsize[cell]);

InstallMethod(PS_CellSlice, [IsPartitionStackRep, IsPosInt],
    {ps, cell} -> Immutable(Slice(ps!.vals, ps!.cellstart[cell], ps!.cellsize[cell])));

InstallMethod(PS_FixedCells, [IsPartitionStackRep],
    {ps} -> ps!.fixed);

InstallMethod(PS_FixedPoints, [IsPartitionStackRep],
    {ps} -> List(ps!.fixed, {x} -> ps!.vals[ps!.cellstart[x]]));

InstallMethod(PS_CellOfPoint, [IsPartitionStackRep, IsPosInt],
    function(ps, i)
        local pos, pos2;
#        pos := ps!.invvals[i];
#        while ps!.marks[pos] = 0 do
#            pos := pos - 1;
#        od;
        pos2 := ps!.cellof[ps!.invvals[i]];
#        Assert(0, ps!.marks[pos] = pos2);
        return pos2;
    end);


InstallMethod(PS_UNSAFE_CellSlice, [IsPartitionStackRep, IsPosInt],
    {ps, cell} -> Slice(ps!.vals, ps!.cellstart[cell], ps!.cellsize[cell]));

InstallMethod(PS_UNSAFE_FixupCell, [IsPartitionStackRep, IsPosInt],
    function(ps, cell)
        local i,j;
        for i in [ps!.cellstart[cell]..ps!.cellstart[cell]+ps!.cellsize[cell]-1] do
            j := ps!.vals[i];
            ps!.invvals[j] := i;
        od;
    end);


BindGlobal("_PSR_SplitCell",
    function(ps, t, cell, index, reason)
        local splitpos, newcellid, splitcellsize, i;
        Assert(2, index >= 1 and index <= ps!.cellsize[cell]);
        splitpos := ps!.cellstart[cell] + index - 1;
        splitcellsize := ps!.cellsize[cell];

        newcellid := Length(ps!.cellstart) + 1;

        ps!.cellstart[newcellid] := splitpos;
        ps!.cellsize[newcellid] := splitcellsize - (index - 1);

        for i in [ps!.cellstart[newcellid]..ps!.cellstart[newcellid]+ps!.cellsize[newcellid]-1] do
            ps!.cellof[i] := newcellid;
        od;

        ps!.marks[splitpos] := newcellid;

        ps!.cellsize[cell] := (index - 1);

        if (index - 1) = 1 and ps!.vals[ps!.cellstart[cell]] <= ps!.original_len then
            Add(ps!.fixed, cell);
        fi;

        if splitcellsize - (index - 1) = 1 and ps!.vals[ps!.cellstart[newcellid]] <= ps!.original_len then
            Add(ps!.fixed, newcellid);
        fi;

        Add(ps!.splits, cell);
        return MaybeAddEvent(t, rec(oldcell := cell,
                                    newcell := newcellid,
                                    oldsize := index - 1,
                                    newsize := splitcellsize - (index - 1),
                                    reason  := reason));
    end);

InstallMethod(PS_ExtendedSplitCellsByFunction, [IsPartitionStack, IsTracer, IsFunction],
    function(ps, t, f)
        local i;
        for i in [1..PS_Cells(ps)] do
            if not PS_SplitCellByFunction(ps, t, i, f) then
                return false;
            fi;
        od;
        return true;
    end);

InstallMethod(PS_SplitCellsByFunction, [IsPartitionStack, IsTracer, IsFunction],
    function(ps, t, f)
        local i;
        for i in [1..PS_Cells(ps)] do
            if PS_CellSlice(ps,i)[1] <= PS_Points(ps) then
                if not PS_SplitCellByFunction(ps, t, i, f) then
                    return false;
                fi;
            fi;
        od;
        return true;
    end);

InstallMethod(PS_SplitCellByFunction,
    [IsPartitionStackRep, IsTracer, IsPosInt, IsFunction],
    function(ps, t, cell, f)
        local slice, slicelen, lastval, curval, i, success;

        slice := PS_UNSAFE_CellSlice(ps, cell);
        SortBy(slice, f);
        PS_UNSAFE_FixupCell(ps, cell);
        slicelen := Length(slice);
        lastval := f(slice[slicelen]);
        for i in [slicelen-1, slicelen-2..1] do
            curval := f(slice[i]);
            if lastval <> curval then
                Info(InfoBTKit, 9, "Splitting ",cell, " at ",i+1," because ",lastval,"<>",curval);
                if not _PSR_SplitCell(ps, t, cell, i+1, curval) then
                    Info(InfoBTKit, 9, "Split failed!");
                    return false;
                fi;
                Info(InfoBTKit, 9, "Got: ",PS_AsPartition(ps));
            fi;
            lastval := curval;
        od;
        return MaybeAddEvent(t, rec(endsplit := true, reason := f(slice[1])));
    end);

InstallMethod(PS_SplitCellByUnorderedFunction,
    [IsPartitionStack, IsTracer, IsPosInt, IsFunction],
    function(ps, t, cell, f)
        local slice, slicelen, lastval, curval, i;

        slice := PS_UNSAFE_CellSlice(ps, cell);
        SortBy(slice, f);
        PS_UNSAFE_FixupCell(ps, cell);
        slicelen := Length(slice);
        lastval := f(slice[slicelen]);
        for i in [slicelen-1, slicelen-2..1] do
            curval := f(slice[i]);
            if lastval <> curval then
                _PSR_SplitCell(ps, cell, i+1);
            fi;
            lastval := curval;
        od;
    end);


InstallMethod(PS_RevertToCellCount, [IsPartitionStackRep, IsPosInt],
    function(ps, depth)
        local revertcell, revertstart, revertlen, i;
        while depth < Length(ps!.cellstart) do
            revertcell := Remove(ps!.splits);
            revertstart := Remove(ps!.cellstart);
            revertlen := Remove(ps!.cellsize);

            if revertcell = -2 then
                # This was an extra cell was grew the partition
                ps!.len := ps!.len - revertlen;
                ps!.vals := ps!.vals{[1..ps!.len]};
                ps!.invvals := ps!.invvals{[1..ps!.len]};
                ps!.marks := ps!.marks{[1..ps!.len+1]};
                ps!.marks[ps!.len+1] := ps!.len+1;
                ps!.cellof := ps!.cellof{[1..ps!.len]};
            else
                for i in [revertstart..revertstart+revertlen-1] do
                    ps!.cellof[i] := revertcell;
                od;

                ps!.marks[revertstart] := 0;

                if ps!.cellsize[revertcell] = 1 and ps!.vals[ps!.cellstart[revertcell]] <= ps!.original_len then
                    Remove(ps!.fixed);
                fi;

                if revertlen = 1 and ps!.vals[ps!.cellstart[revertcell]] <= ps!.original_len then
                    Remove(ps!.fixed);
                fi;

                ps!.cellsize[revertcell] := ps!.cellsize[revertcell] + revertlen;
            fi;
        od;
    end);
