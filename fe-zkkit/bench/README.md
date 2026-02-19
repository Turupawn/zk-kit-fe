# fe-zkkit benchmarks (Foundry)

This is a self-contained Foundry project that helps evaluate **Fe-generated EVM code** against an equivalent **Solidity reference implementation**.

## What it does

- **Fuzzing**: proves the Fe contract and Solidity reference compute identical roots/updates for LeanIMT and SMT helpers.
- **Gas**: `forge test --gas-report` shows per-call gas for Fe vs Solidity variants on representative inputs.

## Prereqs

- Foundry (`forge`)
- A local `fe` binary at `../../../fe/target/debug/fe` (this repo layout)

## Run

From `fe-zkkit/bench`:

```bash
forge test --ffi --offline -vvv
forge test --ffi --offline --gas-report
```
