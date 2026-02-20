# fe-zkkit benchmarks (Foundry)

This is a self-contained Foundry project that helps evaluate **Fe-generated EVM code** against an equivalent **Solidity reference implementation**.

## What it does

- **Fuzzing**: differential-checks Fe→Sonatina, Fe→Yul→solc, and a Solidity reference across `compute*`, `verify*`, and `update*` (including revert/false cases).
- **Gas**: `forge test --gas-report` shows per-call gas for Fe vs Solidity variants on representative inputs.

## Prereqs

- Foundry (`forge`)
- A `fe` binary available in your `PATH`

## Run

From `fe-zkkit/bench`:

```bash
# Single Sonatina opt-level (0/1/2):
FE_SONA_OPT_LEVEL=2 forge test --ffi --offline -vvv

forge test --ffi --offline -vvv

# Gas benches used by the report (compute/verify/update; typical + worst-case vectors):
rm -rf out/fe
FE_SONA_OPT_LEVEL=2 forge test --ffi --offline -vvv --match-test testGas_bench_
```

## Reports

- `../../FE_ZKKIT_EQUIVALENCE_REPORT.md`
- `../../FE_ZKKIT_COMPREHENSIVE_GAS_REPORT.md`

## Stronger equivalence runs

```bash
# Multi-seed, high fuzz-runs, across Sonatina opt-levels 0/1/2:
FUZZ_RUNS=10000 SEEDS="1 2 3 4 5" EXHAUSTIVE=0 ./scripts/verify_equivalence.sh

# Optional bounded exhaustive sweeps (slower):
EXHAUSTIVE=1 FE_ZKKIT_EXHAUSTIVE_LEANIMT_MAX_SIBLINGS=5 FE_ZKKIT_EXHAUSTIVE_SMT_MAX_BITS=5 FE_ZKKIT_EXHAUSTIVE_VALUE_MAX=3 \
  ./scripts/verify_equivalence.sh
```
