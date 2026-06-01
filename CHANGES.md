# Changes to Vole

This file records notable, user-visible changes between released versions
of Vole. The format follows [Keep a Changelog](https://keepachangelog.com/).

## Version 1.1.0 (01/06/2026)

The headline of this release is support for computing **normalisers** and
**canonical images of groups** by directed-graph backtracking, together with
substantial performance work on that machinery.

### Added

- **Normalisers of permutation groups** via `Vole.Normalizer(G, U)`, computed
  by graph backtracking (orbital graphs, block systems, and — where one
  exists — a regular orbit). This is competitive with, and often faster than,
  &GAP;, especially on intransitive and imprimitive groups; &GAP; keeps an
  edge on affine and some primitive groups, where it has closed-form methods.
- **Canonical images of groups under conjugacy** via
  `Vole.CanonicalImage(G, H, OnPoints)` and `Vole.CanonicalPerm`. Two
  subgroups are conjugate in `G` exactly when their canonical images are
  equal, giving a direct conjugacy test for subgroups. The canonical-image
  search automatically uses a *canonical-safe* refiner (see the new manual
  section for the safety boundary).
- `Vole.DDPD`: disjoint direct-product decomposition of a permutation group
  (Chang–Jefferson), used to factor highly-intransitive normaliser problems.
- An optional hook to install Vole's normaliser in place of &GAP;'s
  `DoNormalizerPermGroup`, so existing code calling `Normalizer` can use Vole
  transparently.
- A settable branching-cell selector strategy, via the `selector` option or
  the `VOLE_SELECTOR` environment variable.
- A new manual section, *Normalisers and canonical images of groups*,
  including worked examples and the canonical-safety discussion.

### Changed (performance)

- **Graph compression.** Clique and complete-multipartite components in the
  orbital and block-system graphs pushed by the normaliser refiner are now
  replaced by compact auxiliary-vertex gadgets with the same automorphism
  group. This sharply reduces the data sent to, and refined by, the solver —
  e.g. on `S_10 wr S_10` the orbital graphs shrink from 9900 to 210 arcs —
  for a 2–3.5× end-to-end speedup on symmetric-base wreaths, which previously
  were Vole's weakest normaliser class.
- **1-WL equivalence key.** Orbital graphs are grouped into families using a
  1-dimensional Weisfeiler–Leman colour-refinement invariant instead of a
  Bliss canonical form. This removes the external Bliss/Nauty graph tooling
  from the refiner and eliminates what had been the dominant GAP-side cost on
  root-heavy groups.
- **No unconditional `FittingSubgroup`.** The characteristic-subgroup search
  in the default normaliser refiner now computes `FittingSubgroup` only for
  solvable groups, removing a multi-second pathology on large non-solvable
  imprimitive inputs.
- **Cheaper normaliser pre-check.** `Vole.Normalizer` no longer runs a full
  `IsNormal(G, U)`; it uses only the constant-time checks &GAP; itself uses
  (trivial `U`, or `U = G`), relying on the backtrack for the rest.
- **Free stabiliser chain.** Group results carry the base, strong generating
  set, and size found during the search, so &GAP; receives a usable
  stabiliser chain without rerunning Schreier–Sims.

### Removed

- The `raw` option has been removed from the `Vole.` and `VoleFind.`
  interfaces. It returned an undocumented internal record and existed mainly
  for early debugging. Search statistics (node count, refiner calls, solver
  time) — the one part of that record with ongoing use — are now written to
  the internal `_Vole.LastStats` after every search, which is what the test
  and benchmark harnesses read. To inspect what a search is doing, use
  `InfoVole` or the `trace` diagnostics.

### Notes

- Canonical images are canonical only relative to a given build: as documented,
  the specific image returned may differ between versions of Vole or &GAP; and
  across hardware. Some embedded example outputs in the manual changed
  accordingly in this release.

## Version 1.0.0 (29/05/2025)

- First released version, providing high-performance backtrack search in
  permutation groups (stabilisers, canonical images of sets/tuples/digraphs,
  representatives, intersections) through the simple `Vole.` interface and the
  full `VoleFind.` interface.
