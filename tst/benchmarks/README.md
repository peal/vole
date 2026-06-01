# Benchmark harness

Performance measurement, kept separate from the correctness bank
(`tst/bank/`). Bank entries are correctness gates run per PR; benchmark
entries are curated for empirical comparison and are **not** run by the
test suite (`testall.g` only runs `.tst` files).

Search statistics (node count, refiner calls, solver time) are read from
the global `_Vole.LastStats`, which `_Vole.Solve` sets on every search.
(The old per-call `raw := true` option that used to carry this record has
been removed.) So the pattern throughout these scripts is: run a Vole
search, then read `_Vole.LastStats.search_nodes` etc. immediately after.

## Drivers

Two self-contained entry points:

    # Curated harness: cyclic-prime, primitive, intransitive families.
    gap -q -c 'Read("tst/benchmarks/run.g"); RunBenchmarks(); QUIT;'

    # Loss hunt: where do we lose to GAP, and by how much (BUDGET secs/call).
    gap -q -c 'BUDGET := 60; Read("tst/benchmarks/run-hunt.g"); QUIT;'

`run.g` writes CSV to stdout and to `tst/benchmarks/latest.csv`.
`run-hunt.g` writes `tst/benchmarks/hunt.csv`; `analyse-hunt.g` summarises
it.

The remaining `.g` files are standalone investigations — each is run on
its own (`gap -q -c 'Read("tst/benchmarks/<file>.g"); QUIT;'` or, for the
auto-running ones, just `Read`) and is documented in the catalogue below.

## CSV format

`run.g`/`helpers.g` emit rows of the form

    problem_id,variant,nodes,refiner_calls,wall_time_ms,size,vole_eq_gap

where `variant` names the refiner (or the `gap` reference), `size` is the
order of the returned group (cross-check), and `vole_eq_gap` records
whether Vole's answer equalled GAP's. The `gap` reference row reports
`nodes = refiner_calls = -1` (not applicable). `run-hunt.g` uses its own
wider schema (see the header of `hunt.g`).

## Refiner variants

Normaliser/conjugacy refiners, defined in
`dependencies/GraphBacktracking/gap/constraints/normaliser.g` and selected
by name (`GB_Con.Normaliser<name>`, or the `refiner` option on
`Vole.Normalizer`). All compute the same normaliser; they differ only in
which deductions they push, hence in node count and speed.

| name                            | orbital graphs       | block systems | regular-orbit deductions          |
|---------------------------------|----------------------|---------------|-----------------------------------|
| `Simple`                        | none (orbits only)   | none          | –                                 |
| `Simple2`                       | none (orbits only)   | root only     | –                                 |
| `OrbitalNone`                   | never                | root only     | – (≈ `Simple2`)                   |
| `OrbitalRoot`                   | root only            | root only     | –                                 |
| `Orbital`                       | every depth          | root only     | –                                 |
| `OrbitalDeep`                   | every depth          | every depth   | –                                 |
| `OrbitalSmall`                  | every depth, capped  | root only     | –                                 |
| `OrbitalRegOrbit`               | every depth          | root only     | §3.7 regular orbit                |
| `OrbitalRegOrbitChar`           | every depth          | root only     | §3.7.3 regular char. subgroup     |
| `OrbitalRegOrbitCross`          | every depth          | root only     | + cross-orbit propagation         |
| `OrbitalRegOrbitCrossNoPropose` | every depth          | root only     | cross, no branch-cell proposal    |

`Vole.Normalizer`'s default is **`OrbitalRegOrbitChar`** (canonical-unsafe;
canonical-image dispatch stays at `Orbital`). Plus `gap` as the reference,
calling `Normalizer(SymmetricGroup(n), G)`.

## Catalogue

Curated harness (driven by `run.g`):
- `helpers.g`        — `BenchVariant`/`BenchSweep`/`BenchWriteHeader`; the shared CSV plumbing.
- `cyclic-prime.g`   — `C_p ≤ S_p` regular action (Theißen's motivating regular-orbit case).
- `primitive.g`      — hand-picked non-2-transitive primitive groups.
- `intransitive.g`   — direct and wreath products of small groups.

Loss hunt:
- `hunt.g` / `run-hunt.g` — sweep many families under a per-call budget; record where Vole loses to GAP.
- `analyse-hunt.g`        — post-hoc summary of `hunt.csv`.

Scaling sweeps (push a family until runs take seconds):
- `scaling-volewins.g`        — families where Vole beats GAP at small sizes (wreaths, deep wreaths, intransitive). SLOW.
- `scaling-direct-products.g` — direct/semidirect product families.
- `scaling-shortcut.g`        — `root_aut_shortcut` on/off, abelian-regular family.
- `drill-cp-power.g`          — `(C_p)^k` node-count drill, Vole vs GAP.

Canonical image of a group:
- `canonical-group.g`         — canonical image of a group inside another.
- `canonical-refiner-sweep.g` — the same across refiner variants.

Showcase (curated input/comparison pairs):
- `showcase.g`, `showcase-big.g`.

Probes / one-off investigations:
- `probe-slow-gap.g`        — find input classes where GAP's `Normalizer` is slow.
- `probe-slow-vole.g`       — Vole's behaviour on the slow-GAP inputs.
- `probe-orbital-set-aut.g` — root-level set-stabiliser of H's orbital graphs.
- `refiner-sweep-slow.g` / `test-byorbits-slow.g` / `trace-slow-subdirect.g` — the 4 Vole-slow subdirect cases.
- `big-norm.g`              — larger normalisers where wall time clears the subprocess overhead.
- `dnpg-override.g`         — the `DoNormalizerPermGroup` override hook.
- `intrans-constructor.g`   — construct intransitive groups and diff node counts across refiners.
- `regorbit3-bench.g`       — the cross-propagation (`RegOrbitCross`) refiner.
- `compress-ab.g`           — A/B for the graph-compression pass (`_BTKit.compressGraph`).
- `profile-normaliser.g`    — per-phase profiling of a normaliser refiner.
- `vole-vs-bliss-digraph.g` — pure digraph-automorphism timing, Vole vs Bliss.

Several of these run for minutes by design (the `scaling-*` and `*-slow`
files especially): they bound GAP with `IO_CallWithTimeout`, but Vole runs
in-process and is **not** capped (Vole has no timeout), so a single hard
input runs to completion.

## Artifacts

`*.csv` and `*.log` in this directory are run outputs, regenerated by the
drivers, and are git-ignored (see `.gitignore`). Don't commit them.

## When to add a benchmark

- A bank failure surfaced a hard input — add it here with its label so we
  can track when performance catches up to correctness.
- A literature problem is worth tracking (e.g. one from [CJR22]).
- A class of inputs becomes the new bottleneck.

This file is a living artefact, like the test bank.
