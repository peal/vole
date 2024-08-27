# Vole: Backtrack search in permutation groups with graphs
# A GAP package by Mun See Chang, Christopher Jefferson, and Wilf A. Wilson.
#
# SPDX-License-Identifier: MPL-2.0
#
# Internal utility functions.

DeclareGlobalVariable("_Vole");
InstallValue(_Vole, rec());


# ForceQuitGap is only available in GAP >= 4.12, it used to be FORCE_QUIT_GAP
if not IsBound(ForceQuitGap) and IsBound(FORCE_QUIT_GAP) then
    ForceQuitGap := FORCE_QUIT_GAP;
fi;


# Get the upper and lower bounds for a list of constraints
# The list of constraints may contain permutation groups (in the event
# we are solving a canonical problem)
_Vole.getBounds := function(constraints, initial_max, allow_max_inf)
    local min, max, this_min, this_max, c;
    if initial_max < infinity then
        min := initial_max;
    else
        min := 1;
    fi;
    max := initial_max;
    for c in constraints do
        this_min := 1;
        this_max := infinity;
        if IsPermGroup(c) then
            this_min := LargestMovedPoint(c);
            this_max := LargestMovedPoint(c);
        elif IsRefiner(c) then
            this_min := c!.largest_required_point;
            if HasLargestMovedPoint(c!.constraint) then
                this_max := LargestMovedPoint(c!.constraint);
            fi;
        fi;
        min := Maximum(min, this_min);
        max := Minimum(max, this_max);
    od;
    max := Maximum(min, max); # TODO Wilf: I'm not sure if I want this line... need to think about it
    if max = infinity and not allow_max_inf then
        ErrorNoReturn("Vole is unable to deduce an upper bound for the number ",
                      "of points on which the search is defined. ",
                      "Please include an additional argument that is ",
                      "a containing group, or a constraint of the form ",
                      "Constraint.LargestMovedPoint(point) or ",
                      "Constraint.MovedPoints(pointlist), ",
                      "in order to give a bound explicitly, ",
                      "type '?Bounds associated' for more information, ",
                      "or look at the manual...");
    fi;
    return rec(min := min, max := max);
end;


# TODO Wilf has been adjusting this and it's still a bit of a work in progress
# I want the 'main' configuration interface to just be listing the options
# as value options individually, i.e.
# VoleFind.Group(constraints : points := 5);
# VoleFind.Group(constraints : raw := true);
#
# Fill in a configuration 'default', using user-supplied values from
# ValueOptions
_Vole.getConfig := function(default)
    local r, conf;

    conf := rec();
    for r in RecNames(default) do
        if ValueOption(r) <> fail then
            conf.(r) := ValueOption(r);
        else
            conf.(r) := default.(r);
        fi;
    od;
    return conf;
end;

# For some wrapper functions, we are explicitly asking for a subgroup of
# the first argument G. GAP sets the parent of the result to be G, so we
# should do this too. However, the result is sometimes a group, or sometimes
# a record (in the 'raw' case), and so we have this little helper function
# to reduce code repetition.
_Vole.setParent := function(ret, G)
    local obj;
    if IsPermGroup(ret) then
        obj := ret;
    else
        obj := ret.group;
    fi;
    SetParent(obj, G);
end;

# Function in use by VoleRefiner.InSymmetricGroup to let it accept either a
# point k (interpreted as [1..4]) or a set of positive integers
_Vole.points := function(s)
    if s = 0 or IsPosInt(s) then
        return [1 .. s];
    elif IsDuplicateFreeList(s) and ForAll(s, IsPosInt) then
        return Set(s);
    else
        ErrorNoReturn("Unclear how <s> defines a set of positive integers");
    fi;
end;

# Temporary declarations that are made in newer versions of Digraphs package.
# Remove these when we require Digraphs v1.6.0 or newer
if not IsBound(OnTuplesDigraphs) then
    BindGlobal("OnTuplesDigraphs",
    {L, p} -> List(L, x -> OnDigraphs(DigraphMutableCopyIfMutable(x), p)));
fi;

# Turn a digraph into a list of neighbours, to allow us to accept
# either a Digraph, or a list of neighbours
_Vole.Digraph := function(g)
    if IsDigraph(g) then
        return OutNeighbours(g);
    elif IsList(g) then
        return g;
    else
        Error("Invalid graph");
    fi;
end;


Unbind(_ReadGBPackage);
Unbind(_ReadBTPackage);

_Vole.LoadFullDependencies := function()
    BindGlobal("_ReadGBPackage", {f} -> ReadPackage("Vole", Concatenation("dependancies/GraphBacktracking/", f)));
    BindGlobal("_ReadBTPackage", {f} -> ReadPackage("Vole", Concatenation("dependancies/BacktrackKit/", f)));
    ReadPackage("Vole", "dependancies/BacktrackKit/init.g");
    ReadPackage("Vole", "dependancies/GraphBacktracking/init.g");
    ReadPackage("Vole", "dependancies/BacktrackKit/read.g");
    ReadPackage("Vole", "dependancies/GraphBacktracking/read.g");
    MakeReadWriteGlobal("_ReadGBPackage");
    MakeReadWriteGlobal("_ReadBTPackage");
    UnbindGlobal("_ReadBTPackage");
    UnbindGlobal("_ReadGBPackage");
end;
