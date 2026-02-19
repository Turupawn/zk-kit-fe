# Sonatina backend equivalence failures (fe-zkkit/bench)

This report documents a reproducible equivalence failure in the Fe **Sonatina** backend when compiling the `fe-zkkit/zkkit_merkle` contract(s) with `--opt-level 1` or `2`.

## Summary

- ✅ `fe build --backend sonatina --opt-level 0` passes fuzz equivalence for `fe-zkkit/bench`.
- ❌ `fe build --backend sonatina --opt-level 1|2` fails equivalence (LeanIMT + SMT).
- ✅ `fe build --backend yul --optimize --solc /usr/bin/solc` continues to match Solidity.
- The incorrect Sonatina output observed in multiple cases equals `keccak256(0x00…00)` over **64 bytes** (`0xad3228…5fb5`), consistent with `keccak256(left||right)` hashing **zeroed memory**.

## Environment (observed)

- Date: **2026-02-19**
- `forge`: **1.5.0-stable**
- `solc`: **0.8.33** (`/usr/bin/solc`)
- `fe`: **0.26.0** (local `../fe` repo at commit `67711a769`)

## Reproduction

The Foundry tests compile the Fe contracts via FFI in `fe-zkkit/bench/test/ZkKitMerkleBench.t.sol`.

From `fe-zkkit/bench`:

```bash
rm -rf out/fe
forge test --ffi --offline -vvv --match-test test_diff_LeanIMT_computeRoot_smallValues_matchesSolidity
```

This should pass by default (Sonatina opt-level 0).

To reproduce the failure:

```bash
rm -rf out/fe
FE_SONA_OPT_LEVEL=1 forge test --ffi --offline -vvv --match-test test_diff_LeanIMT_computeRoot_smallValues_matchesSolidity
```

(Same failure for `FE_SONA_OPT_LEVEL=2`.)

### Minimal deterministic counterexample (LeanIMT)

Test: `test_diff_LeanIMT_computeRoot_smallValues_matchesSolidity`

Inputs:

- `leaf = 1`
- `index = 0`
- `siblingsLen = 2`
- `siblings[0..2) = [2, 3]` (rest zero)

Expected / observed results:

- Solidity root: `41284475257234908792700626306985277197652811982708732094152184811704779637787`
- Fe→Sonatina (`--opt-level 1|2`) root: `78338746147236970124700731725183845421594913511827187288591969170390706184117`
- Fe→Yul→solc root: matches Solidity

The incorrect Sonatina root in hex is:

- `0xad3228b676f7d3cd4284a5443f17f1962b36e491b30a40b2405849e597ba5fb5`

which equals:

```bash
cast keccak 0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
```

### SMT also fails at `--opt-level 1|2`

For example:

```bash
rm -rf out/fe
FE_SONA_OPT_LEVEL=1 forge test --ffi --offline -vvv --match-test testFuzz_SMT_computeRoot_matchesSolidity
```

fails on the first fuzz case (`runs: 0`), where Solidity and Fe→Yul match, but Fe→Sonatina returns the same incorrect root value above.

## Notes / suspected root cause

The Merkle hashing helper is implemented in Fe as:

- `fe-zkkit/zkkit_merkle/src/hash.fe`
  - `hash2_at(ptr, left, right)` does `mstore(left)`, `mstore(right)`, then `keccak256(ptr, 64)`.

The fact that the optimized Sonatina output returns `keccak256(0x00…00)` strongly suggests the memory writes that feed `keccak256(ptr, 64)` are being removed or otherwise not taking effect at `--opt-level 1|2` (e.g., an optimizer pass not modeling the `keccak256` memory read correctly).

Potential next debugging steps (in the Fe/Sonatina pipeline):

- Diff the Sonatina opt-level 0 vs 1 output around `hash2_at` and check that the two `mstore`s still exist and dominate the `keccak256`.
- Verify the optimizer treats `keccak256`/`SHA3` as **reading** `memory[ptr..ptr+len)`, so store-elimination can’t drop those writes.
