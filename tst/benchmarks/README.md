# Benchmark harness

Performance measurement, separate from the correctness bank
(`tst/bank/`). Bank entries are gates per PR; benchmark entries are
curated for empirical comparison.

Outputs CSV rows of the form

    problem_id,variant,nodes,refiner_calls,wall_time_ms,size

where `variant` names the refiner (or comparison group like `gap`).
Baselines are checked in under `baselines/` so each PR can produce a
diff.

## Variants compared

For normaliser/conjugacy problems, the harness compares five variants
(see `dependencies/GraphBacktracking/gap/constraints/normaliser.g`):

| name                  | orbital graphs at root | orbital graphs deeper | block systems        |
|-----------------------|------------------------|------------------------|----------------------|
| `Simple`              | no (orbits only)       | no (orbits only)       | no                   |
| `Simple2`             | no                     | no                     | root only            |
| `OrbitalNone`         | no                     | no                     | root only (= Simple2)|
| `OrbitalRoot`         | **yes**                | no                     | root only            |
| `Orbital`             | **yes**                | **yes**                | root only            |
| `OrbitalDeep`         | **yes**                | **yes**                | every depth          |

Plus `gap` as a reference (calls `Normalizer(SymmetricGroup(n), G)`).

## Running

    gap -q -c 'Read("tst/benchmarks/run.g"); RunBenchmarks(); QUIT;'

CSV is written to stdout and to `tst/benchmarks/latest.csv`.

## When to add a benchmark

Whenever:
- A bank failure surfaced a hard input — add it here too with its phase
  label, so we can track when performance catches up to correctness.
- A literature problem is worth tracking (e.g. one from [CJR22]).
- A class of inputs becomes the new bottleneck.

This file is a living artefact, just like the test bank.
