# Normaliser refiner: research notes

These notes summarise everything learned in preparation for building a serious
normaliser refiner in Vole. They cover what GAP currently does (in
`lib/stbcbckt.gi`), what Vole already has, and what the literature says.

The goal of this document is to be a reference while we design and implement.
It is not a design document — algorithmic choices belong in code or a PR.

Document conventions: `Ω` is the point set (degree `n`), `G ≤ Sym(Ω)` the
ambient group inside which we search, and `H ≤ G` the subgroup whose
normaliser `N_G(H)` we want. "PB" = partition backtrack; "GB" = graph
backtracking.


## 1. GAP's normaliser, end to end

Entry point: `NormalizerPermGroup(G, E [, L])` at `lib/stbcbckt.gi:2652`.
The real work is in `DoNormalizerPermGroup` at `:2616`. The flow:

```
NormalizerPermGroup
  → maybe NormalizerViaRadical (if G has Fitting-free lift and big radical)
  → if G is intransitive on its support, reduce orbit-by-orbit (the loop at :2705)
  → DoNormalizerPermGroup(G, E, L, Ω):
        Pr := gen -> ForAll(gens(E), g -> g^gen in E)
        B  := OrbitsPartition(E, Ω)
        rbase := RBaseGroupsBloxPermGroup(false, G, Ω, E, div, B)
        data  := [true, E, [], B, []]
        N := PartitionBacktrack(G, Pr, false, rbase, data, L, L)
```

So at the highest level, the normaliser uses the same `PartitionBacktrack`
machinery as set stabiliser, centraliser, intersection — it is *not* a
separate algorithm. What makes the normaliser case special is two things:

1. The initial ordered partition is `OrbitsPartition(E, Ω)` — orbits of the
   group being normalised, not the trivial partition.
2. The `rbase.nextLevel` function (built in `RBaseGroupsBloxPermGroup` at
   `:1969`) registers a battery of refinements computed from `E` at each
   level: suborbits, orbital partitions, blocks ("blox"), regular orbit
   refinements. These are stored as a recipe of `Refinements.*` calls.

The same recipe is then played back inside `PartitionBacktrack` at each node
of the search tree — `RRefine` (`:1026`) calls each `Refinements.<func>` on
the *image side* partition, which is the cheap part.


### 1.1 The refinements in `Refinements`

All in `stbcbckt.gi`. The string names are bound to functions at lines `:1556`
to `:1864`.

- `ProcessFixpoint` (`:1556`) — propagate a new fixed point.
- `Intersection` (`:1569`) — used in the intersection case (when we have
  `[G, G2]` instead of one group). Not directly used for normaliser.
- `Centralizer` (`:1589`) — used by `RepOpElmTuplesPermGroup` (centraliser /
  conjugacy of element tuples), not by normaliser per se.
- `_MakeBlox` (`:1604`) — at the image side, compute a block system of `E`
  with respect to the chosen base pair, and check the cell-length profile
  matches the rbase. This is one of the two main pruning sources.
- `SplitOffBlock` (`:1620`) — split off a block whose image is known.
- `_RegularOrbit1/2/3` (`:1639`, `:1674`, `:1706`) — applies when `E` has a
  regular orbit. Once `s` images are known (where `s = #generators(E)`), the
  entire regular orbit's image is determined. Theißen, thesis §3.7. Realised
  through `NextLevelRegularGroups` (`:1871`).
- `Suborbits0..3` (`:1744`–`:1850`) — the Theißen orbital-graph refinements.
  These are the main reason GAP beats trivial backtrack for normalisers.
- `TwoClosure` (`:1854`) — used when `G` happens to be 2-closed.

The "graph" data that GAP uses lives inside the `Suborbits` record (`:416`).
It is keyed by the fixpoint `α` and produces:

- the **suborbit partition** of `Ω` under `E_α` (`subs.partition`, refined to
  unions of suborbits of equal length);
- on demand, an **OrbitalPartition** (`:624`) computed by a flooding algorithm
  on a single orbital graph (or a union of orbital graphs of equal-length
  suborbits): vertices are coloured by their distance pattern in the orbital
  graph, and the resulting colour classes give a partition refinement.

Both are caches per `(α, Ω)` on `H!.suborbits`.

### 1.2 Crucial point: GAP **does** use orbital graphs, but only as partitions

This is the key thing to get right when contrasting with Vole. GAP doesn't
*keep* the orbital graph around as a graph: each orbital graph is collapsed
into a partition by `OrbitalPartition`, and that partition is fed into the
partition stack via `MeetPartitionStrat`. The information about *which arc
goes where* is thrown away as soon as the partition is computed. If two
orbital graphs happen to induce the same partition, refining by one is the
same as refining by the other.

This is exactly the partition-vs-graph distinction that `[JPWW21]` makes,
and it is the leverage point for Vole.

### 1.3 Theißen §3.7 in detail (regular-orbit base-point order)

GAP's `stbcbckt.gi` cites this section by name twice — in comments on
`NextLevelRegularGroups` at lines `:1879` and `:1925`. The thesis itself
([The97], "Eine Methode zur Normalisatorberechnung in Permutationsgruppen
mit Anwendungen in der Konstruktion primitiver Gruppen", Aachener
Beiträge zur Mathematik Bd. 21, Verlag der Augustinus-Buchhandlung,
1997) was published as a physical book and **never digitised**. It is in
the DNB catalogue as a Hochschulschrift only, the publisher (Verlag
Mainz, formerly Augustinus) sells physical copies only, and it does not
appear on archive.org, Google Scholar, ResearchGate, or RWTH's
repository. Citation count in Google Scholar: 44. So we reconstruct the
algorithm from GAP's implementation, helped by the descriptions in
[Cha21] §2.3–2.4 and [JPWW21] §1.

If we want the original, the realistic options are interlibrary loan
from RWTH's library or direct contact with Theißen (who is no longer in
academic mathematics) — but we don't need to: the GAP implementation
faithfully realises §3.7 and Theißen's comments inside that
implementation are basically the algorithm's spec.

#### The mathematical idea

Let `F ≤ Sym(Ω)` be a group that acts *regularly* on one of its orbits
`O = {ω₁, …, ω_m}`, so `m = |F|`. Concretely, every point of `O` is
`ω₁^h` for a unique `h ∈ F`, and `F_{ω₁} = 1`. Two consequences that
the algorithm leans on:

1. **Determination from a generating set.** If `F = ⟨h₁, …, h_s⟩` and we
   know the images `ω₁^h_i` for `i = 1, …, s`, we know `F` as an action
   on `O` (we know the Schreier tree built from the `h_i`). For a
   candidate normaliser element `g ∈ Sym(Ω)`, knowing `g(ω₁)` and
   `g(ω₁^h_i)` for each generator `h_i` is enough to determine `g` on
   *all* of `O`: extending `(h_i)^g` by the regular action gives the
   image of every other point.

2. **Propagation to non-regular orbits.** Let `y ∈ Ω` be a point in some
   other `F`-orbit and let the `F`-orbit of `y` be `{y^h : h ∈ F}` (not
   necessarily of length `m`; the stabiliser may be non-trivial). Given
   the image `g(y)` and the image `g(ω₁^h)` for any `h ∈ F`, we can
   recover the image `g(y^h) = g(y)^{h^g}`, because `h^g` is the unique
   element of `F^g = F` that maps `g(ω₁)` to `g(ω₁^h)`, and on the
   `y`-orbit we apply that same element. So fixing the regular orbit
   pins down every other orbit pointwise once we have *one* fixpoint in
   that other orbit.

So the algorithm rearranges the rbase so that:
- the first `s + 1` rbase points are inside the regular orbit, chosen so
  that they walk a Schreier tree of `F`;
- after those `s + 1` points are fixed (and only those), every other
  point of `O` becomes a forced fixpoint of the rbase partition;
- for any later rbase point `y` in another orbit, *all* of `y^F` becomes
  forced too.

The pruning win: a "generic" rbase would branch over all of `O` at
each visit (`m` branches), and the same for each other orbit. With the
regular-orbit rbase, the search branches at most `s + 1` times on `O` —
the rest is deduction, not search.

#### GAP's implementation of §3.7

Trigger condition (`RBaseGroupsBloxPermGroup`, `:2015`–`:2035`): either
`E` has a regular orbit on `Ω`, or `E` is primitive and has an
elementary abelian regular normal subgroup (the *socle of an affine
primitive group* — `STBCTEARNS`). In case (a), `rbase.reggrp` returns
`E` itself; in case (b), it returns the Earns. The rest of the
algorithm doesn't care which case applies: it just needs *some* regular
action.

`rbase.regorb` is a Schreier tree of `F = rbase.reggrp` on its regular
orbit, with generators those of `F`.

**rbase-side construction (`NextLevelRegularGroups`, `:1871`).**

At depth `d`:

- *Depth 1*: pick the regular orbit's first listed point `ω₁` as the
  first base point. Initialise `tree[1]` as the trivial Schreier tree
  `{ω₁}` of the trivial group inside `F`. Emit refinement
  `RegularOrbit1` with args `(1, 1)`.
- *Depth d > 1*: if the current tree `tree[d-1]` is shorter than
  `|F|` (i.e. we haven't pinned `F` yet), pick the first point of
  `rbase.regorb.orbit` that is *not yet a singleton cell* and *not
  fixed by the current stabiliser chain level*. Call it `b`. Register
  `b` as the new rbase point. Extend `tree[d-1]` to `tree[d]` by adding
  the generator `gen := (regorb-inverse-rep for b)^(-1)` — this is
  precisely the element of `F` taking `ω₁` to `b`. Emit
  `RegularOrbit1` with args `(d, |tree[d].orbit|)`.

  Then *deduce*: every point of `tree[d].orbit` is now `ω₁^{h_i}` for
  some `h_i` in `⟨already-known generators⟩`. So inside the rbase
  partition we can isolate each of these points; do so, record the
  cell number in `strat`, and if that cell becomes a singleton, also
  isolate the partner-fixpoint and record it as `[-p, j]`. Emit
  `RegularOrbit2(d, tree[d].orbit, strat)`.

- If the tree has length `|F|` already (we've pinned the entire regular
  group), fall through to `NextRBasePoint` (standard cell-size rbase
  selection).

After the regular-orbit segment, propagate to other orbits — the
"`y` for `γ`" part at `:1925`. For each fixpoint `y` of the partition
that hasn't been processed yet, build a Schreier tree `S` rooted at `y`
using `F`'s generators (so `S.orbit = y^F`). For every `yh ∈ S.orbit`,
let `h = inverse-rep(S, yh) ∈ F`, and let `bh = ω₁^{h^{-1}}` (note:
`PreImageWord` applied to the trivial regorb base point inverts). If
`bh` is *already* a fixpoint of the rbase partition (cell length 1),
then the image of `yh` is forced and we can isolate it; record this in
`strat`. Emit `RegularOrbit3(f, strat)`.

**image-side refinements (`Refinements.{_RegularOrbit1, RegularOrbit2,
RegularOrbit3}`).** These replay the deductions on the image partition:

- `_RegularOrbit1` (`:1644`): build (or extend) the image-side Schreier
  tree from the image of the rbase base point under the candidate.
  *Pruning*: if at depth 1 the orbit of `image.regorb` doesn't have the
  same length as `rbase.regorb` (so `F` doesn't have a regular orbit of
  matching size at the image), fail. At depth `d > 1`, if extending the
  tree by the candidate generator gives a wrong-sized tree, fail.
- `RegularOrbit2` (`:1684`): replay the `(i, j)` and `(-p, j)`
  deductions from the rbase strategy on the image partition. If a
  candidate orbit point can't be isolated into cell `j`, fail.
- `RegularOrbit3` (`:1716`): replay the `(yh, i, j)` deductions —
  compute `yhg = preimage-word(yg, h^g)` and isolate into cell `j`. If
  that fails, fail.

The leading underscore on `_RegularOrbit1` matters: refinements with a
leading underscore are run by `RRefine` (`:1026`) *even* on the
left-most branch where image = base, because they have side effects on
`image.data` and `image.regorb` that subsequent levels need. This is
how the image-side Schreier tree gets built up incrementally as we
descend the left-most branch.

#### Why this gives a different search shape

Without §3.7, the rbase picks cells by a heuristic on cell sizes
(`NextRBasePoint`). The search then branches over each cell choice, and
the cells inside the regular orbit `O` look exactly like any other
cell: `m` branches per visit. The cell-length partition refinement at
each node helps a bit (it knows two equal-size orbits can't go to
non-matching cells) but doesn't exploit the regularity at all.

With §3.7, base points are forced into `O` in Schreier-tree order. The
first base point in `O` is free (every other point in `O` is a possible
image, so `m` branches). The next is also free relative to the action
of `F^g`, but only `m` choices remain consistent with the partition
refinements. Crucially, **after `s+1` base points the entire orbit
collapses to fixpoints** — no further branches in `O` — and any new
fixpoint in *any other orbit* collapses *that* orbit too.

For `E = F` regular on the whole of `Ω` (a Cayley action), this means
the search has total branching factor `≤ m · (m-1) · … · (m-s)` — the
"choose `s+1` ordered points in `O`" count — instead of `m!`. For `E`
affine with socle `F`, the search lives inside `Sym(socle-orbit)` for
those first `s+1` steps and then collapses.

### 1.4 The base-point order for normalisers (general case)

`RBaseGroupsBloxPermGroup` (`:1990`–`:2003`) picks the *order* of base
points heuristically:

```gap
order := Maximum( List( GeneratorsOfGroup( E ), Order ) );
if 2 * order < n  then  order := Cell( B, l );    # cell with shortest length
                  else  order := Cell( B, L );    # cell with longest length
```

i.e. it prefers small `E`-orbits when the order of `E` is small relative to
`n`, otherwise large `E`-orbits. There's no deep theory behind this; it is a
heuristic. The actual selection within the chosen cell is left to
`NextRBasePoint` (`:968`), which then prefers cells of length > 1 not fixed
by the current stabiliser. For normalisers, GAP *biases* the rbase
construction by `E`'s orbit structure even outside §3.7.

### 1.5 Outer wrapper: orbit-by-orbit reduction

`NormalizerPermGroup` (`:2692`) detects intransitivity in `G` and tries
to find normalisers one orbit (or small union of orbits) at a time, via
`ActionHomomorphism`. Each successful pass shrinks `G` before the next pass.
If `G` is `IsNormal(E)` early it short-circuits. The expensive call to
`DoNormalizerPermGroup` on the whole of `Ω` happens only if no orbit gives a
proper reduction — see `:2755`.

This wrapper is **independent of the partition-backtrack core** and is a
cheap algorithmic win that we should reuse in Vole, irrespective of what
refiner we put inside.


## 1.6 What the Theißen thesis actually contains

The full PDF (189 pages, German, copy obtained from the user) confirms
and substantially extends the reconstruction above. Sections worth
calling out:

### §3.1 — the master refinement principle

Theißen's whole chapter 3 rests on one lemma (§3.1.1, "Prinzip"). Sym(Ω)
acts on some set Δ on which we have an E-invariant structure; any
g ∈ Sym(Ω) with `g⁻¹Eg = F` bijects E-orbits on Δ to F-orbits on Δ
**preserving length**, and bijects stabilisers `E_{[e]}` to `F_{[eg]}`
with the same property. Every refinement in chapter 3 is a special case
of this principle for a particular Δ:

- Δ = Ω → orbit-length partition (§3.1.2). Implemented in
  `GB_Con.NormaliserSimple` and in GAP's `OrbitsPartition`.
- Δ = Ω × Ω → orbital graphs (§3.2–§3.5). The crux of the thesis.
- Δ = set of blocks → block-system refinement (§3.3.7). Implemented
  in GAP as `_MakeBlox`/`SplitOffBlock`.
- Δ = set of orbital graphs → the [JWW22] "perfect refiner" for
  2-closed groups. Theißen doesn't formalise this as a refiner but
  §3.6 makes the Galois correspondence between 2-configurations and
  2-closed groups explicit.

For Vole: this principle is the right *organising abstraction* for the
refiner code. Currently `NormaliserSimple` and `NormaliserSimple2` are
ad-hoc lists of things to push onto the graph stack; they would be more
maintainable as a registry of "Δ-handlers."

### §3.4 / §3.5 — selecting refinements

Theißen distinguishes between *constructing* an orbital-graph partition
and *deciding which orbital graphs to refine by*. The construction is
the partition ξ(Γ, α) computed by flooding-distance and local-valence
(Algorithms 3.4.5 and 3.4.7). The selection is four criteria, in
increasing generality:

- **§3.5.4**: refine by `(α, β)E` when both α and β lie in singleton
  cells of Π (and Π′ correspondingly).
- **§3.5.5**: refine by `(α, β)E` when α is a singleton in Π and some
  cell of Π is contained in `βE_α`.
- **§3.5.6**: refine by the *edge-union* of all orbital graphs of a
  given valence (i.e. cells of the valence partition λ(E, α)).
- **§3.5.7**: refine by the edge-union of all orbital graphs of a given
  *Π-type* — where the Π-type of `(α, β)E` is the set of cells of Π
  that the 1-distance-zone βE_α touches.

GAP implements **§3.5.6** as `Refinements.Suborbits1` (orbital graphs
of equal valence) and **§3.5.7** as `Refinements.Suborbits2`/`Suborbits3`
(orbital graphs of equal Π-type). §3.5.4 and §3.5.5 don't appear as
distinct refinements — they're subsumed by §3.5.7 when the cell
structure permits, but the explicit form might give cheaper
deductions when both endpoints are singletons.

For Vole: the selection problem is *more* important under graph
backtracking than under partition backtrack. Pushing every orbital
graph onto the digraph stack will work but be expensive — the
equitable refinement is essentially McKay-cost per push. Implement
§3.5.4 (cheap, very few graphs) first, then §3.5.7 (more graphs,
better refinement), and only escalate if needed. This matches
[JPW19]'s empirical observation that selecting "non-futile"
orbital graphs beats using all of them.

### §3.4.8 + Appendix A.1 — what GAP explicitly omits

Theißen explicitly identifies what GAP's normaliser **does not do**.
At the end of §3.4 he writes:

> Analog könnte nun eine Partition in Zellen gleicher ξ(Γ, α)-
> Nachbarschaft berechnet werden usw., bis sich keine Verfeinerung
> mehr ergibt. Am Ende stünde dann eine Partition ξ∞(Γ, α), […]
> Diese gleichmäßige Verfeinerung der Partition ζ(Γ, α) ließe sich
> mit dem dort angegebenen Algorithmus von B. McKay ausrechnen.
> Ähnlich wie schon der Isomorphietest von Graphen erweist sich diese
> Berechnung als Unterprogramm einer generellen Normalisator-Funktion
> aber als zu aufwendig. Deshalb begnügt sich die derzeitige
> GAP-Implementation mit der Bestimmung von ξ(Γ, α).

Translation: a *fully equitable* partition ξ∞ — McKay's iterated
neighbourhood-refinement, as in nauty/bliss — could be used. Theißen
deemed it too expensive as a subroutine of a general normaliser, so
GAP only does the first round ξ. **Appendix A.1** gives McKay's full
algorithm (Algorithm A.1.10) and the theorem (A.1.11) that it
computes the coarsest v-equitable partition finer than Π.

**This is the single most important unimplemented idea for Vole.**
Vole's graph-stack architecture in `domain_state.rs` runs
`refine_partition_cells_by_graph` to fixed point already (see
`refine_graphs` at `domain_state.rs:149`). So in Vole the "too
expensive" objection vanishes — McKay's iterated refinement is what
the engine already does, for free, every time we push a graph. We just
need to push the orbital graphs and let the engine do the rest. This
is precisely the "Strong" / "Full" algorithm of [JPWW21] Section 8,
and Theißen's §3.4.8 is the historical reason it wasn't in GAP.

### §3.6 — 2-closure machinery

This section presents the Galois correspondence:

> {2-configurations on Ω} ⇆ {subgroups of Sym(Ω)}

via `Aut` and `Σ²`, and identifies the image as the 2-closed groups.
This is precisely the theoretical setting of [JWW22]'s "perfect
refiner for 2-closed G" — a refiner that captures Σ²(G) is perfect
exactly when N(G) = N(G^[2]).

§3.6.8 contains a small algorithmic observation worth noting: testing
whether a given `g ∈ Sym(Ω)` lies in `E^[2]` is expensive in general,
**but** if we already know `g` permutes the orbital graphs of E (say,
because we found `g` while computing `N(E)`), the test collapses to a
single E_α-orbit comparison per orbital graph. So a normaliser refiner
*almost* gets the 2-closure for free.

### §3.7 — regular-orbit deductions (the central topic)

Already reconstructed above. Two clarifications from the actual text:

**§3.7.2** explicitly generalises §3.7.1 from "E is regular on Ω" to
"E has one or more regular orbits". The normaliser permutes the
regular orbits among themselves. Once one regular orbit is fixed, the
action of `g^{-1}Eg` on E by conjugation is known, and *every other
E-orbit* `γE` is determined pointwise once `γ` is. This is the
generalisation that GAP's `NextLevelRegularGroups` `:1924`–`:1954` "y
for γ" loop realises.

**§3.7.3** notes that §3.7's idea extends to E that is *not* itself
regular but contains a **regular characteristic subgroup** F. Then
N(E) ≤ N(F) and the §3.7 deductions apply to F. Theißen says: "Dieses
Verfahren erweist sich z.B. als vorteilhaft bei der Berechnung von
Normalisatoren affiner primitiver Permutationsgruppen in Kapitel 5"
— and that is the *only* use GAP makes of it, via the `STBCTEARNS`
path that finds the elementary abelian regular socle. **The general
case — any regular characteristic subgroup of E — is not implemented.**
A regular characteristic subgroup is computable in polynomial time for
e.g. solvable E; this could give §3.7 deductions in many more cases
than GAP currently uses.

**§3.7.4** (summary) is Theißen's own list of which refinements the
GAP-4 normaliser uses:

> Die Normalisator-Funktion für Permutationsgruppen […] verwendet
>   • die Verfeinerung auf Grund von Blöcken wie in 3.3.7,
>   • die Verfeinerung durch Schnittbildung mit ξ(Γ, α), wobei Γ eine
>     Kanten-Vereinigung von Orbital-Graphen wie in 3.5.7 ist,
>   • die in diesem Abschnitt erklärten Verfeinerungen, wenn die zu
>     normalisierende Gruppe (oder ihr charakteristischer Sockel im
>     Fall einer affinen primitiven Permutationsgruppe) eine reguläre
>     Bahn hat.

So GAP uses: block refinement (§3.3.7), Π-type orbital-graph
refinement (§3.5.7, *not* the other three selection criteria),
regular-orbit (§3.7). It does **not** use the McKay-equitable
extension (§3.4.8), the simpler selection criteria (§3.5.4, §3.5.5,
§3.5.6), or §3.7 outside the affine-primitive case.

### Other chapters

**§1.5.5** suggests an optimisation: on lower search levels the
iterated stabiliser is small, so applying the minimality criterion has
diminishing returns. Theißen proposes using just *a subgroup of R*
containing generators that fix the so-far-image-points, rather than
computing the full iterated stabiliser. GAP's
`ChangeStabChain`-based approach always computes the full chain. Worth
considering as a runtime optimisation, but not strictly a normaliser
issue.

**§1.6 Parallelisation** sketches a master/slave parallelisation via
GAP-MPI for both representative search and subgroup search. The idea
is that direct successors of any non-leftmost node are independent and
parallelisable. GAP-MPI never properly landed in mainline GAP. **Not
implemented.** Largely orthogonal to refiner work; a long-term
direction for Vole if parallel search becomes a priority.

**Chapter 2** (Stabiliser chains for automorphism groups) extends the
backtrack framework from Sym(Ω) to Aut(G) by enlarging the operating
domain from Ω to `G/N₁ ⨿ G/N₂ ⨿ … ⨿ G` where `G = N₀ > N₁ > … > Nₗ = 1`
is a characteristic series. Each basic orbit then lives in a coset
`g_i N_{j-1}/N_j` and so has length ≤ `|N_{j-1}/N_j|` rather than
≤ `|G|`. The "full automorphism group" (Eq. 2.3) has a clean
description as a subgroup of `Sym(G/N₁ ⨿ … ⨿ G)` preserving each
quotient. Vole currently does not compute Aut(G) at all and this is
the framework for adding it later.

**§5.2** gives the affine primitive group `3⁴ : 2^{1+4}_- ≤ S_81` as
a counterexample to Pyber's conjecture (`[N(G):G] ≤ n`): this one has
index 120 = `|O₄⁻(2)|`. Pure mathematics, no algorithmic content for
us.

**Appendix A.1** gives the full McKay equitable-partition algorithm
(A.1.10) — the same algorithm that nauty uses for graph
canonicalisation. As noted above, this is the missing ingredient that
Vole already supplies.

## 2. What Vole has today

### 2.1 Plumbing

- Refiner trait in `rust/src/vole/refiners/mod.rs`. Hooks:
  `refine_begin`, `refine_fixed_points`, `refine_changed_cells`,
  `snapshot_rbase`, `solution_found`.
- The domain (`vole/domain_state.rs`) holds a *stack of digraphs*
  (`digraph_stack`) plus the partition stack. `add_graph` /
  `add_arc_graph` push a new graph; `refine_graphs` runs an equitable
  refinement of the partition by the current digraph stack. So Vole is
  already structured around the graph-backtracking framework `[JPWW21]` —
  the data structures the paper recommends are in place.
- Existing refiners:
  - `digraph.rs`: `DigraphTransporter` — pushes one digraph at `refine_begin`.
  - `simple.rs`: set, tuple, set-of-sets, set-of-tuples stabilisers.
  - `gaprefiner.rs`: a generic refiner that calls back to a GAP-side
    refiner and accepts either a partition (`vertlabels`) or a `graph`,
    possibly extended with extra vertices. This is what `GraphBacktracking`
    plugs into.

### 2.2 What's in place for normalisers, end-to-end

- `Vole.Normalizer(G, H)` (gap/wrapper.gi:47) — wraps
  `Constraint.Normalise(H)` and calls `VoleFind.Group(G, …)`.
- `Constraint.Normalise(G) := Constraint.Stabilise(G, OnPoints)`
  (BacktrackKit/gap/constraint.gi:218) — i.e. internally a normaliser is
  encoded as "stabiliser of `G` under conjugation".
- Dispatch in `GraphBacktracking/gap/refiners.gi:25`: for a transporter
  constraint with `action = OnPoints` and source a `PermGroup`, the refiner
  used is `GB_Con.GroupConjugacySimple2(G, G)`.
- `GraphBacktracking/gap/constraints/normaliser.g` defines two refiners:
  - `NormaliserSimple` (lines 2–51): at each newly-fixed point, computes
    `Stab(E, fixed_so_far)` and refines by its orbits. **Partition only**,
    one graph for orbit colours.
  - `GroupConjugacySimple2` / `NormaliserSimple2` (lines 54–143): refines
    by orbits *and* by a minimal-block-system graph. Closer to what GAP
    does, but still only one block system, and no orbital graphs.

So Vole's current normaliser is roughly equivalent to a stripped-down GAP
normaliser without the Theißen orbital-graph refinements. This matches the
roadmap entry "Refiner for 'better normaliser' (TODO)" in
`vole-roadmap.md`.

### 2.3 Search strategy

`vole/selector.rs` picks the next branching cell with one of `Smallest`,
`Largest`, `First`, `MostConnected`, `SmallestMostConnected` —
hard-coded to `Smallest` at line 49. There is **no normaliser-specific
strategy**, no regular-orbit shortcut, no `E`-orbit bias. This is one of
the things the user identified as missing and it is the easiest immediate
win.


## 3. The literature

References (full citations in §6):

- **[Leon91]** introduces partition backtrack; everything below builds on it.
- **[Hol91]** introduces two pruning tricks for normalisers — orbit sizes of
  the stabiliser chain, and the "automorphism of `H`" deduction for regular
  (and faithfully-acting) `H`.
- **[The97]** Theißen's PhD thesis. Adds orbital graphs as refiners
  specifically for normalisers. This is what GAP currently implements.
- **[Hul08]** Hulpke. Uses the induced automorphism action of `N_G(H)` on
  `Aut(H)` to backtrack in a smaller group when `H` is elementary abelian.
  Implemented in GAP as `NormalizerViaRadical`.
- **[Hul05]** Hulpke. For intransitive `H`, considers permutation-isomorphism
  classes of the orbit projections to find a proper overgroup of `N(H)`.
- **[Miy06]** Miyamoto. Uses association schemes / 2-closure structure for
  transitive groups, producing a wreath-product overgroup.
- **[JPW19]** Jefferson, Pfeiffer, Waldecker. "New refiners for permutation
  group search." Extends Theißen's orbital-graph idea to general
  stabilisers/intersections inside PB; the empirical paper showing that
  *using only some* orbital graphs ("non-futile" ones) is often much faster
  than using all of them.
- **[JPWW21]** Jefferson, Pfeiffer, Waldecker, Wilson. "Permutation group
  algorithms based on directed graphs." Introduces the graph-backtracking
  framework Vole is built on. **Explicitly leaves normalisers as future
  work** — "One obvious major area not addressed in this paper is normaliser
  and group conjugacy problems, and we plan to look for new refiners for
  normaliser calculations" (§9).
- **[JWW22]** Jefferson, Waldecker, Wilson. "Perfect refiners for permutation
  group backtracking algorithms." §8.3.5 gives the cleanest theoretical
  framing of the normaliser problem in the graph-backtracking world:
  - **Proposition 8.3:** if `G^x = H`, then `x` transports the *set* of
    orbital graphs of `G` to that of `H`. So `N(G)` stabilises the set of
    orbital graphs of `G`.
  - **Lemma 8.4:** the set-stabiliser in `Sym(Ω)` of the set of orbital
    graphs of `G` equals `N(2-closure of G)`.
  - **Corollary:** the orbital-graph refiner is **perfect** (gives a
    perfect approximation, no false negatives) iff `N(G) = N(2-closure G)`.
    This holds for all 2-closed `G` and more — see Example 8.5.
- **[Cha21]** Chang. "Computing normalisers of highly intransitive groups."
  PhD thesis + JoA paper [CJR22]. Several pruning techniques for the
  intransitive case: equivalent orbits, disjoint direct product
  decomposition, permutation-isomorphism classes of projections. Reports
  speedups of "many orders of magnitude" over GAP.
- **[CJR22]** Chang, Jefferson, Roney-Dougal. The published version of
  Chang's algorithm. Also shows that the case `G = S_n` is at least as hard
  as monomial automorphisms of a linear code.
- **[RDS20, Sic20]** polynomial-time normaliser algorithms for restricted
  classes (primitive, primitive with non-regular socle).

### 3.1 The story in one paragraph

Backtrack normaliser computation has been an "orbital graphs first"
discipline since Theißen 1997. The recent line of work (Jefferson et al.,
2019 → 2021 → 2022) reframes orbital graphs as a special case of a more
general *graph-backtracking* framework: instead of immediately collapsing an
orbital graph into a partition (which is what Theißen does and what GAP
still does), keep the graph around and let the refiner work on the entire
digraph stack. The "perfect refiners" paper makes this precise: stabilising
the **set of orbital graphs** of `H` is exactly the right thing to do, and
gives a perfect refiner whenever `N(H) = N(2-closure H)` (in particular for
2-closed `H`).

Practical caveats — three of them:
1. For 2-transitive groups, the unique orbital graph is complete, so this
   approach gives nothing. Don't bother.
2. Many orbital graphs are "futile" (their automorphism group is the orbit
   stabiliser), so using *all* of them is wasteful. [JPW19] reports that
   selecting non-futile ones is often dramatically faster.
3. For intransitive `H`, the orbit structure itself carries a lot of
   information, and the Chang techniques (orbit equivalence, disjoint
   direct product decomposition, projection isomorphism) are independent of
   any orbital-graph machinery and stack on top.


## 3a. Concrete unimplemented Theißen ideas, ranked

Six items from the thesis that GAP doesn't do, ordered by expected
impact on Vole:

1. **McKay-equitable iterated refinement on orbital graphs (§3.4.8 +
   App. A.1).** Theißen's stated reason for omitting it ("too expensive
   as a subroutine") vanishes under Vole's graph stack — the engine
   already does iterated equitable refinement. This is the headline
   item.
2. **§3.7 for any regular characteristic subgroup F of E, not just the
   affine socle (§3.7.3).** GAP only uses §3.7 when E itself has a
   regular orbit, or when E is a primitive affine group (Earns). The
   generalisation is one paragraph in the thesis and likely
   easy-medium work.
3. **All four selection criteria for orbital-graph refinements
   (§3.5.4–§3.5.7), not just §3.5.7.** §3.5.4 and §3.5.5 give cheap
   wins when many points are fixed; §3.5.6 is "futile orbital graphs"
   territory and corresponds to the empirical "non-futile" filter in
   [JPW19]. Decision needs benchmarking.
4. **Multi-graph stack instead of partition collapse.** The point of
   Vole vs GAP: every place GAP runs `OrbitalPartition` to collapse a
   union of orbital graphs into a partition, Vole can push the graphs
   themselves. Subsumes (1) operationally.
5. **§3.6.8 cheap 2-closure test inside the normaliser run.** If a
   candidate `g` permutes the orbital graphs (which the normaliser
   refiner has to establish anyway), checking `g ∈ E^[2]` is one
   E_α-orbit comparison per graph. Cheap bookkeeping during search.
6. **Parallelisation (§1.6).** Theißen's master/slave model. Far from
   urgent but a real omission and architecturally clean — every
   non-leftmost subtree at any node is independent.

## 4. Where Vole can do better than GAP

This is the design space we should be exploring. Five distinct axes; they
mostly compose.

### 4.1 Keep a set of orbital graphs, not just a partition

This is the user's main hypothesis and the literature confirms it. GAP's
`Suborbits1/3` flatten an orbital graph or a union of orbital graphs into a
partition via `OrbitalPartition` (flooding-distance colour). Vole already
has a `digraph_stack` and a refiner (`refine_graphs`) that runs equitable
refinement over the stack. Pushing each interesting orbital graph of
`Stab(E, fixed)` directly onto the stack — as a labelled digraph — strictly
dominates the partition obtained by flooding-distance colouring, and
matches what is called the **Strong** algorithm in [JPWW21] §8.

Open questions to answer empirically:
- How many orbital graphs do we push, and which? All of them (Full) vs
  the "non-futile" ones (per [JPW19]) vs a small budget chosen by some
  heuristic (degree, edge count, …).
- Do we push them all at the root, or push more as we descend the search
  tree? GAP only computes new suborbit information when a new fixed point
  appears — Vole should do the same to avoid redundant graphs.
- The orbital graphs of `Stab(E, α₁, …, αₖ)` depend on the fixed points,
  which differ between sides in the transporter case. Need to be careful
  that left/right stacks remain comparable.

### 4.2 Search strategy: the regular-orbit shortcut

GAP's `NextLevelRegularGroups` (`:1871`) is the part of stbcbckt.gi that
isn't a refiner at all — it changes the *base-point order*. When `E` has a
regular orbit, choosing base points inside that orbit is qualitatively
different from choosing arbitrary base points, because pinning down `s`
points on the regular orbit (where `s` is the number of generators of `E`)
pins down the whole orbit and therefore much of the action of `E`. This is
Theißen §3.7.

Vole's `selector.rs` has no concept of base-point order beyond cell-size
heuristics. For normaliser problems we want to:
- detect regular orbits of `E` once, before search starts;
- if there is one, override the selector to branch on the regular orbit's
  cell first, walking the orbit;
- otherwise fall back to a normaliser-aware heuristic — probably
  `Smallest` is fine but we should benchmark `Largest` and the GAP
  cell-length heuristic.

This is largely orthogonal to (4.1): it works regardless of which
refinements we run. Implementing only this without orbital graphs would
already cover ~half of what GAP gets from `NextLevelRegularGroups`.

### 4.3 Block-system graphs

GAP's `_MakeBlox` / `SplitOffBlock` refinements use a *single* block system
of `E` for pruning. Vole already does one block system in
`GroupConjugacySimple2` (`normaliser.g:64`). With a graph stack we can push
*multiple* block systems — every minimal block system of `E` on each orbit,
encoded as a labelled digraph with one new vertex per block — and let the
equitable refiner combine the constraints.

### 4.4 Chang's intransitive-case techniques

If we want Vole's normaliser to be competitive with the recent literature
(not just with GAP's stbcbckt.gi), we should implement the Chang pipeline
at the wrapper level, above the backtrack:

- **Disjoint direct product decomposition** of `H` (Chang Ch. 3) — if `H =
  H₁ × … × H_k` on disjoint supports, then `N(H) = ⟨N(H_i), C(H), E⟩`
  where `E` permutes the factors with equal support sizes. This collapses
  one big search into several small ones.
- **Equivalent-orbit reduction** (Chang §4.1): orbits that are
  permutation-isomorphic via `H` can be collapsed for the backtrack search,
  then the witness lifted. Reduces the effective degree.
- **Projection-class refiner** (Chang §4.3): conjugacy invariant function
  on projections of `H` onto orbits.

These are pre-backtrack reductions. They wrap any normaliser solver,
including a graph-backtracking one. GAP's outer-wrapper `NormalizerPermGroup`
does a much weaker version of this (orbit-by-orbit). Doing it properly is
where the literature reports the largest speedups.

### 4.5 Theoretical lens: aim for "perfect" when affordable

By [JWW22] §8.3.5 the orbital-graph-stack refiner is perfect for `H` with
`N(H) = N(2-closure H)`. In particular, for 2-closed `H`, no search is
needed beyond what the refiner deduces. We should test for 2-closure
cheaply (or test the weaker condition computationally inside search) and
use it as a stopping condition / sanity check on the implementation: a
2-closed input should give *zero* search nodes (in the sense of [JPWW21]
Table 8.2's "Strong" column).


## 5. Concrete checklist for an implementation pass

This is the order I think things should land in. Each step is independently
testable.

1. **Wire `NormaliserSimple2`-style orbital-graph stack refiner.** Refiner
   produces, at `refine_fixed_points`, the list of orbital graphs of
   `Stab(E, fixed_so_far)`. Push each as a labelled digraph. Cache per
   fixpoint sequence. Compare to current `NormaliserSimple2` on the
   existing test suite.
2. **"Non-futile" filter.** Skip orbital graphs whose automorphism group
   coincides with the orbit-stabiliser. [JPW19] reports a large practical
   win for this.
3. **Regular-orbit search strategy (Theißen §3.7).** Concretely:
   1. At normaliser-refiner construction time, find a regular orbit `O`
      of `E` (or, if `E` is primitive, the Earns and its socle-orbit).
      Cache `O`, `ω₁ ∈ O`, generators `h₁, …, h_s` of `F`, and a
      Schreier tree of `F` on `O`.
   2. Plug a normaliser-aware selector into `vole/selector.rs` — or,
      better, give the refiner an interface to *propose* the next
      branching cell. Until the Schreier tree of size `|F|` has been
      reproduced on the image side, the proposed branching cell is the
      one containing the next undetermined Schreier-tree point.
   3. At each new fixed point inside `O`, run the §3.7 deductions:
      extend the image-side Schreier tree, isolate every other point
      of `O` that the new generator pins down, and force the
      corresponding image-partition cells. This is `_RegularOrbit1`
      and `RegularOrbit2` from GAP.
   4. For every fixed point `y` outside `O`, after the regular orbit is
      pinned, force the image of every point in `y^F` (the
      `RegularOrbit3` deduction).
   5. Image-side failure cases: tree of wrong size, cell isolation
      fails. These map straight to `trace::TraceFailure` in Vole.

   Doing this purely as base-point ordering on top of graph
   backtracking, without any partition trickery, will be cleaner than
   GAP's implementation — Vole's domain stack can store the candidate
   image of the regular orbit explicitly rather than as a derived
   partition.
4. **Block-system graphs.** Push all minimal block systems of `E` on each
   transitive orbit, as labelled digraphs.
5. **Orbit-by-orbit reduction wrapper.** Port GAP's outer
   `NormalizerPermGroup` orbit reduction loop into `Vole.Normalizer`. Cheap
   and independent of (1)–(4).
6. **Disjoint direct product decomposition wrapper.** Chang Ch. 3
   reduction. Largest expected win for intransitive inputs.
7. **2-closure sanity check.** Optional: test for 2-closure and assert
   zero-node search on the orbital-graph stack refiner.

After (1) — and certainly after (2)+(3) — we should already match GAP on
most non-2-transitive inputs. After (6) we should beat GAP by orders of
magnitude on highly intransitive inputs, per [CJR22].


## 6. References

- **[Hol91]** D. F. Holt. "The computation of normalizers in permutation
  groups." J. Symbolic Comput. 12 (1991) 499–516.
- **[Hul05]** A. Hulpke. "Constructing transitive permutation groups."
  J. Symbolic Comput. 39 (2005) 1–30.
- **[Hul08]** A. Hulpke. "Normalizer calculation using automorphisms."
  Computational group theory and the theory of groups, Contemp. Math. 470
  (2008) 187–195. <https://www.math.colostate.edu/~hulpke/paper/normperm.pdf>
- **[JPW19]** C. Jefferson, M. Pfeiffer, R. Waldecker. "New refiners for
  permutation group search." J. Symbolic Comput. 92 (2019) 70–92.
  <https://arxiv.org/abs/1608.08489>
- **[JPWW21]** C. Jefferson, M. Pfeiffer, R. Waldecker, W. A. Wilson.
  "Permutation group algorithms based on directed graphs." J. Algebra
  (2021), arXiv:2106.13132 (extended version arXiv:1911.04783).
- **[JWW22]** C. Jefferson, R. Waldecker, W. A. Wilson. "Perfect refiners
  for permutation group backtracking algorithms." J. Symbolic Comput.
  (2022). <https://arxiv.org/abs/2112.05065>
- **[Leon91]** J. S. Leon. "Permutation group algorithms based on
  partitions, I." J. Symbolic Comput. 12 (1991) 533–583.
- **[Miy06]** I. Miyamoto. (Association-scheme based normaliser
  improvements.)
- **[RDS20]** C. M. Roney-Dougal, S. Siccha. "Normalizers of primitive
  groups with non-regular socles in polynomial time."
  <https://publications.rwth-aachen.de/record/795205>
- **[Sic20]** S. Siccha. Related work, cited via [Cha21].
- **[The97]** H. Theißen. "Eine Methode zur Normalisatorberechnung in
  Permutationsgruppen mit Anwendungen in der Konstruktion primitiver
  Gruppen." PhD thesis, RWTH Aachen, 1997.
- **[Cha21]** M. S. Chang. "Computing normalisers of highly intransitive
  groups." PhD thesis, University of St Andrews, 2021.
  <https://research-repository.st-andrews.ac.uk/handle/10023/23416>
- **[CJR22]** M. S. Chang, C. Jefferson, C. M. Roney-Dougal. "Computing
  normalisers of intransitive groups." J. Algebra (2022).
  <https://arxiv.org/abs/2112.00388>
- GAP source: `lib/stbcbckt.gi`, especially `NormalizerPermGroup`
  (line 2652), `DoNormalizerPermGroup` (2616), `RBaseGroupsBloxPermGroup`
  (1969), `Suborbits` (416), `OrbitalPartition` (624),
  `NextLevelRegularGroups` (1871), and the `Refinements.*` table at 1556ff.
- Vole source: `rust/src/vole/refiners/{mod,digraph,gaprefiner,simple}.rs`,
  `rust/src/vole/{domain_state,selector,search/mod}.rs`,
  `dependencies/GraphBacktracking/gap/constraints/normaliser.g`,
  `dependencies/BacktrackKit/gap/constraint.gi:218`.

## 7. Rereview findings (2026-05) — techniques in Theißen / GAP not yet on the phase plan

After implementing Phase A (orbital widget) + Phase C (regular-orbit
selector) + Phase E (ByOrbits / L-overgroup wrapper), I went back to
both Theißen's thesis and `stbcbckt.gi` to look for anything we missed.
Notes here are intentionally short — these are seeds for future PRs, not
finished designs.

### 7.1 The "ξ_∞" iterated equitable refinement on the orbital config

Theißen §3.4.8 explicitly states the GAP impl only does ONE round of the
orbital-graph distance/local-structure refinement ξ(Γ, α), saying the
full McKay iterated equitable refinement is too expensive *as a
subroutine* of the normaliser search. Vole's `digraph_stack`
(`partition_stack.rs:519-553`) already runs that iteration to fixed
point automatically. **This is the one place we have a strictly free
win over GAP and it's worth quantifying.** Phase A pushes orbital
graphs into `digraph_stack` so we DO iterate to fixed point — but only
within a single orbital widget. Pushing more graphs (e.g. union-of-
suborbits orbital graphs of multiple Γ_i, §3.5.6) would let the
iteration cross-talk between widgets, potentially yielding strictly
finer partitions than GAP can reach. This is a candidate Phase B
extension.

### 7.2 §3.6: 2-closure as a structural pre-step

Two facts from §3.6 / §3.6.5:
* `E^[2] = Aut(Σ_2(E))` — the 2-closure equals the automorphism group
  of the orbital-graph configuration of E.
* `N_S(E) = N_S(E) ∩ E^[2]` whenever every g ∈ N_S(E) fixes every
  orbital graph as a set; more generally, the kernel of `N → Sym(set
  of orbital graphs)` is exactly `N ∩ E^[2]`.

Implication: when E is **2-closed** (E = E^[2]), `N_S(E)` is the
*outer* part — elements that permute orbital graphs but lie outside
the kernel — composed with E itself. JWW22 Cor. 8.4 already gives us
"0 search nodes on 2-closed E" via the set-of-orbital-graphs widget,
so this isn't new. But the *structural* observation suggests an
alternative pipeline:

1. Compute E^[2] = Aut of the individual orbital graphs (pushed as
   fixed digraphs, not in a permuting widget). This is a 2-closure
   computation, fast in Vole.
2. Check whether E = E^[2]. If yes, `N(E) = Aut(orbital-config)` —
   compute via the set-of-graphs widget. Done.
3. If no, the inner search lives inside E^[2] rather than S_n.
   E^[2] is often a much tighter outer group than S_n, especially when
   E is "almost" 2-closed.

This composes with Phase E: at the inner solve, use E^[2] as the outer
constraint instead of S_n. Plausible candidate for a Phase E variant.

### 7.3 §3.5.6–§3.5.7: edge-unions of orbital graphs by Π-type

§3.5.7 defines the Π-type of an orbital graph Γ = (α, β)E as the set
of cell indices in the current partition Π that meet the distance-1
zone of Γ from α. The Π-type is invariant under any valid g, so all
orbital graphs of the same Π-type can be unioned into a single edge-
multigraph and pushed as one widget. This is strictly between "push
each orbital separately" (computes the 2-closure, too strong) and
"push the whole set permutably" (the Phase A set-of-graphs widget).
Vole's Phase A widget groups by valence/orbital-equivalence-key, which
is coarser than Π-type. Refining the equivalence key to Π-type would
give finer partitions in some cases (especially deeper in the search,
where Π has more singleton cells).

### 7.4 §3.5.4: cheap two-singleton-cells refinement

When the current partition Π has at least two singleton cells {α} and
{β}, the single orbital graph (α, β)E is a P-refinement. This is the
cheapest possible orbital-graph push and avoids enumerating the full
set. Vole's Phase A always enumerates the full orbital set (the
`StabTreeStabilizerOrbitalGraphs` call). At deeper depths, where Π
has many singletons, switching to the "two-singletons" cheap case
would save the orbital enumeration time. Effectively the `cheap` half
of Phase B as planned.

### 7.5 §3.7.3: regular characteristic subgroup F ≤ E (Phase D)

§3.7.3 explicitly proposes: when E itself is not regular, search for a
regular characteristic subgroup F (DerivedSubgroup, FittingSubgroup,
Centre, socle for primitive affine, etc.) and apply the regular-orbit
machinery to F. The deductions remain valid for N(E) because
N(E) ≤ N(F) for characteristic F. This is Phase D in our plan and
remains undone — worth picking up after the perf situation on Phase C
is sorted.

### 7.6 GAP-specific techniques not in Theißen

* **`Refinements.Suborbits0..3`** (`stbcbckt.gi:1744-1850`): suborbit
  *length-distribution* refinement. After fixing a base point, the
  suborbits of `Stab(F, base)` partition Ω; the multi-set of suborbit
  lengths is a g-invariant. Refines by suborbit length, and (more
  finely) by intersection profile with existing cells. Vole's orbital
  widget captures orbit lengths via vertex colours but **not the
  full Suborbits3 intersection profile**. Worth investigating.

* **`NormalizerViaRadical`** (`norad.gi:380`): a completely separate
  algorithm using Fitting-radical layers via Pcgs. GAP uses it when
  `HasFittingFreeLiftSetup(G)` AND `NrMovedPoints(G) > 1000` AND the
  radical is at least `Size(G)^(1/3)`. This is the algorithm of choice
  for solvable-radical-heavy groups; Vole has nothing remotely
  similar. Likely a long-term candidate, but if we want to beat GAP on
  solvable inputs we'd need either this or something equivalent.

* **`SubgroupProperty` fallback for huge degree** (`stbcbckt.gi:2626-
  2628`): when `NrMovedPoints(G) > 500 AND NrMovedPoints(G) > |G|`,
  GAP gives up on the backtrack and uses SubgroupProperty (an element-
  by-element check). Vole has no analogous fallback — for very-large-
  degree, very-small-group inputs we might be doing strictly more
  work than necessary.

* **`Size(E) = 2` special case** (`stbcbckt.gi:2662-2668`): when E is
  generated by a single involution, normaliser computation reduces to
  RepOpElmTuplesPermGroup — the conjugacy problem for the involution
  in G. Vole hits the generic path for this case. Cheap win for
  cyclic-2 inputs but probably rare in practice.

* **Skip-small-orbits heuristic** (`stbcbckt.gi:2723-2726`): in the
  orbit-by-orbit loop, GAP unions orbits until total length ≥ 10 (or
  exhausts orbits). For one-or-two-point orbits, the per-orbit
  reduction overhead exceeds the saving. Our Phase E `ByOrbits` does
  NOT apply this heuristic — every orbit, however tiny, contributes
  a perm-iso class and a recursive call. Cheap to add and might fix
  the perf regression observed on full-direct-product inputs.

* **`IsNormal(G, E)` early-stop in orbit loop** (`stbcbckt.gi:2705-
  2708`): GAP checks after every per-orbit refinement and bails out
  immediately when G already normalises E. We don't have this. Cheap
  to add (single call per outer iteration) and would dominate on
  transitive-by-luck refinements.

* **`NormalizerViaRadical` precondition**: only invoked when
  `HasFittingFreeLiftSetup(G)`. GAP computes this for nice perm
  groups (transgrp / primgrp library entries) automatically.

### 7.7 Things our Phase C does NOT do that Theißen §3.7 does

* **Schreier-tree update across rbase points**: in
  `NextLevelRegularGroups` (line 1888-1916), GAP extends the regular-
  orbit Schreier tree IN PARALLEL with the rbase descent. Each
  newly-fixed regular-orbit point adds one generator to the tree, so
  the deduced-image set grows monotonically with depth. Phase C
  re-computes the BFS orbit from scratch at each event, which is
  wasteful. Replacing with incremental tree extension would save
  O(s · |O|) refiner work at the deepest levels (where O is the
  regular orbit and s is the number of E-generators).

* **`STBBCKT_STRING_REGORB3` cross-orbit propagation** (line 1924-
  1953): "if the image of a point ω is known, the image of its
  E-orbit is known". When the regular orbit has been pinned, ANY
  other E-orbit's images are derivable from a single point — propagate
  to fix the entire orbit. Phase C as implemented only fires on
  regular-orbit points; it doesn't propagate to other orbits once
  the regular orbit is settled. The §3.7.2 generalisation (regular
  characteristic subgroup F ≤ E) is even broader.

### 7.8 Summary table (priority guess, no commitments)

| Idea | Section | Likely payoff | Cost |
|------|---------|---------------|------|
| Π-type orbital union (§3.5.7) | 7.3 | Med | Low (extend equiv key) |
| 2-singleton cheap (§3.5.4) | 7.4 | Med (deep depths) | Low |
| Phase D (reg char subgroup) | 7.5 | High for AGL-class | Med |
| Suborbits3 intersection profile | 7.6 | Unknown | Med |
| Phase C cross-orbit propagation | 7.7 | Med | Low |
| IsNormal short-circuit in ByOrbits | 7.6 | Low-Med | Trivial |
| Skip-small-orbits in ByOrbits | 7.6 | Fixes ByOrbits perf regression | Trivial |
| E^[2] as outer in inner solve | 7.2 | Speculative | Med |
| NormalizerViaRadical analogue | 7.6 | High for solvable | Very high |

## 8. Hunt benchmark results (May 2026)

The loss hunt (tst/benchmarks/hunt.g, 94 instances spanning cyclic
regular, elementary-abelian regular, intransitive C3/S3, inhomogeneous
C3xS3, AGL(1,p), AGL(d,p), PSL(2,q), PGL(2,q), Mathieu, wreath
products, hand-picked TransGrp_hard) gave the following per-backend
totals at 30s/call budget. Each backend column sums wall time over all
ok-status runs; max column gives the slowest single instance.

| Backend                    | Total (ms) | Max (ms) | vs GAP |
|----------------------------|-----------:|---------:|-------:|
| gap (Normalizer)           |     1 629  |      101 |   1.0x |
| OrbitalRegOrbitChar (D)    |    10 352  |    3 693 |   6.4x |
| OrbitalDeep                |    10 852  |    2 131 |   6.7x |
| OrbitalRegOrbit (C)        |    11 382  |    3 653 |   7.0x |
| Orbital (A default)        |    11 390  |    3 660 |   7.0x |
| OrbitalSmall               |    12 397  |    3 854 |   7.6x |
| wrap:direct                |    16 707  |    4 494 |  10.3x |
| wrap:ByOrbits              |    18 288  |    3 964 |  11.2x |

Observations:

* **Phase D is the best vole variant**, overtaking Phase C by ~10%
  overall. The headline improvement is AGL(1, p) where Phase D drops
  the per-instance ratio from 14x to 5x.
* **Phase E (ByOrbits) is uniformly worse than direct** on these
  benchmarks. The orbital widget already encodes the wreath structure
  the L overgroup makes explicit, and L's construction overhead +
  the inner search's L-constraint refinement add up to a net loss.
  Kept as a baseline; needs IsNormal short-circuit + skip-small-orbits
  to be competitive.
* **wrap:direct is 60% slower than the OrbitalRegOrbitChar refiner
  used standalone**. The gap is wrapper-dispatch overhead (option
  parsing, IsSubset/IsNormal checks). The standalone path is
  preferable for raw benchmarking, but Vole.Normalizer needs the
  wrapper to provide the option machinery and short-circuits.
* **One win**: TransGrp(12;1) — small symmetric group, ratio 0.3x.
  The orbital widget on highly symmetric inputs is very efficient.
* Top losses remaining: AGL(1, p) for p ∈ {23,29,31,...} (still
  ~5x), inhomogeneous C3^a x S3^b at 2-4x, PSL/PGL/wreath at 2-3x,
  intransitive C3/S3 at 2-3x.

The data is reproducible via `tst/benchmarks/run-hunt.g` and analysed
by `tst/benchmarks/analyse-hunt.g`. CSV is regenerated each run.

### 8.1 Known bug: Phase D propose-branch hint

The proposeBranchPoint hint in Phase D's deduction
(`_BTKit.makeNormaliserRegOrbitDeduction`) gives wrong answers on
some inputs (e.g. TransGrp(8,33) = E(8):A_4). The forced labels are
sound and kept; the propose is disabled by default in Phase D until
the bug is traced (the same propose works correctly in Phase C).
Investigation note: Phase C and Phase D use the SAME propose code,
the SAME deduction structure, but Phase D uses F's regular-orbit
data (where F is a characteristic subgroup of E) instead of E's
own. The g-equivariance argument that makes Phase C's propose sound
seems to hold in Phase D too — both sides propose the same cell
index for any valid g — yet the empirical search rejects valid g
when propose is enabled. Worth a fresh look with a debugger.

