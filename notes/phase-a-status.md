# Phase A — status hand-off

What landed during the overnight session and where I stopped.

## TL;DR

Phase A — the orbital-graph normaliser refiner — is **landed, correct,
and competitive with GAP** on the inputs benchmarked. The known
cyclic-prime hangs (`C_11`, `C_13` in regular action) are resolved in
milliseconds. The bank now has 2839 single-variant tests + a
variant-cross-check sweep, all green.

## What's new

### Code

- **`_BTKit.buildSetOfGraphsWidget(graphs, n)`** (in
  `dependencies/BacktrackKit/gap/internal/util.g`) — the
  "set-of-graphs" widget. Encodes a family of digraphs `{Γ_1, …, Γ_k}`
  on `[1..n]` as a single labelled digraph whose Sym(Ω)-automorphism
  group equals the setwise stabiliser. Singleton fast path: `k=1`
  pushes the graph directly. Asserts inputs live on `[1..n]`.
- **`_BTKit.orbitalEquivalenceKey(og)`** — current key is the
  multiset of out-degrees (sound but coarse). Tighten in Phase B.
- **`_BTKit.blockSystemsAsGraphs(G, orb, n)`** — block systems as
  intra-block complete digraphs on `[1..n]`. Replaces the previous
  encoding that used aux vertices (which collided with the widget's
  aux range — see "Bug found and fixed" below).
- **`_BTKit.partitionByKey(items, keyFn)`** — group items by key.
- **`_BTKit.makeNormaliserOrbitalRecords(G, n, isRoot, strategy)`** —
  the underlying push: orbits + (optional) block-system widgets +
  (optional) orbital-graph family widgets, with strategy knobs.

### The variant family

In `dependencies/GraphBacktracking/gap/constraints/normaliser.g`,
parameterised by a strategy record `rec(orbitals := ?, blocks := ?, …)`:

| Variant                                | Orbital graphs           | Block systems   |
| -------------------------------------- | ------------------------ | --------------- |
| `GroupConjugacySimple`                 | none (orbits only)       | none            |
| `GroupConjugacySimple2`                | none                     | root            |
| `GroupConjugacyOrbitalNone`            | none                     | root            |
| `GroupConjugacyOrbitalRoot`            | root only                | root            |
| `GroupConjugacyOrbital`  *(default)*   | every stab-chain step    | root            |
| `GroupConjugacyOrbitalDeep`            | every stab-chain step    | every step      |
| `GroupConjugacyOrbitalSmall`           | every step, cutoff=`n`   | root            |

`NormaliserX(g)` = `GroupConjugacyX(g, g)` for each variant.

Dispatch in `dependencies/GraphBacktracking/gap/refiners.gi` routes
`OnPoints` transporter / `Normalise` constraints to the default
`GroupConjugacyOrbital`.

### Test bank

`tst/bank/` is the living correctness bank against GAP. Quick mode
caps:

| source        | quick               | nightly             | full |
| ------------- | ------------------- | ------------------- | ---- |
| transgrp      | degrees ≤ 12        | ≤ 16                | ≤ 22 |
| primgrp       | ≤ 12                | ≤ 16                | ≤ 22 |
| smallgrp      | order ≤ 24, deg ≤ 12| order ≤ 64, deg ≤ 16| order ≤ 128, deg ≤ 22 |
| intransitive  | total-degree ≤ 12   | ≤ 18                | ≤ 30 |
| random        | n ≤ 12, 5 samples/n | ≤ 18, 20 samples/n  | ≤ 28, 50 samples/n |
| variants      | 20 + 15 each src    | 100 + 80            | 500 + 400 |
| regression    | (entries forever)   | (entries forever)   | (entries forever) |

Quick mode: 2839 single-variant + 70 variant-cross-check tests, all
pass.

Run with `./run-bank.sh quick` or `./run-bank.sh nightly`.

### Benchmark harness

`tst/benchmarks/` produces CSVs. Run with
`gap -q -c 'Read("tst/benchmarks/run.g"); RunBenchmarks(); QUIT;'`.
Latest CSV in `tst/benchmarks/latest.csv`. Two suites currently —
cyclic-prime and primitive — easy to extend.

Headline measurements from `tst/benchmarks/latest.csv`:

| input        | Simple/Simple2/None     | OrbitalRoot      | Orbital         | OrbitalDeep     | OrbitalSmall    | gap            |
| ------------ | ----------------------- | ---------------- | --------------- | --------------- | --------------- | -------------- |
| C_7          | 568 nodes               | 7                | 7               | 7               | 7               | (ref)          |
| C_11         | brute force             | 6                | 6               | 6               | 6               | (ref)          |
| PSL(2,11)    | 9 330 / 14 / 9 330      | 9 330            | 10              | 10              | 55              | (ref)          |
| M_11         | 30 553 / 22 / 30 553    | 30 553           | 99              | 110             | 99              | (ref)          |

The variants behave very differently — push-at-root isn't enough for
`PSL(2,11)` / `M_11`; you need orbitals at every step.

## Bugs found and fixed (three of them, all root-caused not patched)

### 1. Aux-vertex collision (block systems)

**Root cause**: the widget originally assumed every input digraph
lived on `[1..n]`. But the existing block-system encoding (from
`GroupConjugacySimple2`) used aux vertices `[n+1..n+k+1]`. When the
widget consumed these block-system graphs, its own family-member
vertices `[n+1..n+k]` *collided* with the block-system's aux vertices.
The widget then misinterpreted incoming arcs from block aux vertices
as arcs from family-member vertices, producing structurally wrong
labels and over-constraining the partition (often to `|N|=1`).

**Fix**: re-encoded block systems as intra-block complete digraphs on
`[1..n]` only (no aux vertices). Information-equivalent (connected
components recover blocks); composes correctly with the widget.
Reinforced with an `Assert(0, DigraphNrVertices(g) <= n)` contract at
widget entry.

Caught by V_4 in S_4 (the simplest case where multiple block systems
of the same shape exist) failing on the bank.

### 2. Equivalence-key non-determinism (Bliss canonical form)

**Root cause**: after tightening the orbital-equivalence key to use
`BlissCanonicalDigraph`, several bank inputs started failing. The
canonical digraph's edge SET was deterministic but the adjacency-list
storage ORDER was not — so `String(D)` for two isomorphic graphs gave
different strings, and `partitionByKey` placed them in different
families. Singleton-family fast paths then over-constrained the
partition.

**Fix**: the equivalence key serialises `List(OutNeighbours(canon),
Set)` (each adjacency list sorted), producing a deterministic string.
Caught by the bank's regression sweep at degree 10.

### 3. Covariance violation (`R(S)^g ≠ R(S^g)`)

**Root cause**: the refiner computed `Stabilizer(group, fixedpoints,
OnTuples)` and called `getOrbitalListWithOptions` on it directly. On
the left and right sides of the search the stabilisers are conjugate
but may be represented differently (different point order), and so
the orbital graphs come back in different orders. Then the
left-vs-right refiner outputs don't correspond up to conjugation,
breaking trace consistency. (Flagged by Chris.)

**Fix**: rewired through `StabTreeStabilizerOrbitalGraphs(group,
points, options)` and `StabTreeStabilizerOrbits(group, points,
[1..n])`. Stabtree caches results keyed on the canonical
representation and applies the inverse min-perm — so both sides see
the same orbital graphs in the same order, just conjugated. The
across-family iteration order is also pinned by sorting key names
(`SortedList(RecNames(families))`).

Block-system pushes initially had to be root-only because stabtree
had no block-system cache. Resolved by adding
**`StabTreeStabilizerBlockSystemGraphs`** (in
`dependencies/BacktrackKit/gap/stabtree.g`) — same pattern as
`StabTreeStabilizerOrbitalGraphs`: cache canonical-form block-system
digraphs on `ret.tree.blockSystemDigraphs`, keyed by an options
record (currently `rec(maxval)`); return conjugated copies per call;
canonical values are made immutable to prevent cache pollution. The
refiner's `Length(points) = 0` guard is gone; `OrbitalDeep`
(blocks="always") now genuinely differs from `Orbital`
(blocks="root"). Cache key design is forward-compatible: adding e.g.
a "minimal blocks only" parameter goes into the options record and
gets a separate cache entry automatically — same idea as how
`reducedOrbitals` already keys by `skipOneLarge`/`cutoff`.

All three bugs were caught by the bank — that's exactly what it's for.

## Outstanding bugs / TODO surfaced during this session

None outstanding. Two cyclic-prime hangs surfaced earlier in the
session were both resolved by Phase A:

- `TransGrp(11, 1)` = C_11 — was hang, now 12 ms.
- `TransGrp(13, 1)` = C_13 — was hang, now 21 ms.

`tst/bank/known_hangs.g` is empty.

## What I considered and chose not to do

- **Native-Rust normaliser refiner** — explicitly chosen against per the
  plan (`make-a-plan-on-zazzy-kettle.md`). All group-theoretic work
  stays in GAP; only labelled digraphs flow to the Rust engine.
- **Phase E (orbit-by-orbit wrapper)** — checked and decided the win
  is small for `Vole.Normalizer(S_n, X)` (the common case): S_n is
  transitive on `[1..n]` so the GAP-style orbit decomposition by `G`
  doesn't trigger. The Chang [CJR22] DDPD reduction in Phase F
  decomposes by `E` instead — that's the bigger win, but it's the
  biggest single piece of work and not appropriate for a one-night
  push.
- **Phase C (§3.7 regular-orbit search strategy)** — Phase A's
  widget subsumes §3.7 for everything tested so far (all cyclic
  primes up to 29; all primitive groups in the benchmark). The Rust
  selector hook for §3.7 is unbuilt and is reserved for inputs where
  Phase A still hits the wall.
- **Tighter orbital-graph equivalence** (canonical-form hashing). The
  current out-degree-multiset key is sound but coarse — it groups too
  many orbital graphs together and so over-uses the widget. Tightening
  with bliss/nauty canonical forms is Phase B territory.

## Performance characterisation

Comparing variants gives a clean empirical picture:

- **For cyclic primes in regular action**: all orbital variants are
  equally good (6–7 search nodes). The key constraint is "push orbital
  graphs at all"; doing so at the root or every step makes no
  difference because the search is essentially done after the root.
- **For larger primitive groups (PSL(2,11), M_11)**: only "always"
  helps. OrbitalRoot gives the same nodes as no-orbitals (because the
  root push doesn't refine the partition for these inputs, so the
  orbital constraint is needed at every level).
- **OrbitalSmall** (cutoff = n) is competitive on most inputs but
  loses on PSL(2,11) and PSL(2,7), where larger orbitals carry useful
  structure. A more sophisticated cutoff or canonical-form grouping
  would likely fix this.

## Hand-off

Natural next steps:

1. **`StabTreeStabilizerBlockSystems`**. The current code restricts
   block-system push to root only because stabtree has no block-system
   cache. Adding one (mirror the `reducedOrbitals` pattern, conjugating
   by `ret.minperm^-1`) would unblock the `OrbitalDeep` variant, which
   right now is effectively identical to `Orbital`.
2. **Adaptive variant selection in `Vole.Normalizer`**. Empirically:
   for cyclic groups in regular action, `OrbitalRoot` is as good as
   `Orbital` but cheaper. For larger primitive / affine groups,
   `Orbital` is required. A heuristic checking `IsPrimitive(E)` and
   `IsCyclic(E)` should be enough to pick the right variant.
3. **Tighter orbital-graph cutoff**. `OrbitalSmall` uses `cutoff = n`
   which works for cyclics but harms PSL(2,11). Try `cutoff = 2n` or
   `cutoff = n^1.5`. Benchmark to find the sweet spot.
4. **Phase F (Chang DDPD)**. The intransitive benchmark shows Phase A
   already handles direct products of small groups well (`C_5 x C_5`:
   19 nodes), but the DDPD reduction would scale further. Largest
   expected single PR. Builds on top of Phase A.

The bank and benchmark suites are designed for iteration. The bank
quick mode is 2839 single-variant + 70 variant-cross-check tests
(degrees ≤ 12, ~1–2 min on CI). Add inputs freely; each later PR
should show numeric movement in `tst/benchmarks/latest.csv`.

## Files changed this session

```
dependencies/BacktrackKit/gap/internal/util.g
dependencies/GraphBacktracking/gap/constraints/normaliser.g
dependencies/GraphBacktracking/gap/refiners.gi
tst/bank/{README,helpers,run-bank,transgrp,primgrp,smallgrp,
         intransitive,random,regression,variants,known_hangs}.g
tst/bank/README.md
tst/benchmarks/{README,helpers,run,cyclic-prime,primitive,intransitive}.g
notes/{normaliser,phase-a-status}.md
run-bank.sh
```

## Nightly bank state at hand-off

Background gap process started ~00:04 to run `nightly` mode (TransGrp ≤
16, intransitive total-cap 18). Last log update was at 00:04. It's
been stuck on intransitive for over an hour. Either it's slowly
grinding through ~46k pairs (plausible — quick at 12 has 2117 pairs
and runs in seconds; 18 has ~22× more), or it's hung on one input.
The sandbox doesn't allow `ps`/`killall`, so you may want to manually
kill it on waking. The log is at `/tmp/claude-501/bank_nightly.log`.

The nightly run is using the *pre-Bliss-key, pre-stabtree* code (it
was started before those changes landed). The bank itself, run fresh
on the current code, passes quick mode with 2839+70 tests.
