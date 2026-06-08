# Vole: Backtrack search in permutation groups with graphs
# A GAP package by Mun See Chang, Christopher Jefferson, and Wilf A. Wilson.
#
# SPDX-License-Identifier: MPL-2.0
#
# Implementations: the generic "set of refiners" refiner.
#
# VoleRefiner.SetOf([r_1, ..., r_k]) builds a refiner for the SET of the
# objects that the member refiners r_i describe: a permutation p is accepted
# iff it maps { source(r_1), ..., source(r_k) } onto { result(r_1), ...,
# result(r_k) } AS A SET (the members may be reordered amongst themselves).
# When every member is a stabiliser this is the setwise stabiliser of the
# family; otherwise it is the set transporter. With normaliser/conjugacy
# members (action OnPoints on groups) it is the setwise stabiliser of a set of
# groups under conjugation.
#
# Unlike every other refiner, this one operates *on refiners*. It reads from
# each member:
#   - its graph encoding, via the member's refine hooks (the same filters the
#     member would push if run on its own); and
#   - its action and object(s), via the member's constraint (ActionFunc /
#     SourceObject / ResultObject).
#
# Per-node recall: a member may emit more graphs as points get fixed during
# search (e.g. a normaliser pushing orbital graphs of Stab(E, fixed) per node).
# OnSet forwards every search hook (initialise/fixed/changed, and rBaseFinished)
# to its members, re-wrapping whatever they emit at that node into the widget.
# Because Vole keeps OnSet's GAP-side partition on the real points (the widget's
# auxiliary vertices live only in the engine) and syncs it to the current
# partition before each hook, members see exactly the partition they would see
# standalone, so no partition translation is needed. Static members (sets,
# tuples, digraphs) emit everything at initialise and have no fixed/changed, so
# for them OnSet stays initialise-only.
#
# State: members carry their own backtracking state (e.g. btdata.seenDepth). The
# engine only saves OnSet's state, so OnSet owns its members' SaveState /
# RestoreState (see IsVoleSetOfRefiner below).
#
# Pruning: each node's per-member graphs are combined into a set-of-graphs
# widget whose Sym(Omega)-automorphism group contains the true setwise
# stabiliser (so refinement never discards a valid permutation), and accumulated
# by the engine across the search.
#
# Correctness: a candidate is accepted iff applying each member's own action and
# collecting the [type, image] pairs as a GAP set equals the target set. GAP
# represents a set {3,4} and a tuple [2,4] both as the plain list, so each image
# is tagged by its member's action: the family is type-aware (a set is never the
# same element as a tuple), matching what the widget encodes. This check is
# authoritative; the widget only accelerates the search.

# A refiner that owns a list of member refiners and delegates backtracking state
# to them (the engine only saves the outer refiner's state).
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

# Build the set-of-graphs widget for one side (source if buildingRBase, else
# result) from whatever each member emits via its `hook` (a refine field name:
# "initialise", "fixed" or "changed"). Returns a single refiner filter
# rec(graph, vertlabels); the empty list [] if no member emits anything at this
# node; or fail if any member is unsatisfiable on this side.
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
#                                   member moves as a unit; anchors of the same
#                                   member-type share a colour and may be
#                                   permuted, which is what lets the set be
#                                   reordered.
# Colours are stable hashes of structural keys (HashBasic), identical on both
# sides, so the same structure in different members matches and a member's type
# (its action) never matches a different type.
_Vole.SetOfRefinersGraph := function(ps, refiners, buildingRBase, hook)
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
        type := NameFunction(ActionFunc(refiners[i]!.constraint));
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
    for i in [1 .. k] do
        if memberHasPiece[i] then
            labels[anchors[i]] := AbsInt(HashBasic(["anchor",
                NameFunction(ActionFunc(refiners[i]!.constraint))]));
        fi;
    od;

    # Each piece: a private copy of its graph. Real-point copies (j <= n) glue
    # back to the shared point; every copy ties to its member's anchor, so the
    # member moves as a unit and members of the same type may be permuted.
    # Copy colours carry the action type, the aux/real flag and the piece's
    # vertex label, but NOT the member index, so equal structure in different
    # members matches.
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

VoleRefiner.SetOf := function(refiners)
    local memberCons, typeOf, seen, dedup, key, i, srcSet, resSet, action,
          constraint, lrp, members, refine, obj;

    if not (IsList(refiners) and not IsEmpty(refiners)
            and ForAll(refiners, IsRefiner)) then
        ErrorNoReturn("VoleRefiner.SetOf: <refiners> must be a nonempty ",
                      "list of refiners");
    fi;
    if not ForAll(refiners,
                  r -> IsBound(r!.refine) and IsBound(r!.refine.initialise)) then
        ErrorNoReturn("VoleRefiner.SetOf: every member refiner must expose a ",
                      "refine.initialise hook (e.g. a BacktrackKit or ",
                      "GraphBacktracking refiner; a native Vole refiner builds ",
                      "its graph in Rust and cannot be a member)");
    fi;
    memberCons := List(refiners, r -> r!.constraint);
    if not ForAll(memberCons, IsTransporterConstraint) then
        ErrorNoReturn("VoleRefiner.SetOf: every member refiner must describe ",
                      "the stabiliser or transporter of an object under a ",
                      "group action");
    fi;

    # Each member is tagged by its action (e.g. "OnSets", "OnTuples",
    # "OnPoints"). GAP represents a set {3,4} and a tuple [2,4] both as the
    # plain list, so an untagged set image could be considered equal to a tuple
    # image. We treat the family as TYPE-AWARE: a set is never the same family
    # element as a tuple. This is also what the widget encodes (members of
    # different action types get distinct vertex/anchor colours), so check and
    # widget agree.
    typeOf := c -> NameFunction(ActionFunc(c));

    # The family is a SET, so members describing the identical typed object
    # (same type, source and result) are redundant. They must be removed:
    # keeping them would make the widget enforce multiset rather than set
    # semantics (it would demand that a repeated object map to a repeated
    # object), which can exclude a genuine solution.
    seen := [];
    dedup := [];
    for i in [1 .. Length(refiners)] do
        key := [typeOf(memberCons[i]), SourceObject(memberCons[i]),
                ResultObject(memberCons[i])];
        if not key in seen then
            Add(seen, key);
            Add(dedup, refiners[i]);
        fi;
    od;
    members := dedup;
    memberCons := List(members, r -> r!.constraint);

    srcSet := Set(memberCons, c -> [typeOf(c), SourceObject(c)]);
    resSet := Set(memberCons, c -> [typeOf(c), ResultObject(c)]);
    # The action applies each member's own action (via the closed-over member
    # constraints) and returns a GAP set of [type, image] pairs. It ignores its
    # first argument: the constraint always supplies SourceObject, and the
    # per-member objects live in the closure.
    action := function(x, p)
        return Set(memberCons, c -> [typeOf(c), ImageFunc(c)(p)]);
    end;
    # When srcSet = resSet (as GAP sets) this is a stabiliser, and
    # Constraint.Transport marks it as a group constraint, as required by
    # VoleFind.Group; otherwise it is a coset/transporter.
    constraint := Constraint.Transport(srcSet, resSet, action);

    lrp := Maximum(List(members, r -> r!.largest_required_point));

    # Forward each search hook the members actually use. Static members have
    # only initialise, so OnSet then stays initialise-only.
    refine := rec(
        initialise := function(ps, buildingRBase)
            return _Vole.SetOfRefinersGraph(ps, members, buildingRBase,
                                            "initialise");
        end,
    );
    if ForAny(members, r -> IsBound(r!.refine.fixed)) then
        refine.fixed := function(ps, buildingRBase)
            return _Vole.SetOfRefinersGraph(ps, members, buildingRBase, "fixed");
        end;
    fi;
    if ForAny(members, r -> IsBound(r!.refine.changed)) then
        refine.changed := function(ps, buildingRBase)
            return _Vole.SetOfRefinersGraph(ps, members, buildingRBase,
                                            "changed");
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
        name := "Vole_SetOf",
        largest_required_point := lrp,
        constraint := constraint,
        members := members,
        refine := refine,
    );
    return Objectify(VoleSetOfRefinerType, obj);
end;
