---
name: verilator-simflow
description: |
  Provides end-to-end simulation workflows for Verilator projects, including
  single test execution, regression runs, waveform dumping, and results
  reporting integrated with CMake build systems and testbenches.
  TRIGGER when: user asks to run a simulation, execute a test, view waveforms, run regression, or debug simulation failures in a Verilator project.
  DO NOT TRIGGER when: only writing or reviewing RTL/testbench code without running simulations, or editing build files.
metadata:
  version: "1.0.0"
  depends_on:
    - verilator-cmake
    - systemverilog-tests
---

# Verilator Simulation Flow Skill

## Purpose

This skill defines procedures for running Verilator simulations:

- single test execution
- batch regression
- enabling/disabling waveform tracing
- managing logs and outputs
- collecting pass/fail status

It may use CMake or direct Verilator invocation depending on user context.

Generated scripts and configurations must be self-documenting — use descriptive variable/function names; only add comments to explain *why* (e.g., tool quirks, environment constraints), never *what* the code does.

**Reuse first:** Before writing new scripts or configs, search for existing simulation scripts, CTest configurations, and helper functions in the project. Extend them rather than creating parallel infrastructure. Factor repeated patterns (build-run-check) into shared shell functions or CMake macros.
**Minimize edits to existing code:** When modifying existing scripts, configs, or test flow files, keep changes scoped to what is necessary for the task. Avoid unrelated cleanup or restructuring unless required.

---

## Capabilities

This skill can:

- run one simulation binary with arguments
- enable VCD/FST waveform dumping
- generate shell scripts for repeated use
- organize build / run directories
- create simple regression infrastructure
- analyze test output for pass/fail tokens

---

## When to activate

Activate when prompt includes:

- “run Verilator”
- “simulate”
- “regression”
- “waveform”
- “run all tests”
- “collect pass/fail”
- “simulation script”

---

## Procedure: Run a Single Simulation

When executing a single simulation:

1. Identify simulation binary location
2. Create output/run directory
3. Apply any user-provided command-line arguments and reuse existing regression configuration when present
4. Enable/disable waveform dumping per user request
5. Capture stdout/stderr logs
6. Grep for `TEST PASS` or `TEST FAIL`
7. Report structured result

---

## Procedure: Regression Run

1. Identify list of tests or binaries
2. For each test:
   - run simulation
   - store logs
   - create waveform only on failure
3. Summarize:
   - total
   - passed
   - failed
4. Write report file

---

## Returned Outputs

The skill may return:

- shell scripts
- cmake ctest config
- commands to run
- result summaries

---

## References Provided

See folder `references/` for:

- simulation workflow guidance
- regression best practices
- waveform dumping instructions
