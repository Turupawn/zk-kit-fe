# fe-zkkit Sonatina gas comparison (master vs `sbillig/sona-alloca`)

This report compares gas usage for the Merkle helper bench in `fe-zkkit/bench` when compiling the same Fe contract with:

- `../fe` **master** @ `fe3257412b30` (`fe 26.0.0-alpha.5`)
- `../fe` **remotes/sbillig/sona-alloca** @ `946a186b67a5` (`fe 26.0.0-alpha.5`)

## Executive summary (verified)

- `sbillig/sona-alloca` is **higher gas for every Sonatina benchmark** below: **+75 to +2,219 gas** (**+0.71% to +12.85%**).
- Largest regression is **SMT “typical enables”** (`computeRoot` / `verify`): **+2,219 gas** (≈ **+12.8%**).
- **Fe→Yul and Solidity gas are identical** between both runs, so the change is isolated to **Fe→Sonatina output** (not the bench harness).
- A quick equivalence check passed for both revisions at `FE_SONA_OPT_LEVEL=2` (`testFuzz_*` + `test_diff_*`, `--fuzz-runs 10000`, `--fuzz-seed 1`).

## Toolchain / environment (verified)

- Date: **2026-02-23**
- `forge`: **1.5.0-stable** (`1c5785446`)
- `solc`: **0.8.33** (`/usr/bin/solc`)
- Foundry optimizer: `optimizer=true`, `optimizer_runs=200` (`fe-zkkit/bench/foundry.toml`)
- Sonatina opt-level: `FE_SONA_OPT_LEVEL=2`

## Sonatina dependency versions

Both Fe revisions report `fe 26.0.0-alpha.5`, but they pin different Sonatina git revs:

- **master**: `rev=1b6be0b` (`1b6be0be3c15adeb4f60087733badc484df1e800`)
- **sbillig/sona-alloca**: `rev=124ae14` (`124ae14605f238fe8fbbf275bcf39519d1e66f3e`)

## Gas results (Fe→Sonatina, O2)

| Benchmark | master `fe` (sonatina O2) | `sona-alloca` `fe` (sonatina O2) | Δ gas | Δ% |
|---|---:|---:|---:|---:|
| LeanIMT `computeRoot` (siblings=7) | 9,788 | 9,959 | +171 | +1.75% |
| LeanIMT `verify` (siblings=7) | 9,869 | 10,040 | +171 | +1.73% |
| LeanIMT `updateRoot` (siblings=7) | 10,494 | 10,569 | +75 | +0.71% |
| LeanIMT `computeRoot` (siblings=32) | 14,105 | 14,891 | +786 | +5.57% |
| LeanIMT `verify` (siblings=32) | 14,190 | 14,976 | +786 | +5.54% |
| LeanIMT `updateRoot` (siblings=32) | 16,538 | 16,898 | +360 | +2.18% |
| SMT `computeRoot` (typical enables) | 17,270 | 19,489 | +2,219 | +12.85% |
| SMT `verify` (typical enables) | 17,375 | 19,594 | +2,219 | +12.77% |
| SMT `updateRoot` (typical enables) | 20,345 | 22,504 | +2,159 | +10.61% |
| SMT `computeRoot` (all enabled) | 14,247 | 15,027 | +780 | +5.47% |
| SMT `verify` (all enabled) | 14,307 | 15,087 | +780 | +5.45% |
| SMT `updateRoot` (all enabled) | 17,048 | 17,402 | +354 | +2.08% |

## Opcode deltas (Fe→Sonatina, O2)

For several representative benches, we collected opcode-level traces using `forge test --debug --dump ...` and analyzed the **`STATICCALL` frame** (the actual call into the Fe Sonatina contract). For each opcode, we summed:

- **count**: number of executed steps with that opcode
- **gas**: sum of per-step `gas_cost` reported by the debugger

### Summary

- The regression is dominated by **additional stack-manipulation opcodes** (`SWAP*`, `DUP*`, `POP`).
- **No increase in `KECCAK256` count** was observed in the SMT “typical enables” path (still **32**).

### LeanIMT `computeRoot` (siblings=32): +786 gas

| Opcode | Δ count | Δ gas |
|---|---:|---:|
| `SWAP1` | +128 | +384 |
| `SWAP2` | +102 | +306 |
| `SWAP3` | +32 | +96 |

### SMT `computeRoot` (typical enables): +2,219 gas

| Opcode | Δ count | Δ gas |
|---|---:|---:|
| `SWAP5` | +179 | +537 |
| `SWAP2` | +159 | +477 |
| `SWAP1` | +152 | +456 |
| `SWAP3` | +110 | +330 |
| `SWAP4` | +104 | +312 |
| `POP` | +64 | +128 |
| `DUP7` | +32 | +96 |
| `DUP6` | +32 | +96 |
| `DUP5` | +32 | +96 |

`SMT verify (typical)` shows the same opcode deltas and totals (+2,219 gas).

### SMT `updateRoot` (typical enables): +2,159 gas

| Opcode | Δ count | Δ gas |
|---|---:|---:|
| `SWAP6` | +192 | +576 |
| `SWAP3` | +158 | +474 |
| `SWAP4` | +123 | +369 |
| `SWAP5` | +78 | +234 |
| `SWAP1` | +76 | +228 |
| `SWAP2` | +59 | +177 |
| `POP` | +64 | +128 |
| `DUP8` | +32 | +96 |
| `DUP7` | +32 | +96 |
| `DUP6` | +32 | +96 |

## Reproduce locally

Build each Fe revision (so you have two `fe` binaries), then run the bench from `fe-zkkit/bench` with the desired `fe` first on `PATH`:

```bash
rm -rf out/fe
PATH="/path/to/fe/target/release:$PATH" FE_SONA_OPT_LEVEL=2 \
  forge test --ffi --offline -vvv --match-test testGas_bench_
```
