#
# BacktrackKit: An extensible, easy to understand backtracking framework
#
# Methods for constraint objects
#

InstallMethod(IsGroupConstraint, "for a constraint", [IsConstraint],
    {con} -> Check(con)(()));

# Warning: may need to perform a search to compute these:
InstallMethod(IsCosetConstraint, "for a constraint", [IsConstraint],
    {con} -> IsGroupConstraint(con) or not IsEmptyConstraint(con));
InstallMethod(IsEmptyConstraint, "for a constraint", [IsConstraint],
    {con} -> Representative(con) <> fail);
# TODO have overriding method in each of GB and Vole
InstallMethod(Representative, "for a constraint", [IsConstraint],
function(con)
    local stack;
    if IsGroupConstraint(con) then
        return ();
    elif not HasLargestRelevantPoint(con) then
        # TODO: If we can translate the constraint into a refiner,
        # then we might find a largest_required_point for the constraint,
        # which we could use in place of LargestRelevantPoint below.
        ErrorNoReturn("Unbounded...");
    fi;

    # TODO: Add an Info statement saying that a search is about to happen and might be slow.

    return _BTKit.SimpleSinglePermSearch(
        PartitionStack(LargestRelevantPoint(con)),
        [BTKit_RefinerFromConstraint(con)],[])[1];
end);

InstallImmediateMethod(Representative, "for a group constraint",
    IsGroupConstraint,
    {con} -> ());
InstallImmediateMethod(Representative, "for an empty constraint",
    IsEmptyConstraint,
    ReturnFail);
InstallImmediateMethod(IsEmptyConstraint, "for a constraint with size",
    IsConstraint and HasSize,
    {con} -> Size(con) = 0);
InstallImmediateMethod(LargestRelevantPoint, "for a constraint with largest moved point",
    IsConstraint and HasLargestMovedPoint,
    LargestMovedPoint);

InstallImmediateMethod(Size, "for a constraint with IsEmptyConstraint",
    IsConstraint and HasIsEmptyConstraint,
    function(con)
        if IsEmptyConstraint(con) then
            return 0;
        fi;
        TryNextMethod();
    end);

InstallMethod(Check, "for an in-coset-by-gens constraint", [IsInCosetByGensConstraint],
    {con} -> {p} -> p / Representative(con) in UnderlyingGroup(con));
InstallMethod(Check, "for a transporter constraint", [IsTransporterConstraint],
    {con} -> {p} -> ImageFunc(con)(p) = ResultObject(con));
InstallMethod(Check, "for a constraint", [IsConstraint],
function(con)
    if IsBound(con!.Result) then
        return {p} -> ImageFunc(con)(p) = con!.Result;
    fi;
    # TODO: Refer user to appropriate documentation of what IsConstraint objects must implemented.
    ErrorNoReturn("Unrecognised type of constraint, unable to construct a Check function.");
end);

InstallMethod(ImageFunc, "for a transporter constraint", [IsTransporterConstraint],
    {con} -> {p} -> ActionFunc(con)(SourceObject(con), p));
# FIXME I don't think this really makes sense, but is currently needed for canonical images
InstallMethod(ImageFunc, "for an in-group-by-gens constraint", [IsInGroupByGensConstraint],
    {con} -> {p} -> UnderlyingGroup(con));

InstallMethod(\=, "for two constraints",
[IsConstraint, IsConstraint],
function(x, y)
    if IsTransporterConstraint(x) and IsTransporterConstraint(y) then
        return ActionFunc(x) = ActionFunc(y)
            and SourceObject(x) = SourceObject(y)
            and ResultObject(x) = ResultObject(y);
    elif IsInCosetByGensConstraint(x) and IsInCosetByGensConstraint(y) then
        # Should the gens and specific rep matter for equality? Currently they do not.
        return UnderlyingGroup(x) = UnderlyingGroup(y)
            and Representative(x) / Representative(y) in UnderlyingGroup(x);
    else
        # A transporter constraint and an in-coset-by-gens constraint,
        # or an equality involving a special one-off constraint (only equal to themselves).
        return false;
    fi;
end);


# Functions for creating constraints

Constraint.Transport := function(x, y, action...)
    local con, name, isgroup, lrp;

    # Determine action: default is OnPoints
    if Length(action) = 1 and IsFunction(action[1]) and
      (NumberArgumentsFunction(action[1]) = 2 or
       NumberArgumentsFunction(action[1]) < 0) then
        action := action[1];
    elif Length(action) = 0 then
        action := OnPoints;
    else
        ErrorNoReturn("Constraint.Transport: args: x, y[, action]");
    fi;

    if (action = OnTuples or StartsWith(NameFunction(action), "OnTuples"))
      and not (IsList(x) and IsList(y)) then
        ErrorNoReturn(
            "Constraint.Transport: ",
            "the third argument <action> is OnTuples{...}, ",
            "but the first and second arguments <x> and <y> are not lists"
        );
    elif (action = OnSets or StartsWith(NameFunction(action), "OnSets"))
      and not (IsSet(x) and IsSet(y)) then
        ErrorNoReturn(
            "Constraint.Transport: ",
            "the third argument <action> is OnSets{...}, ",
            "but the first and second arguments <x> and <y> are not GAP sets"
        );
    elif action = \^ then
        # Standardise \^ and OnPoints to make equality of constraint testing more accurate.
        action := OnPoints;
    fi;

    isgroup := x = y;

    con := ObjectifyWithAttributes(
        rec(), ConstraintType,
        IsGroupConstraint, isgroup,
        ActionFunc, action,
        SourceObject, x,
        ResultObject, y
    );
    SetFilterObj(con, IsTransporterConstraint);

    if FamilyObj(x) <> FamilyObj(y) or
          ((action = OnTuples or StartsWith(NameFunction(action), "OnTuples") or
            action = OnSets or StartsWith(NameFunction(action), "OnSets"))
           and Length(x) <> Length(y)) then
        SetIsEmptyConstraint(con, true);
        SetCheck(con, ReturnFalse);
        SetRepresentative(con, fail);
        SetSize(con, 0);
    fi;

    lrp := _BTKit.LargestRelevantPoint(x);
    if not isgroup then
        lrp := Maximum(lrp, _BTKit.LargestRelevantPoint(y));
    fi;
    if lrp < infinity then
        SetLargestRelevantPoint(con, lrp);
    fi;

    if IsGroupConstraint(con) then
        name := StringFormatted(
            "<constraint: stabiliser of {} under {}>",
            x, NameFunction(action));
    else
        name := StringFormatted(
            "<constraint: transporter of {} to {} under {}>",
            x, y, NameFunction(action));
    fi;
    SetName(con, name);
    return con;
end;
Constraint.Stabilise := {x, action...} ->
    CallFuncList(Constraint.Transport, Concatenation([x, x], action));
Constraint.Stabilize := Constraint.Stabilise;


Constraint.InCoset := function(arg...)
    local con, name, G, x;

    if Length(arg) = 1 and IsRightCoset(arg[1]) and IsPermGroup(ActingDomain(arg[1])) then
        G := ActingDomain(arg[1]);
        x := Representative(arg[1]);
    elif Length(arg) = 2 and IsPermGroup(arg[1]) and IsPerm(arg[2]) then
        G := arg[1];
        x := arg[2];
    else
        ErrorNoReturn(
            "Constraint.InCoset: the argument(s) must be a perm group ",
            "and a perm, or a GAP right coset object of a perm group"
        );
    fi;

    con := ObjectifyWithAttributes(
        rec(), ConstraintType,
        UnderlyingGroup, G,
        Representative, x,
        Size, Size(G),
        LargestMovedPoint, Maximum(LargestMovedPoint(G), LargestMovedPoint(x))
    );
    SetFilterObj(con, IsInCosetByGensConstraint);

    SetIsGroupConstraint(con, x in G);
    if IsGroupConstraint(con) then
        name := StringFormatted("<constraint: in group: {}>", G);
    else
        name := StringFormatted("<constraint: in coset: {} * {}", G, x);
    fi;
    SetName(con, name);

    return con;
end;
Constraint.InLeftCoset := {G, x} -> Constraint.InRightCoset(G ^ x, x);
Constraint.InRightCoset := Constraint.InCoset;
Constraint.InGroup := {G} -> Constraint.InCoset(G, ());


# Special cases of the constraint-creator functions (i.e. special names)

Constraint.Normalise := function(G)
    local con;
    if not IsPermGroup(G) then
        ErrorNoReturn("Constraint.Normalise: The argument must be a perm group");
    fi;
    con := Constraint.Stabilise(G, OnPoints);
    con!.Name := StringFormatted("<constraint: normalise {}>", G);
    return con;
end;
Constraint.Normalize := Constraint.Normalise;

Constraint.Centralise := function(G)
    local con, type;
    if IsPermGroup(G) then
        con := Constraint.Stabilise(GeneratorsOfGroup(G), OnTuples);
        type := "group";
    elif IsPerm(G) then
        con := Constraint.Stabilise(G, OnPoints);
        type := "perm";
    else
        ErrorNoReturn("Constraint.Centralise: ",
                      "The argument must be a perm or perm group");
    fi;
    con!.Name := StringFormatted("<constraint: centralise {} {}>", type, G);
    return con;
end;
Constraint.Centralize := Constraint.Centralise;

Constraint.Conjugate := function(G, H)
    local con, type;
    if IsPermGroup(G) and IsPermGroup(H) then
        type := "group";
    elif IsPerm(G) and IsPerm(H) then
        type := "perm";
    else
        ErrorNoReturn("Constraint.Conjugate: ",
                      "The arguments must be two perms or two perm groups");
    fi;

    if G = H then
        if IsPermGroup(G) then
            return Constraint.Normalise(G);
        else # IsPerm(G)
            return Constraint.Centralise(G);
        fi;
    fi;

    con := Constraint.Transport(G, H, OnPoints);
    con!.Name := StringFormatted("<constraint: conjugate {} {} to {}>", type, G, H);

    if IsPerm(G) and (CycleIndex(G) <> CycleIndex(H)) then
        SetIsEmptyConstraint(con, true);
    fi;

    return con;
end;

Constraint.MovedPoints := function(pointlist)
    local con;
    if not IsList(pointlist) or not ForAll(pointlist, IsPosInt) then
        ErrorNoReturn("Constraint.MovedPoints: ",
                      "The argument must be a list of positive integers");
    fi;
    con := Constraint.InGroup(SymmetricGroup(pointlist));
    con!.Name := StringFormatted("<constraint: moved points: {}>", pointlist);
    return con;
end;

Constraint.LargestMovedPoint := function(point)
    local con;
    if point <> 0 and not IsPosInt(point) then
        ErrorNoReturn("Constraint.LargestMovedPoint: ",
                      "The argument must be a nonnegative integer");
    fi;
    con := Constraint.InGroup(SymmetricGroup([1 .. point]));
    con!.Name := StringFormatted("<constraint: largest moved point: {}>", point);
    return con;
end;


# Special one-off constraints

Constraint.IsEven := ObjectifyWithAttributes(
    rec(Result := 1), ConstraintType,
    ImageFunc, SignPerm,
    IsGroupConstraint, true,
    LargestRelevantPoint, 1,
    #UnderlyingGroup, fail,
    Size, infinity,
    Name, "<constraint: is even permutation>"
);

Constraint.Everything := ObjectifyWithAttributes(
    rec(), ConstraintType,
    ImageFunc, IdFunc,
    Check, ReturnTrue,
    IsGroupConstraint, true,
    LargestRelevantPoint, 1,
    Size, infinity,
    Name, "<constraint: satisfied by all permutations>"
);

Constraint.IsOdd := ObjectifyWithAttributes(
    rec(Result := -1), ConstraintType,
    ImageFunc, SignPerm,
    IsCosetConstraint, true,
    IsGroupConstraint, false,
    LargestRelevantPoint, 2,
    Representative, (1,2),
    Size, infinity,
    Name, "<constraint: is odd permutation>"
);

Constraint.Nothing := ObjectifyWithAttributes(
    rec(), ConstraintType,
    IsEmptyConstraint, true,
    Check, ReturnFalse,
    LargestMovedPoint, 1,
    Representative, fail,
    Size, 0,
    Name, "<empty constraint: satisfied by no permutations>"
);
Constraint.None := Constraint.Nothing;

Constraint.IsTrivial := ObjectifyWithAttributes(
    rec(Result := ()), ConstraintType,
    ImageFunc, IdFunc,
    IsGroupConstraint, true,
    LargestMovedPoint, 1,
    UnderlyingGroup, TrivialGroup(IsPermGroup),
    Size, 1,
    Name, "<trivial constraint: is identity permutation>"
);


ProcessConstraints := function(args...)
    local constraints, refiners, extra, x, i, G, movedG, movedx, differ, points, sizes, all, con, bound;
    # FIXME if `[]` or `[[]]` etc is given as an arg, then this disappears!
    args := Flat(args);

    constraints := [];
    refiners := [];
    extra := [];

    # Replace:
    #   Integer i -> LargestMovedPoint i
    #   Group G   -> InGroup G
    #   Coset U   -> InCoset U
    for x in args do
        if IsConstraint(x) then
            Add(constraints, x);
        elif IsRefiner(x) then
            Add(refiners, x);
            Add(extra, x!.constraint);
        elif IsRecord(x) and IsBound(x.con) then
            # TODO Make Vole refiners into proper refiner objects
            Add(refiners, x);
        elif IsInt(x) then
            Add(constraints, Constraint.LargestMovedPoint(x));
        elif IsPermGroup(x) then
            Add(constraints, Constraint.InGroup(x));
        elif IsRightCoset(x) and IsPermCollection(x) then
            Add(constraints, Constraint.InRightCoset(x));
        else
            ErrorNoReturn("Unrecognised");
        fi;
    od;

    # Remove duplicates
    extra := Unique(extra);

    # Perform further smart replacements
    for i in [1 .. Length(constraints)] do
        con := constraints[i];

        # In Alt(x) -> IsEven and MovedPoints(x)
        if IsGroupConstraint(con) and HasUnderlyingGroup(con) and IsNaturalAlternatingGroup(UnderlyingGroup(con)) then
            Add(constraints, Constraint.IsEven);
            constraints[i] := Constraint.MovedPoints(MovedPoints(UnderlyingGroup(con)));

        # In coset of Sym(x) -> combination
        elif IsInCosetByGensConstraint(con) and not IsGroupConstraint(con) and IsNaturalSymmetricGroup(UnderlyingGroup(con)) then
            G := UnderlyingGroup(con);
            x := Representative(con);
            movedG := MovedPoints(G);  # is a GAP set
            movedx := MovedPoints(x);
            differ := Difference(movedx, movedG);
            constraints[i] := Constraint.MovedPoints(Union(movedG, movedx));
            Add(constraints, Constraint.Transport(movedG, OnSets(movedG, x), OnSets));
            Add(constraints, Constraint.Transport(differ, OnTuples(differ, x), OnTuples));
        fi;
    od;

    # Make a consolidated "Constraint.MovedPoints" constraint
    points := Integers;
    for i in [Length(constraints), Length(constraints) - 1 .. 1] do
        x := constraints[i];
        if IsGroupConstraint(x) and HasUnderlyingGroup(x) then
            G := UnderlyingGroup(x);
            points := Intersection(points, MovedPoints(G));
            if IsNaturalSymmetricGroup(G) then
                Remove(constraints, i);
            fi;
        fi;
    od;
    for x in extra do
        if IsGroupConstraint(x) and HasUnderlyingGroup(x) then
            points := Intersection(points, MovedPoints(UnderlyingGroup(x)));
        fi;
    od;
    # TODO: Only really need to add this constraint if it is not implied by any of the remaining ones
    if IsFinite(points) then
        Add(constraints, Constraint.MovedPoints(points));
    fi;

    all := Concatenation(constraints, extra);
    if (Constraint.IsEven in constraints or Constraint.IsEven in extra) and (Constraint.IsOdd in constraints or Constraint.IsOdd in extra) then
        Add(constraints, Constraint.Nothing);
    fi;

    # Remove duplicates
    constraints := Unique(Filtered(constraints, x -> not x in extra));
    all := Concatenation(constraints, extra);

    sizes := List(Filtered(all, con -> IsGroupConstraint(con) and HasSize(con) and IsPosInt(Size(con))), Size);
    if IsEmpty(sizes) then
        bound := infinity;
    else
        bound := Gcd(sizes);
    fi;

    return rec(
        refiners := refiners,
        constraints_without_refiners := constraints,
        constraints_of_refiners := extra,
        is_known_empty := ForAny(all, con -> HasIsEmptyConstraint(con) and IsEmptyConstraint(con)),
        is_group := ForAll(all, IsGroupConstraint),
        group_size_bound := bound,
    );
end;
