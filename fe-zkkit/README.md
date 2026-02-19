# fe-zkkit (in-repo prototype)

This folder contains a small **Fe v2 workspace** that implements a few ZK‑Kit-style primitives in Fe (starting with Merkle proof helpers).

## Layout

- `fe.toml`: workspace root
- `zkkit_merkle/`: Merkle helpers (Keccak `hash2`, LeanIMT proof root reconstruction, Sparse Merkle proof root reconstruction)
- `fe_zkkit/`: umbrella ingot that re-exports the workspace members

## Quick checks

From the `zk-kit` repo root:

```bash
../fe/target/debug/fe check fe-zkkit
```

Or check a single ingot:

```bash
../fe/target/debug/fe check fe-zkkit/zkkit_merkle
../fe/target/debug/fe check fe-zkkit/fe_zkkit
```

## Build the example contract

`zkkit_merkle` includes an EVM-facing helper contract, `ZkKitMerkleBench`, that exposes a small ABI for computing/updating Merkle roots from calldata (handy for quick integration tests).

```bash
../fe/target/debug/fe build --contract ZkKitMerkleBench fe-zkkit/zkkit_merkle --out-dir /tmp/fe-zkkit-out
```

## Benchmarks (Foundry)

See `fe-zkkit/bench/README.md`.
