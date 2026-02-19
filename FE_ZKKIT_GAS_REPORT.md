# fe-zkkit gas results (Merkle helpers)

This repo includes `fe-zkkit/bench`, a Foundry project that deploys equivalent Merkle helper contracts and compares:

- **Fe → Sonatina** (`fe build --backend sonatina`)
- **Fe → Yul → solc** (`fe build --backend yul --optimize --solc /usr/bin/solc`)
- **Solidity → solc** (compiled by Foundry)

The benchmarked contract is `ZkKitMerkleBench` (LeanIMT + SMT helpers, Keccak-based).

## Toolchain / settings

- `fe` **0.26.0** (built from `../fe` at commit `b11d78fb4`)
- `forge` **1.5.0**
- `solc` **0.8.33** (`/usr/bin/solc`)
- Foundry optimizer: `optimizer=true`, `optimizer_runs=200` (`fe-zkkit/bench/foundry.toml`)

### Backend flags used

- **fe→sona:** `--backend sonatina --opt-level 0`
  - Note: `--opt-level 1/2` currently fails fuzz equivalence for this bench (as of `b11d78fb4`); see `FE_ZKKIT_SONATINA_EQUIVALENCE_REPORT.md`. The gas report pins opt-level 0 for correctness.
- **fe→yul(solc):** `--backend yul --optimize --solc /usr/bin/solc`

## Gas results

Numbers below come from `forge test --ffi --offline -vvv --match-test testGas_bench_` and use `vm.pauseGasMetering()/resumeGasMetering()` to exclude calldata construction / vector setup. Each measurement is one `staticcall` into the deployed contract.

| Benchmark | fe→sona (sonatina) | fe→yul (solc `--optimize`) | Solidity (solc) |
|---|---:|---:|---:|
| `computeLeanIMTRoot` (siblings=7) | 10,465 | 9,945 | 10,618 |
| `computeLeanIMTRoot` (siblings=32) | 17,186 | 15,104 | 16,520 |
| `updateLeanIMTRoot` (siblings=7) | 12,583 | 11,548 | 7,883 |
| `computeSMTRoot` (typical enables) | 23,847 | 20,530 | 19,499 |
| `computeSMTRoot` (all enabled) | 17,212 | 15,737 | 16,447 |
| `updateSMTRoot` (typical enables) | 39,355 | 32,628 | 25,912 |

## Bench vectors (for context)

- **LeanIMT typical:** `siblingsLen=7`, `index=11`
- **LeanIMT 32:** `siblingsLen=32`, `index=0x1234_5678`
- **SMT typical:** `index=0x1234_5678`, `enables` has bits `{0,3,5,12,31}` set (5 provided siblings)
- **SMT all-enabled:** `index=0x1234_5678`, `enables=0xffffffff` (32 provided siblings)

## Reproduce locally

```bash
cd fe-zkkit/bench
rm -rf out/fe
forge test --ffi --offline -vvv --match-test testGas_bench_

# Full fuzz + diffs + gas benches:
rm -rf out/fe
forge test --ffi --offline -vvv
```
