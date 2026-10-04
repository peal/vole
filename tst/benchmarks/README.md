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

The fresh-process normaliser runner requires Python 3.9+ and POSIX and uses
explicit JSONL inputs:

```sh
cargo build --release --manifest-path rust/Cargo.toml
python3 tst/benchmarks/normalisers.py tst/benchmarks/normalisers-smoke.jsonl \
  --output /tmp/vole-normalisers-run --repeats 5 --shortcut both
```

Each input records `id`, `degree`, and generators as permutation image lists
of exactly that degree, retaining fixed points. Optional `ambient_generators`
specify a proper ambient group. The smoke catalogue is a correctness pilot,
not a performance study. Supply larger family inputs for useful timings.

Every measurement starts a fresh GAP process using the bundled dependencies
and reconstructed groups. It records call wall time in nanoseconds, including
refiner/characteristic discovery, and monotonic process wall time including
startup. GAP's call timer uses the system wall clock. Method/trial order is
seeded and shuffled; paired methods receive the same GAP random-source seed.
`--selectors smallest,most-connected-smallest` crosses selector choices;
`--backends gap,direct,by-orbits,refiner:OrbitalRegOrbitCross` chooses methods.

`--timeout` caps the whole measurement process, including startup; on expiry
the runner kills its GAP/Rust process group. Exact group equality, generator
validity and ambient membership are checked in separate fresh processes with
`--verify-timeout`. An unavailable oracle is `oracle_unavailable`, never a
verified result. Incorrect results and crashes give a nonzero runner exit.

The output directory must be new. It contains copied inputs, configuration,
commit/build/source hashes, and a flushed `observations.jsonl` event log.
Join measurement and verification events by `(trial, backend)`; a `finished`
measurement is not a solved/verified instance until its verification event
says `verified`. Interrupted runs retain their completed measurement events.
Only compare timings of verified observations. Node/refiner counts describe
the last search, not totals over ByOrbits' constituent searches. Combined
memory is currently not measured or capped; this must be added before making
publication memory claims.

Harness failure-path tests:

```sh
python3 -m unittest discover -s tst/benchmarks -p 'test_normalisers.py'
```

Assisted-by: OpenAI Codex (GPT-6), runner, verification and regression tests.

Two legacy GAP entry points remain:

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
wider schema (see the header of `hunt.g`); `eq_gap` can be `unknown` and
`status` can be `unverified` when its GAP oracle did not finish. Its forked
process measurements are exploratory; use the fresh-process runner for cold
comparisons.

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

`Vole.Normalizer`'s default is **`OrbitalRegOrbitChar`** (experimental for
canonical use; canonical-image dispatch stays at `Orbital`). Plus `gap` as the reference,
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
- `setof-pairs.g`             — enumerate transformations / partial permutations,
                                and ordered/unordered pairs of them, up to
                                conjugacy, via `SetOf`/`TupleOf`/`MultisetOf`
                                canonical images; checks every count against a
                                published table (OEIS A001372 for the single
                                column). A heavy fan-out (~98k searches at n=4);
                                set `SETOF_PAIRS_MAXN` to cap the degree. SLOW.
- `pairs-one-canonical.g`     — readable example: unordered pairs of
                                transformations up to conjugacy via `SetOf`,
                                cutting `|M|^2` to `|singles| * |M|` by the
                                "one member canonical" fact (and explaining why
                                two-canonical fails). GAP `Orbits` cross-check at
                                n <= 4; `PAIRS_ONE_CANONICAL_MAXN` caps degree.
- `orderly-transformations.g` — orderly generation of single transformations up
                                to conjugacy, building n from n-1 through partial
                                transformations; self-checks reps = A126285(n)
                                and totals = A001372(n) at every level. Reaches
                                n=13 in ~5 min; `ORDERLY_MAXN`/`ORDERLY_BUDGET`.

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
