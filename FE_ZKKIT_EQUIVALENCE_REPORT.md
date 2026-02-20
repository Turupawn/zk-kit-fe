# fe-zkkit equivalence report (Sonatina backend)

This report documents the current equivalence status of the **Fe Sonatina** backend for the Merkle helper bench in `fe-zkkit/bench`.

## Executive summary (verified)

- ✅ `fe build --backend sonatina --opt-level 0|1|2` matches the Solidity reference for LeanIMT + SMT helpers.
- ✅ `fe build --backend yul --optimize --solc /usr/bin/solc` matches the same Solidity reference.
- Validation includes fuzzing, deterministic diff tests, negative cases (revert/false), invariance properties, and bounded exhaustive sweeps over small domains.

## Toolchain / environment (verified)

- Date: **2026-02-20**
- `fe`: **0.26.0** (`/usr/local/bin/fe` from `PATH`)
- `fe` repo: `../fe` @ `c8dfd6656`
- `forge`: **1.5.0-stable**
- `solc`: **0.8.33** (`/usr/bin/solc`)

## Scope

The bench compares three EVM implementations of the same API:

- **Fe → Sonatina**: `fe build --backend sonatina` (opt-level via `FE_SONA_OPT_LEVEL`)
- **Fe → Yul → solc**: `fe build --backend yul --optimize --solc /usr/bin/solc`
- **Solidity reference**: `fe-zkkit/bench/src/SolidityMerkleBench.sol`

Functions under test:

- LeanIMT: `computeLeanIMTRoot`, `verifyLeanIMT`, `updateLeanIMTRoot`
- SMT: `computeSMTRoot`, `verifySMT`, `updateSMTRoot`

## What “equivalence” means here

For the same inputs:

- `compute*` returns identical roots across implementations.
- `verify*` returns identical booleans across implementations (including `false` for a corrupted root).
- `update*` returns identical new roots, and **reverts identically** when `currentRoot` does not match the proof.

Additionally, the test suite checks semantic invariants that should hold regardless of implementation details (e.g., unused siblings are ignored, high bits are ignored where appropriate).

## How it’s verified

The Foundry test suite in `fe-zkkit/bench/test/ZkKitMerkleBench.t.sol` includes:

- **Differential fuzzing** against the Solidity reference for all compute/verify/update functions.
- **Negative cases**
  - `verify*(root ^ 1) == false` across all implementations.
  - `update*(currentRoot ^ 1, ...)` reverts across all implementations.
  - `computeLeanIMTRoot(..., siblingsLen=33, ...)` reverts across all implementations.
- **Invariance properties**
  - LeanIMT: index bits above `siblingsLen` ignored; siblings after `siblingsLen` ignored.
  - SMT: index bits above depth ignored; enables only uses low 32 bits; siblings after `popcount(enables)` ignored.
- **Structural cross-check**: SMT roots match LeanIMT roots when SMT packed siblings are expanded using the canonical default `zero` nodes.
- **Optional bounded exhaustive sweeps** (small input domains) for LeanIMT and SMT.

## Reproduce locally

From `fe-zkkit/bench`:

```bash
rm -rf out/fe
FE_SONA_OPT_LEVEL=2 forge test --ffi --offline -vvv
```

Run across all Sonatina opt-levels with higher confidence (multi-seed, higher fuzz runs):

```bash
cd fe-zkkit/bench
FUZZ_RUNS=10000 SEEDS="1 2 3 4 5" EXHAUSTIVE=0 ./scripts/verify_equivalence.sh
```

Enable bounded exhaustive sweeps (slower):

```bash
cd fe-zkkit/bench
EXHAUSTIVE=1 \
  FE_ZKKIT_EXHAUSTIVE_LEANIMT_MAX_SIBLINGS=5 \
  FE_ZKKIT_EXHAUSTIVE_SMT_MAX_BITS=5 \
  FE_ZKKIT_EXHAUSTIVE_VALUE_MAX=3 \
  ./scripts/verify_equivalence.sh
```

## Notes / limitations

- This is **strong empirical validation**, not a formal proof.
- Equivalence is defined relative to the Solidity reference implementation shipped in this repo.
