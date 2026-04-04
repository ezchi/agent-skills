#!/usr/bin/env bash
set -e

TESTS=(
  {{test_list}}
)

PASS=0
FAIL=0

for t in "${TESTS[@]}"; do
  ./run_sim.sh "$t" && PASS=$((PASS+1)) || FAIL=$((FAIL+1))
done

echo "TOTAL: $((PASS+FAIL)) PASS: $PASS FAIL: $FAIL"
