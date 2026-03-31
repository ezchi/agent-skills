---
name: cocotb-verilator-tests
description: |
  Generate and manage Cocotb Python testbenches for SystemVerilog RTL modules using Verilator simulator. Use when writing tests in Python for Verilog/SystemVerilog instead of native SystemVerilog testbenches.
  TRIGGER when: creating, modifying, or reviewing Cocotb Python test files (`test_*.py`), or user asks to write Python-based tests for SystemVerilog/Verilog modules, or mentions cocotb/Cocotb.
  DO NOT TRIGGER when: writing native SystemVerilog testbenches (`*_tb.sv`), editing RTL design files, or working on non-test Python code.
metadata:
  version: "1.0.0"
---

# Cocotb Verilator Tests Skill

This skill provides expertise for generating and managing Cocotb testbenches running on the Verilator simulator for SystemVerilog designs.

## Capabilities

- Create a new Cocotb test file (`test_*.py`) for a given SystemVerilog module
- Provide the boilerplate Makefile required to run Cocotb with Verilator
- Set up clock generators and reset logic in Python
- Establish best practices for asynchronous testing, timeouts, and driving signals with Cocotb

## When to Use This Skill

Activate this skill when users request:
- "Write a Cocotb test for..."
- "Create a Python testbench for my SystemVerilog module..."
- "Set up a Makefile for Cocotb and Verilator..."
- "Review my Cocotb testbench..."

## Procedures

### Test Plan (Mandatory — Before Any Implementation)

Before writing any test code, create and present a test plan for user approval:

1. **Understand the DUT Interface:** Identify clocks, resets, I/O signals, parameters, and operating modes.
2. **Identify major features to test** — list each functional block, operating mode, protocol, and boundary condition the DUT exposes.
3. **Define coverage points** — for each feature, specify what must be exercised: input ranges, edge cases, state transitions, error injection, corner cases, and cross-coverage between features.
4. **Build the test list** — a table with columns:

   | Test Name | Purpose | How to Test |
   |-----------|---------|-------------|
   | `test_reset_behavior` | Verify outputs go to known state on reset | Assert all outputs match reset values after reset assertion/deassertion |
   | … | … | … |

   - **Test Name**: descriptive `snake_case` name prefixed with `test_`.
   - **Purpose**: one sentence stating what the test proves.
   - **How to Test**: concrete stimulus and checking strategy (directed values, random sweep, scoreboard comparison, etc.).

5. **Present the plan to the user and wait for approval** before writing any test code.

### Generating a Cocotb Testbench

After the test plan is approved:

1. **Search for reusable components:** Check existing test files and `sim/cocotb/common/` for shared drivers, monitors, helper functions, and constants. Import and reuse them — do not duplicate.
3. **Generate the Test File:** Use `assets/templates/test_dut.py` as a baseline to create the Cocotb testbench.
   - Set up the clock generator (`cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())`).
   - Write a reset routine.
   - Implement asynchronous driver and monitor tasks.
   - Create tests using `@cocotb.test()` with timeouts to prevent hangs.
   - **Prefer self-documenting code over comments** — use descriptive function/variable names and named constants. Only add comments to explain *why* (e.g., protocol timing, workarounds), never *what* the code does.
   - **Reproducible randomness:** When tests use `random`, rely on the `random_seed` fixture from `conftest.py`. This seeds `random` from `COCOTB_RANDOM_SEED` (if set) or `time.time_ns()` (so values differ each run) and logs the seed for reproduction. Never call `random.seed()` directly in tests.
   - **Out-of-source build directory:** Use the `build_dir` fixture from `conftest.py` for all `runner.build()` and `runner.test()` calls. This places build artifacts under `<repo_root>/build/cocotb/<test_dir_name>/`, keeping the source tree clean and enabling parallel test execution (`pytest -n auto`). Never hardcode `sim_build` or place build artifacts inside the source directory.
3. **Generate the Makefile:** Provide `assets/templates/Makefile` to run the simulation, properly pointing to Verilator as the `SIM` engine.

### Reviewing a Cocotb Testbench

1. **Verify a test plan exists** — check that tests correspond to a documented plan with features, coverage points, and test list. Flag any tests that appear ad-hoc or lack traceability to a plan.
2. Verify naming conventions and structure against `references/cocotb-style-guide.md`.
2. **Check for code reuse** — flag duplicated helper functions, drivers, or constants that already exist in `sim/cocotb/common/` or other test files. Recommend extracting shared logic.
3. Ensure timeouts are specified for tests to avoid simulation hangs.
3. Ensure signals are driven using the appropriate mechanisms (`.value = ...`).
4. Look for potential race conditions or missing `await` statements.
5. Check for magic numbers — all meaningful literals must be named constants at the top of the file or in a shared module.
6. **Check for self-documenting code** — flag comments that explain *what* code does; ensure names and structure make intent obvious without comments.
7. **Check randomness seeding** — flag any direct `random.seed()` calls. Tests must use the `random_seed` fixture so seeds vary per run and are logged for reproducibility.
8. **Check build directory** — flag any hardcoded `sim_build` paths or in-source build directories. All runners must use the `build_dir` fixture to ensure out-of-source, per-test build isolation.

## Generating `compile_commands.json` for Verilator C++ Code

After running a cocotb test, Verilator leaves generated C++ and a Makefile
(`Vtop.mk`) in the out-of-source build directory
(`<repo_root>/build/cocotb/<test_dir_name>/`). Use
[bear](https://github.com/rizsotto/Bear) to capture compiler invocations and
produce `compile_commands.json` for clangd / LSP navigation.

```sh
# 1. Run the test once to populate the build directory
python -m pytest common/tests/async_fifo_bram_fwft/test_async_fifo_bram_fwft.py::test_async_fifo_bram_fwft_default

# 2. Force-rebuild under bear to capture compiler commands
bear -- make -C build/cocotb/test_async_fifo_bram_fwft -f Vtop.mk -B
```

`-B` forces make to rebuild all targets so bear can intercept the compiler
calls. The resulting `compile_commands.json` is written to the current
working directory.

## Available Resources

### Templates

- `assets/templates/test_dut.py` - Standard Cocotb testbench template
- `assets/templates/runner.py` - Pytest runner using cocotb_tools.runner

### References

- `references/cocotb-style-guide.md` - Guidelines and best practices for writing tests in Cocotb
