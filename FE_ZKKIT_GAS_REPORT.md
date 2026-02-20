# fe-zkkit gas results (Merkle helpers)

This repo includes `fe-zkkit/bench`, a Foundry project that deploys equivalent Merkle helper contracts and compares:

- **Fe → Sonatina** (`fe build --backend sonatina`)
- **Fe → Yul → solc** (`fe build --backend yul --optimize --solc /usr/bin/solc`)
- **Solidity → solc** (compiled by Foundry)

The benchmarked contract is `ZkKitMerkleBench` (LeanIMT + SMT helpers, Keccak-based).

## What the benchmarks do

The gas benches measure the runtime cost of computing and updating Merkle roots for two Keccak-based helpers:

- **LeanIMT** (`computeLeanIMTRoot` / `updateLeanIMTRoot`): iteratively hashes `keccak256(left || right)` up the tree for `siblingsLen` levels, choosing `(left,right)` order from the `index` bit at each level.
- **SMT** (`computeSMTRoot` / `updateSMTRoot`): iterates 32 levels; `enables` is a bitmask that selects whether each level uses a provided sibling or the default `zero` node. In the non-all-enabled case it also updates the default node each level via `zero = keccak256(zero || zero)`.

Measurement notes:

- Each benchmark is one `staticcall` into an already-deployed contract.
- `vm.pauseGasMetering()/resumeGasMetering()` excludes calldata encoding and vector setup, and `_warm()` (`extcodesize(target)`) avoids cold-account access on the measured call.
- The `update*` benches compute `currentRoot` using the Solidity reference while gas metering is paused, then call `update*` with `newLeaf = oldLeaf ^ 0x1234`.

## Toolchain / settings

- Date: **2026-02-20**
- `fe` **0.26.0** (`/usr/local/bin/fe` from `PATH`)
- `fe` repo: `../fe` @ `2abb2602b`
- `forge` **1.5.0-stable**
- `solc` **0.8.33** (`/usr/bin/solc`)
- Foundry optimizer: `optimizer=true`, `optimizer_runs=200` (`fe-zkkit/bench/foundry.toml`)

### Backend flags used

- **fe→sona:** `--backend sonatina --opt-level 2` (via `FE_SONA_OPT_LEVEL=2`)
- **fe→yul(solc):** `--backend yul --optimize --solc /usr/bin/solc`

## Gas results

Numbers below come from `forge test --ffi --offline -vvv --match-test testGas_bench_` and use `vm.pauseGasMetering()/resumeGasMetering()` to exclude calldata construction / vector setup. Each measurement is one `staticcall` into the deployed contract.

| Benchmark | fe→sona (sonatina) | fe→yul (solc `--optimize`) | Solidity (solc) |
|---|---:|---:|---:|
| `computeLeanIMTRoot` (siblings=7) | 9,783 | 9,945 | 10,618 |
| `computeLeanIMTRoot` (siblings=32) | 14,194 | 15,104 | 16,520 |
| `updateLeanIMTRoot` (siblings=7) | 10,406 | 10,620 | 7,883 |
| `computeSMTRoot` (typical enables) | 18,128 | 20,530 | 19,499 |
| `computeSMTRoot` (all enabled) | 14,238 | 15,737 | 16,447 |
| `updateSMTRoot` (typical enables) | 21,073 | 23,237 | 25,912 |

## Bench vectors (for context)

- **LeanIMT typical:** `siblingsLen=7`, `index=11`
- **LeanIMT 32:** `siblingsLen=32`, `index=0x1234_5678`
- **SMT typical:** `index=0x1234_5678`, `enables` has bits `{0,3,5,12,31}` set (5 provided siblings)
- **SMT all-enabled:** `index=0x1234_5678`, `enables=0xffffffff` (32 provided siblings)

## Reproduce locally

```bash
cd fe-zkkit/bench
rm -rf out/fe
FE_SONA_OPT_LEVEL=2 forge test --ffi --offline -vvv --match-test testGas_bench_

# Full fuzz + diffs + gas benches:
rm -rf out/fe
FE_SONA_OPT_LEVEL=2 forge test --ffi --offline -vvv
```
