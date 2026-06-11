# Vole: Backtrack search in permutation groups with graphs
# A GAP package by Mun See Chang, Christopher Jefferson, and Wilf A. Wilson.
#
# SPDX-License-Identifier: MPL-2.0
#
# Implementations: the generic "set / multiset / tuple of refiners" combinators.
#
# These build a refiner *out of other refiners*. Unlike BTKit_Refiner.SetStab /
# TupleStab (which act on a concrete set or tuple of points), these act on the
# objects that their MEMBER refiners describe, of whatever kind:
#
#   VoleRefiner.SetOf([r_1, ..., r_k])
#     a permutation p is accepted iff it maps the SET
#       { source(r_1), ..., source(r_k) }  onto  { result(r_1), ..., result(r_k) }
#     i.e. the members may be reordered amongst themselves. SetOf is a genuine
#     SET combinator: duplicate members (members describing the identical typed
#     object) are rejected with an error, not silently merged -- see the
#     duplicate check in _Vole.CombinedRefiner. Use VoleRefiner.MultisetOf if
#     repeats are intended.
#
#   VoleRefiner.MultisetOf([r_1, ..., r_k])
#     as SetOf, but the family is a MULTISET: repeated objects are kept (the
#     [type, image] pairs are gathered with SortedList rather than Set, so an
#     object's multiplicity is part of the family element), and p must preserve
#     those multiplicities.
#
#   VoleRefiner.TupleOf([r_1, ..., r_k])
#     a permutation p is accepted iff it maps each source(r_i) to result(r_i)
#     IN ORDER (position i to position i). Standalone this is merely the
#     intersection of the members and is of little use on its own; its purpose
#     is to be a MEMBER of a SetOf/MultisetOf, so that one can express a
#     (multi)set of tuples, e.g. SetOf([TupleOf([a, b]), TupleOf([c, d])]) is
#     the set { [a,b], [c,d] } of ordered pairs (the pairs may be swapped, but a
#     and b may not).
#
# When every member is a stabiliser, SetOf is the setwise stabiliser of the
# family; otherwise it is the set transporter. With normaliser/conjugacy members
# (action OnPoints on groups) SetOf is the setwise stabiliser of a set of groups
# under conjugation; a TupleOf of such members inside a SetOf is a set of tuples
# of groups under simultaneous conjugation.
#
# All three combinators operate *on refiners*. They read from each member:
#   - its graph encoding, via the member's refine hooks (the same filters the
#     member would push if run on its own); and
#   - its action and object(s), via the member's constraint (ActionFunc /
#     SourceObject / ResultObject).
#
# Per-node recall: a member may emit more graphs as points get fixed during
# search (e.g. a normaliser pushing orbital graphs of Stab(E, fixed) per node).
# The combinator forwards every search hook (initialise/fixed/changed, and
# rBaseFinished) to its members, re-wrapping whatever they emit at that node
# into the widget. Because Vole keeps the combinator's GAP-side partition on the
# real points (the widget's auxiliary vertices live only in the engine) and
# syncs it to the current partition before each hook, members see exactly the
# partition they would see standalone, so no partition translation is needed.
# Static members (sets, tuples, digraphs) emit everything at initialise and have
# no fixed/changed, so for them the combinator stays initialise-only.
#
# Members may themselves be SetOf/TupleOf refiners: the machinery is recursive.
# A member's whole graph (its own combined widget) is embedded as one piece, so
# a nested combinator moves as a unit inside the outer one.
#
# State: members carry their own backtracking state (e.g. btdata.seenDepth). The
# engine only saves the combinator's state, so the combinator owns its members'
# SaveState / RestoreState (see IsVoleSetOfRefiner below); nested combinators
# recurse through the same methods.
#
# Pruning: each node's per-member graphs are combined into a widget whose
# Sym(Omega)-automorphism group contains the true (setwise/tuplewise)
# stabiliser (so refinement never discards a valid permutation), and accumulated
# by the engine across the search.
#
# Correctness: a candidate is accepted iff applying each member's own action and
# collecting the [type, image] pairs (as a GAP set for SetOf, a sorted list with
# repeats for MultisetOf, an ordered list for TupleOf) equals the target. GAP
# represents a set {3,4} and a tuple [2,4]
# both as the plain list, so each image is tagged by its member's TYPE (see
# _Vole.RefinerTypeTag): a set is never identified with a tuple, a tuple never
# with a sub-set, etc. This check is authoritative; the widget only accelerates
# the search.

# The type tag of a member refiner. This must satisfy: two members that should
# be interchangeable inside a SetOf get EQUAL tags, and two members of genuinely
# different element-kind (set vs tuple vs sub-set vs sub-tuple ...) get DISTINCT
# tags. For a primitive BTKit/GB refiner the action function is a named global
# (OnSets, OnTuples, OnDigraphs, OnPoints, ...), so its NameFunction is exactly
# the kind. For a composite (SetOf/TupleOf) the action is an anonymous closure
# whose NameFunction is just its local variable name -- the same for every
# composite, which would WRONGLY merge a sub-set with a sub-tuple -- so a
# composite carries an explicit, structural setof_typetag instead.
_Vole.RefinerTypeTag := function(r)
    if IsBound(r!.setof_typetag) then
        return r!.setof_typetag;
    fi;
    return NameFunction(ActionFunc(r!.constraint));
end;

# A refiner that owns a list of member refiners and delegates backtracking state
# to them (the engine only saves the outer refiner's state). Both SetOf and
# TupleOf use this type; nested combinators recurse through these methods.
if not IsBound(VoleSetOfRefinerType) then
    DeclareRepresentation("IsVoleSetOfRefiner", IsGBRefiner, []);
    BindGlobal("VoleSetOfRefinerType",
               NewType(BacktrackableStateFamily, IsVoleSetOfRefiner));
fi;

InstallMethod(SaveState, [IsVoleSetOfRefiner],
    con -> List(con!.members, SaveState));

InstallMethod(RestoreState, [IsVoleSetOfRefiner, IsObject],
    function(con, saved)
        local i;
        for i in [1 .. Length(con!.members)] do
            RestoreState(con!.members[i], saved[i]);
        od;
    end);

# Build the combined widget for one side (source if buildingRBase, else result)
# from whatever each member emits via its `hook` (a refine field name:
# "initialise", "fixed" or "changed"). `ordered` selects SetOf (false: members
# of equal type interchangeable) or TupleOf (true: each position pinned).
# Returns a single refiner filter rec(graph, vertlabels); the empty list [] if
# no member emits anything at this node; or fail if any member is unsatisfiable
# on this side.
#
# Vertex layout of the widget:
#   1 .. n                          the shared real points (the search domain).
#   per member i, a private block:
#     Vsizes[i] copy vertices       a private copy of the member's own graph,
#                                   with copy-of-real-point j glued back to the
#                                   shared point j (so the member tracks the
#                                   real points), plus any auxiliary vertices
#                                   the member's encoding introduces.
#     1 anchor vertex               every copy vertex points at it, so the
#                                   member moves as a unit. For SetOf, anchors of
#                                   the same member-type share a colour and may
#                                   be permuted, which lets the set be reordered.
#                                   For TupleOf, each anchor's colour encodes its
#                                   POSITION, so no two positions may be swapped.
# Colours are stable hashes of structural keys (HashBasic), identical on both
# sides, so the same structure in different members matches and a member's type
# (its type tag) never matches a different type.
_Vole.CombinedRefinersGraph := function(ps, refiners, buildingRBase, hook,
                                        ordered)
    local n, k, pieces, memberHasPiece, any, i, fil, type, f, vlab, cur,
          anchors, N, adj, labels, pc, j, e, val;

    n := PS_Points(ps);
    k := Length(refiners);

    # Collect "pieces": each filter a member emits at this node becomes one
    # piece. A graph record and a vertex-colouring function are each kept as a
    # SEPARATE piece (the engine never merges distinct pushed graphs, and each
    # has its own auxiliary-vertex numbering, so they must not share a copy
    # block). A colouring function f becomes a piece on the n real points with
    # vertex labels f(1..n) and no edges.
    pieces := [];
    memberHasPiece := List([1 .. k], i -> false);
    any := false;
    for i in [1 .. k] do
        if IsBound(refiners[i]!.refine.(hook)) then
            fil := refiners[i]!.refine.(hook)(ps, buildingRBase);
        else
            fil := [];
        fi;
        if fil = fail then
            return fail;
        fi;
        if not IsList(fil) then
            fil := [fil];
        fi;
        type := _Vole.RefinerTypeTag(refiners[i]);
        for f in fil do
            if IsFunction(f) then
                Add(pieces, rec(member := i, type := type, V := n, edges := [],
                                vlab := List([1 .. n], x -> f(x))));
                memberHasPiece[i] := true;
                any := true;
            elif IsRecord(f) and IsBound(f.graph) then
                if IsBound(f.vertlabels) then vlab := f.vertlabels;
                                          else vlab := fail; fi;
                Add(pieces, rec(member := i, type := type,
                                V := DigraphNrVertices(f.graph),
                                edges := DigraphEdges(f.graph), vlab := vlab));
                memberHasPiece[i] := true;
                any := true;
            fi;
        od;
    od;

    # Nothing new at this node: emit no graph (an empty widget would impose a
    # spurious constraint).
    if not any then
        return [];
    fi;

    # Layout: vertices 1..n are the shared real points; then one anchor per
    # member that emitted a piece; then each piece's private copy vertices.
    cur := n;
    anchors := [];
    for i in [1 .. k] do
        if memberHasPiece[i] then
            cur := cur + 1;
            anchors[i] := cur;
        fi;
    od;
    for pc in pieces do
        pc.offset := cur;
        cur := cur + pc.V;
    od;
    N := cur;

    adj := List([1 .. N], x -> []);
    labels := [];
    for j in [1 .. n] do
        labels[j] := AbsInt(HashBasic(["point"]));
    od;
    # Anchor colours. SetOf: by member type, so equal-type members are
    # interchangeable. TupleOf: by position i, so every position is pinned and no
    # two positions may be swapped (even members of identical type).
    for i in [1 .. k] do
        if memberHasPiece[i] then
            if ordered then
                labels[anchors[i]] := AbsInt(HashBasic(["anchor-pos", i]));
            else
                labels[anchors[i]] := AbsInt(HashBasic(["anchor",
                    _Vole.RefinerTypeTag(refiners[i])]));
            fi;
        fi;
    od;

    # Each piece: a private copy of its graph. Real-point copies (j <= n) glue
    # back to the shared point; every copy ties to its member's anchor, so the
    # member moves as a unit. Copy colours carry the type tag, the aux/real flag
    # and the piece's vertex label, but NOT the member index, so equal structure
    # in different members matches; for TupleOf the position-distinct anchors
    # then prevent any swap.
    for pc in pieces do
        for j in [1 .. pc.V] do
            if pc.vlab = fail then val := 0;
                               else val := GetWithDefault(pc.vlab, j, 0); fi;
            labels[pc.offset + j] :=
                AbsInt(HashBasic(["copy", pc.type, j > n, val]));
            if j <= n then
                Add(adj[pc.offset + j], j);
            fi;
            Add(adj[pc.offset + j], anchors[pc.member]);
        od;
        for e in pc.edges do
            Add(adj[pc.offset + e[1]], pc.offset + e[2]);
        od;
    od;

    adj := List(adj, DuplicateFreeList);
    return rec(graph := Digraph(adj), vertlabels := labels);
end;

# Shared constructor for both combinators. `ordered` is false for SetOf (set
# semantics: members may be reordered, duplicates rejected) and true for TupleOf
# `mode` is one of the records defined just below VoleRefiner.SetOf, and selects
# the family kind. Its fields are:
#   name             the public function name, for error messages.
#   ordered          passed to the widget builder; false for set/multiset (equal-
#                    type members interchangeable), true for tuple (positions
#                    pinned).
#   collect          how the [type, image] pairs are gathered into the family
#                    element: Set for a set (sorted, duplicates dropped),
#                    SortedList for a multiset (sorted, duplicates kept), or the
#                    identity for a tuple (in member order).
#   rejectDuplicates true only for a set, where a repeated object is a user
#                    error (see below); false for a multiset or tuple, where
#                    repeats are meaningful.
#   tagOpen/tagClose bracket the structural type tag, and must differ between
#                    kinds so that, e.g., a sub-set is never confused with a
#                    sub-multiset of the same members.
_Vole.CombinedRefiner := function(refiners, mode)
    local memberCons, memberTypes, i, j, members, types, srcObj, resObj, action,
          constraint, lrp, tag, refine, obj;

    if not (IsList(refiners) and not IsEmpty(refiners)
            and ForAll(refiners, IsRefiner)) then
        ErrorNoReturn(mode.name,
                      ": <refiners> must be a nonempty list of refiners");
    fi;
    if not ForAll(refiners,
                  r -> IsBound(r!.refine) and IsBound(r!.refine.initialise)) then
        ErrorNoReturn(mode.name, ": every member refiner must expose a ",
                      "refine.initialise hook (e.g. a BacktrackKit or ",
                      "GraphBacktracking refiner, or a nested VoleRefiner ",
                      "combinator; a native Vole refiner builds its graph in ",
                      "Rust and cannot be a member)");
    fi;
    memberCons := List(refiners, r -> r!.constraint);
    if not ForAll(memberCons, IsTransporterConstraint) then
        ErrorNoReturn(mode.name, ": every member refiner must describe the ",
                      "stabiliser or transporter of an object under a group ",
                      "action");
    fi;

    members := refiners;
    # The type tag of each member (see _Vole.RefinerTypeTag). GAP represents a
    # set {3,4} and a tuple [2,4] both as the plain list, so an untagged set
    # image could be considered equal to a tuple image. We treat the family as
    # TYPE-AWARE: a set is never the same family element as a tuple, nor a
    # nested set the same as a nested multiset. This is also what the widget
    # encodes (members of different type get distinct vertex/anchor colours), so
    # check and widget agree.
    memberTypes := List(members, _Vole.RefinerTypeTag);

    if mode.rejectDuplicates then
        # A SET is not a multiset: two members describing the identical typed
        # object (same type, source and result) are the same set element. We
        # REJECT them with an error rather than silently merging, so the user is
        # never misled into thinking a repeated object is respected. If repeats
        # are intended, VoleRefiner.MultisetOf keeps them.
        for i in [1 .. Length(members)] do
            for j in [i + 1 .. Length(members)] do
                if memberTypes[i] = memberTypes[j]
                   and SourceObject(memberCons[i]) = SourceObject(memberCons[j])
                   and ResultObject(memberCons[i])
                       = ResultObject(memberCons[j]) then
                    ErrorNoReturn(mode.name, ": members ", i, " and ", j,
                        " describe the same object, but a set does not accept ",
                        "duplicate members; remove the duplicate, or use ",
                        "VoleRefiner.MultisetOf to keep repeated objects");
                fi;
            od;
        od;
    fi;

    # The source/result objects and the action. mode.collect turns the list of
    # [type, image] pairs into the family element: a set, a multiset (sorted with
    # repeats), or a tuple (in member order). Each image is tagged by its
    # member's type tag so the family is type-aware. The action ignores its first
    # argument: the per-member objects live in the closure.
    srcObj := mode.collect(List([1 .. Length(members)],
                  i -> [memberTypes[i], SourceObject(memberCons[i])]));
    resObj := mode.collect(List([1 .. Length(members)],
                  i -> [memberTypes[i], ResultObject(memberCons[i])]));
    action := function(x, p)
        return mode.collect(List([1 .. Length(members)],
                   i -> [memberTypes[i], ImageFunc(memberCons[i])(p)]));
    end;
    # When srcObj = resObj this is a stabiliser, and Constraint.Transport marks
    # it as a group constraint, as required by VoleFind.Group; otherwise it is a
    # coset/transporter.
    constraint := Constraint.Transport(srcObj, resObj, action);

    # A structural type tag for this composite, so that when it is itself a
    # member of another combinator it gets a stable, kind-distinct type (see
    # _Vole.RefinerTypeTag). For an unordered kind the member types are sorted so
    # that reordering the members does not change the tag.
    if mode.ordered then types := memberTypes;
                     else types := SortedList(memberTypes); fi;
    tag := Concatenation(mode.tagOpen,
               JoinStringsWithSeparator(types, ","), mode.tagClose);

    lrp := Maximum(List(members, r -> r!.largest_required_point));

    # Forward each search hook the members actually use. Static members have
    # only initialise, so the combinator then stays initialise-only.
    refine := rec(
        initialise := function(ps, buildingRBase)
            return _Vole.CombinedRefinersGraph(ps, members, buildingRBase,
                                               "initialise", mode.ordered);
        end,
    );
    if ForAny(members, r -> IsBound(r!.refine.fixed)) then
        refine.fixed := function(ps, buildingRBase)
            return _Vole.CombinedRefinersGraph(ps, members, buildingRBase,
                                               "fixed", mode.ordered);
        end;
    fi;
    if ForAny(members, r -> IsBound(r!.refine.changed)) then
        refine.changed := function(ps, buildingRBase)
            return _Vole.CombinedRefinersGraph(ps, members, buildingRBase,
                                               "changed", mode.ordered);
        end;
    fi;
    if ForAny(members, r -> IsBound(r!.refine.rBaseFinished)) then
        refine.rBaseFinished := function(rbase)
            local m;
            for m in members do
                if IsBound(m!.refine.rBaseFinished) then
                    m!.refine.rBaseFinished(rbase);
                fi;
            od;
        end;
    fi;

    obj := rec(
        name := tag,
        largest_required_point := lrp,
        constraint := constraint,
        members := members,
        setof_typetag := tag,
        refine := refine,
    );
    return Objectify(VoleSetOfRefinerType, obj);
end;

# A SET of the objects the member refiners describe; the members may be
# reordered. Duplicate members are rejected (use MultisetOf to keep repeats).
VoleRefiner.SetOf := refiners -> _Vole.CombinedRefiner(refiners, rec(
    name := "VoleRefiner.SetOf", ordered := false, collect := Set,
    rejectDuplicates := true, tagOpen := "Vole_SetOf{", tagClose := "}"));

# A MULTISET of the objects the member refiners describe; the members may be
# reordered, and repeated objects are kept (collected with SortedList rather
# than Set, so multiplicity is part of the family element).
VoleRefiner.MultisetOf := refiners -> _Vole.CombinedRefiner(refiners, rec(
    name := "VoleRefiner.MultisetOf", ordered := false, collect := SortedList,
    rejectDuplicates := false, tagOpen := "Vole_MultisetOf{", tagClose := "}"));

# An ordered TUPLE of the objects the member refiners describe; position i is
# pinned. Of little use standalone; its purpose is to be a member of a SetOf or
# MultisetOf, so that one may express a (multi)set of tuples.
VoleRefiner.TupleOf := refiners -> _Vole.CombinedRefiner(refiners, rec(
    name := "VoleRefiner.TupleOf", ordered := true, collect := x -> x,
    rejectDuplicates := false, tagOpen := "Vole_TupleOf[", tagClose := "]"));
