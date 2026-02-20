#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

FUZZ_RUNS="${FUZZ_RUNS:-10000}"
SEEDS="${SEEDS:-1 2 3 4 5}"
EXHAUSTIVE="${EXHAUSTIVE:-0}"
MATCH_TEST="${MATCH_TEST:-"(testFuzz_|test_diff_|testExhaustive_)"}"

for opt in 0 1 2; do
  for seed in $SEEDS; do
    echo "== FE_SONA_OPT_LEVEL=$opt FUZZ_RUNS=$FUZZ_RUNS FUZZ_SEED=$seed EXHAUSTIVE=$EXHAUSTIVE =="
    rm -rf out/fe
    FE_SONA_OPT_LEVEL="$opt" FE_ZKKIT_EXHAUSTIVE="$EXHAUSTIVE" \
      forge test --ffi --offline -vvv --fail-fast \
      --match-test "$MATCH_TEST" \
      --fuzz-runs "$FUZZ_RUNS" \
      --fuzz-seed "$seed"
  done
done

