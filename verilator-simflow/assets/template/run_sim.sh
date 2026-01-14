#!/usr/bin/env bash
set -e

BIN=./build/{{exe_name}}
OUT=sim/{{test_name}}

mkdir -p $OUT

$BIN {{extra_args}} > $OUT/run.log 2>&1

grep "TEST PASS" $OUT/run.log && echo "PASS" || echo "FAIL"
