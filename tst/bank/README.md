# Test bank

A correctness bank for Vole, comparing results against the GAP library as
the source of truth. The bank sweeps broadly over GAP's group libraries
(TransitiveGroups, PrimitiveGroups, SmallGroups) so the test count grows
with library coverage rather than requiring bespoke per-class tests.

The bank is **living infrastructure**: every later PR extends it (new
group classes; permanent regression entries for fixed bugs). Plan files
are written; tests are forever.

The bank is separate from the benchmark suite (`tst/benchmarks/`, see
its own README): bank entries are *correctness* gates, run on every PR;
benchmarks are curated *performance* measurements.

## Layout

- `helpers.g` — common helpers (`BankCompareNormaliser`, etc.).
- `run-bank.g` — driver that dispatches to each source file based on
  the requested mode.
- One file per source:
  - `transgrp.g` — `TransitiveGroup(n, k)` over all `(n, k)`.
  - `primgrp.g` — `PrimitiveGroup(n, k)` over all `(n, k)`.
  - `smallgrp.g` — `AllSmallGroups(n)` mapped to a faithful permutation
    representation via `IsomorphismPermGroup`.
  - `intransitive.g` — direct products and wreath products of small
    transitive groups.
  - `random.g` — random subgroups of `S_n`, seeded for reproducibility.
  - `regression.g` — permanent entries for inputs that exposed a bug.
    New entries are mandatory whenever a bug is found and fixed.

## Modes

Every source file is parametric over a run mode:

| Mode      | Intended runtime | Degree cap initial | Use                  |
|-----------|------------------|--------------------|----------------------|
| `quick`   | ≤ 1 min          | degrees ≤ 10       | every PR CI gate     |
| `nightly` | ≤ 30 min         | degrees ≤ 14       | unattended nightly   |
| `full`    | hours            | as much as fits    | manual / release     |

Initial caps are tight because today's `Vole.Normalizer` is much weaker
than GAP and breaks/hangs on larger inputs. Each later phase raises the
cap as Vole improves. The current caps live at the top of each source
file under a clearly-named constant.

## Running

```
gap -q -c 'Read("tst/bank/run-bank.g"); RunBank("quick"); QUIT;'
```

or via the shell driver (once it lands as part of Phase G.6):

```
./run-bank.sh quick
./run-bank.sh nightly
./run-bank.sh full
```

## Adding a new source

1. Drop a `mybank.g` file into `tst/bank/`.
2. Define `RunBank_mybank := function(mode) ... end;` taking a mode
   string (`"quick"` / `"nightly"` / `"full"`).
3. Inside, decide the degree cap (or other size cap) from the mode.
4. Loop over inputs; call `BankCompareNormaliser(n, G)` (or
   `BankCompareNormaliser_VsGroup(G_outer, G_inner)`) for each.
5. Add a `Read("tst/bank/mybank.g")` line and a dispatch entry to
   `run-bank.g`.

## When a test fails

`BankCompareNormaliser` dumps the input degree, generators, expected
group order, and Vole's result on mismatch. **The failing input is then
added permanently to `regression.g`** so it can never silently regress
again.
