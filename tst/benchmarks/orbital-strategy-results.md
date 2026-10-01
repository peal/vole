# Orbital-graph budgeting — results, memory analysis & recommendation

Experiment driven by `tst/benchmarks/orbital-strategy-sweep.g` (raw CSV in
`orbital-strategy-sweep.csv`), using the BacktrackKit `BTKIT_ORBITAL_STRATEGY`
scaffolding. This note covers three things that landed together:

1. **which orbital-graph subset** gives best search performance (the sweep);
2. **why** budgeting helps (a search-tree / branch-selection effect, not a
   refinement one);
3. **a memory blow-up** on deep searches, its root cause, and the two fixes that
   make budgeting a genuine memory bound (the **V+E cost model** and giving the
   plain in-group path the **same budget rule** as canonical).

Strategies swept (all deterministic — a random subset is excluded because
canonical images must be reproducibly produced):

- `all` — no budget (baseline; the *old* unbudgeted in-group behaviour).
- `smallest` — cheapest-cost edge-count classes first, up to `8·n·(log₂n+1)`,
  `maxPerClass = max(8, 2·log₂|G|)` (the production "ingroup" budget).
- `largest` — dearest-cost classes first, same budget.
- `diversity1` / `diversity4` — 1 (resp. 4) graph per edge-count class, no cost cap.

**Correctness held on every row:** stabilisers/normalisers `= GAP`
(`Stabilizer`/`Normalizer`), canonical images orbit-constant
(`canon(obj^g) = canon(obj)`). No wrong groups, no ill-defined canonical forms.

## Headline: bad-images `C` (order 2704, regular on 2704 of 2808 points)

| problem | strategy | graphs | arcs | nodes | wall (ms) |
|---|---|---:|---:|---:|---:|
| canon | all | 3013 | 7.88M | 54 | 6924 |
| | smallest | 44 | 60.6k | 3 | 53 |
| | diversity1 | 2 | 2.8k | 3 | 29 |
| setstab (`OnSets`) | all | 3013 | 7.88M | 0 | 7485 |
| | smallest | 44 | 60.6k | 7 | 542 |
| | diversity1 | 2 | 2.8k | 7 | 597 |

Budgeting is a **~100–250× wall-clock win** and reduces canonical node count
(54→3). Larger regular groups behave identically (set-stab, back-to-back):

| group (deg) | all | smallest | diversity1 |
|---|---|---|---|
| C1000 (1000) | 999g / 0n / 624ms | 18g / 0n / 13ms | 1g / 0n / 6ms |
| E512 (512) | 511g / 0n / 108ms | 18g / 0n / 5ms | 1g / 2n / 72ms |
| C504 (504) | 503g / 0n / 116ms | 16g / 0n / 5ms | 1g / 0n / 3ms |

Cutting to a single graph never blew up the search; every row was correct.

## Why budgeting helps: it's branch selection, not refinement

Adding orbital graphs can only make the equitable partition **finer** (verified:
the `all` set strictly refines the `smallest` set; the reduced sets are genuine
subsets). So fewer graphs never produce a finer partition — there is no
refinement bug. The node changes come from **which cell the branch selector
targets**:

- vole's default selector is `MostConnectedSmallest` (`rust/.../selector.rs`):
  branch on the cell of highest bliss-style "refining power", tie-broken
  smallest. Refining power sums over the orbital graphs present.
- On bad-images the root partition is the 3 orbit-cells `{2704, 52, 52}`. With
  3013 graphs the giant 2704 cell scores as most-connected and is branched
  **2704-wide**; with 44 graphs the signal flattens and a **52-cell** is
  targeted. That is the entire 54-vs-3 node difference — same partition,
  different target cell.
- The 2704 cell is also the *regular* orbit (trivial point stabiliser ⇒ no
  automorphism pruning of siblings), so it's the worst possible branch on two
  counts. `VOLE_SELECTOR=smallest` alone fixes the nodes, but not the shipping
  cost — so budgeting remains the right lever.

Note this is bliss's heuristic, **not** nauty's (nauty's default target cell is
position-based, not connectivity-based). The most-connected heuristic can pick
huge cells; it's a bet that extra refinement collapses the subtree, which fails
for low-stabiliser / near-regular groups — exactly where orbital graphs flood.

## The memory blow-up on deep searches, and the fix

A selector that branches *narrow-and-deep* (e.g. `SmallestMostConnected`, or any
deep search) exposed a real defect: **one unbudgeted orbital-graph build can
consume >12 GB**. Root cause, pinned by instrumentation:

- At a depth-1 stabiliser of bad-images (`|S|=52`, ~105 orbits on 2756 points),
  the point stabilisers are near-trivial, so suborbits are near-singletons and
  the group has **148,824 orbital-graph descriptors**.
- Each graph is materialised as a Digraph on `maxval` vertices — a full-length
  adjacency skeleton (`List([1..maxval], x->[])`), ~99% empty. `148824 × 2808`
  empty-list bags ≈ **6–12 GB** for one build. The driver is graph **count**
  (near-regular ⇒ trivial point stabs), not arcs (every graph has just 52).

Two changes make budgeting an actual memory bound:

1. **V+E cost model** (`getOrbitalListWithOptions`, Phase 2). Each graph now
   costs `maxval + arcs` (skeleton + edges), not arcs alone. Because every graph
   costs ≥ `maxval`, the graph *count* is bounded by `budget/maxval ≈ 8·log₂n`
   automatically — a tiny-arc flood can no longer slip through on a cheap arc
   bill. Class grouping stays keyed on arc count (V is constant), so normaliser
   atomicity and ordering are unchanged. Verified: the 148k-descriptor node now
   selects **94 graphs / 4 MB** with the cost budget alone (`maxPerClass=∞`);
   production (`maxPerClass` active) selects **10**.

2. **Same budget rule for the plain in-group path.** `_BTKit.getOrbitalList`
   (used by `GB_Con.InGroup` "InGroup-GB" and BacktrackKit's
   `InGroupWithOrbitals`) now passes `budgetMode := "ingroup"` — the *same* rule
   as the canonical `InGroupSimple` path (`StabTreeStabilizerReducedOrbitalGraphs`),
   gated on `BTKIT_ORBITAL_BUDGET`. Previously it passed `budgetMode := false`
   (unbudgeted), so a plain set/set-of-set stabiliser that branched into a small
   orbit of a near-regular group would hit the 148k-graph build and OOM. Now it
   is bounded end-to-end: `getOrbitalList(S,n)` for that node returns 10 graphs.
   The **normaliser** is a different refiner (`budgetMode "normaliser"`) and is
   untouched.

## Cross-family sweep (new cost model, all `eq_gap = true`)

| group | problem | all → smallest (graphs) | nodes (all→sm) | notes |
|---|---|---|---|---|
| C120 | setstab / setsetstab | 119→12 | 0→0 | set-of-set path budgeted too |
| C120 | norm | 119→119 | 0 | atomic+floor keeps all (regular) |
| A5reg | setstab | 59→10 | 0→3 | weaker refiner ⇒ few nodes, still fast |
| A5reg | norm | 59→59 | 0 | atomic+floor |
| F155 (31:5) | setstab / norm | 5→5 / 6→6 | 0 | already small; budget no-op |

**Normalisers on regular groups keep every graph** under all strategies: the set
must stay closed under N, so edge-count classes are atomic and a regular group's
one giant class is taken whole by the floor. Strategy has no effect there — the
tool for regular normalisers is the regOrbit deduction (Theißen §3.7), not
orbital selection.

## Canonical representatives shifted for flood groups (benign)

Under the V+E cost, `badC canon` now shows `eq_all=FALSE` for the budgeted
strategies (it was `true` under the old arcs-only cost). This is **expected and
sound**: a different graph subset induces a different canonical *ordering*, hence
a different (but valid) representative. Every such row is still orbit-constant
(`eq_gap=true`). Canonical images are defined *per strategy/cost model*; there is
no cross-cost stability guarantee (only determinism within a fixed version). The
vole test suite's pinned canonical values are unaffected (those groups' selection
didn't change), so all suites remain green.

## Recommendation / status

1. **Budgeting is the primary lever and is now memory-safe.** Both in-group
   paths (canonical + plain) share one rule (`budgetMode "ingroup"`); the V+E
   cost model bounds memory on deep searches. Default `smallest` (cheapest-cost
   first, `~8·n·log₂n` budget, `maxPerClass ~ 2·log₂|G|`).
2. **`maxPerClass` is now a *quality* knob, not the sole memory guard** — it
   spreads selection across arc-classes for refinement diversity, while the cost
   budget provides the hard memory bound. For deep near-regular nodes the flood
   is many equal-tiny-arc graphs, so a per-class count cap alone would still let
   thousands through; the V+E budget is what catches them.
3. **Normaliser path unchanged** (atomic classes + floor).
4. **Selector is a separate, orthogonal lever.** `SmallestMostConnected` avoids
   the wide-branch pathology but is only safe *with* budgeting (unbudgeted it
   goes narrow-deep and OOMs); not adopted as default pending its own sweep.

## Scaffolding status

`BTKIT_ORBITAL_STRATEGY` (BacktrackKit `gap/internal/util.g`) defaults to `false`
= production ("ingroup" budget for in-group paths, "normaliser" for normalisers,
both gated on `BTKIT_ORBITAL_BUDGET`). All three suites (vole 46 /
GraphBacktracking 12 / BacktrackKit 22) pass. The V+E cost model and the
`getOrbitalList` budget rule are always on in production.
