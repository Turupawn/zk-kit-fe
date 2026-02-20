# fe-zkkit comprehensive gas report (Merkle helpers)

This repo includes `fe-zkkit/bench`, a Foundry project that deploys equivalent Merkle helper contracts and benchmarks gas across:

- **Fe → Sonatina** (`fe build --backend sonatina`) at `--opt-level 0|1|2`
- **Fe → Yul → solc** (`fe build --backend yul --optimize --solc /usr/bin/solc`)
- **Solidity → solc** (reference implementation compiled by Foundry)

The benchmarked contract is `ZkKitMerkleBench` (LeanIMT + SMT helpers, Keccak-based).

## Executive summary

- **Recommended**: `fe → sonatina --opt-level 1` (and `2`) for these workloads.
- In this environment, **Sonatina `--opt-level 1` and `2` produce identical gas** for all benchmarks below.
- `--opt-level 0` is materially slower across the board.

## Toolchain / environment (verified)

- Date: **2026-02-20**
- `fe`: **0.26.0** (`/usr/local/bin/fe` from `PATH`)
- `fe` repo: `../fe` @ `c8dfd6656`
- `forge`: **1.5.0-stable**
- `solc`: **0.8.33** (`/usr/bin/solc`)
- Foundry optimizer: `optimizer=true`, `optimizer_runs=200` (`fe-zkkit/bench/foundry.toml`)

## Methodology

- Each row below is a dedicated Foundry test that makes **one `staticcall`** into an already-deployed contract.
- `vm.pauseGasMetering()/resumeGasMetering()` excludes calldata encoding and vector setup.
- `_warm()` (`extcodesize(target)`) is used to avoid cold-account access on the measured `staticcall`.
- For `update*` benches, `currentRoot` is computed **locally in the test contract while gas metering is paused** (to avoid pre-warming the measured contract via a reference-call).

## Gas results

Numbers come from:

```bash
cd fe-zkkit/bench
rm -rf out/fe
FE_SONA_OPT_LEVEL=0 forge test --ffi --offline -vvv --match-test testGas_bench_
rm -rf out/fe
FE_SONA_OPT_LEVEL=1 forge test --ffi --offline -vvv --match-test testGas_bench_
rm -rf out/fe
FE_SONA_OPT_LEVEL=2 forge test --ffi --offline -vvv --match-test testGas_bench_
```

| Benchmark | fe→sona O0 | fe→sona O1 | fe→sona O2 | fe→yul | Solidity |
|---|---:|---:|---:|---:|---:|
| LeanIMT `computeRoot` (siblings=7) | 10,241 | 9,788 | 9,788 | 9,975 | 10,640 |
| LeanIMT `verify` (siblings=7) | 10,316 | 9,869 | 9,869 | 10,045 | 10,639 |
| LeanIMT `updateRoot` (siblings=7) | 11,455 | 10,494 | 10,494 | 10,642 | 12,449 |
| LeanIMT `computeRoot` (siblings=32) | 16,093 | 14,105 | 14,105 | 15,068 | 16,564 |
| LeanIMT `verify` (siblings=32) | 16,172 | 14,190 | 14,190 | 15,205 | 16,563 |
| LeanIMT `updateRoot` (siblings=32) | 20,884 | 16,538 | 16,538 | 17,907 | 24,321 |
| SMT `computeRoot` (typical enables) | 23,093 | 18,057 | 18,057 | 20,477 | 19,544 |
| SMT `verify` (typical enables) | 23,192 | 18,162 | 18,162 | 20,549 | 19,632 |
| SMT `updateRoot` (typical enables) | 28,194 | 20,943 | 20,943 | 23,207 | 30,434 |
| SMT `computeRoot` (all enabled) | 16,213 | 14,243 | 14,243 | 15,764 | 16,558 |
| SMT `verify` (all enabled) | 16,267 | 14,303 | 14,303 | 15,857 | 16,621 |
| SMT `updateRoot` (all enabled) | 20,764 | 17,044 | 17,044 | 18,516 | 24,371 |

## Benchmark vectors (for context)

- **LeanIMT typical:** `siblingsLen=7`, `index=11`
- **LeanIMT 32:** `siblingsLen=32`, `index=0x1234_5678`
- **SMT typical:** `index=0x1234_5678`, `enables` has bits `{0,3,5,12,31}` set (5 provided siblings; packed)
- **SMT all-enabled:** `index=0x1234_5678`, `enables=0xffffffff` (32 provided siblings; packed)

## Source of benches

- Gas tests: `fe-zkkit/bench/test/ZkKitMerkleBench.t.sol` (functions prefixed `testGas_bench_`)
- Solidity reference: `fe-zkkit/bench/src/SolidityMerkleBench.sol`
- Fe contract: `fe-zkkit/zkkit_merkle` (`ZkKitMerkleBench` in `src/bench_contract.fe`)
