---
name: systemverilog-tests
description: |
  Provides capabilities for generating, refactoring, and reviewing
  SystemVerilog testbenches, including self-checking tests compatible
  with Verilator simulation workflows.
  TRIGGER when: creating, modifying, or reviewing SystemVerilog testbench files (`*_tb.sv`), or user asks to write SV-based tests, self-checking testbenches, or stimulus drivers in SystemVerilog.
  DO NOT TRIGGER when: writing Python/Cocotb tests, editing RTL design files, or working on build infrastructure.
metadata:
  version: "1.0.0"
  depends_on:
    - systemverilog-core
---

# SystemVerilog Tests Skill

## Purpose

This skill generates and improves SystemVerilog testbenches for RTL
design modules. It focuses on:

- self-checking testbench generation
- Verilator compatible simulation constructs
- stimulus and response checking
- assertions and basic coverage
- reusable driver and monitor templates

It does not generate RTL modules (see `systemverilog-core` skill).

---

## Capabilities

- Create new testbench for a given module
- Add clock and reset generators
- Generate random or directed stimulus
- Create checkers and scoreboards
- Insert SystemVerilog assertions
- Review an existing testbench
- Refactor to use best practices

---

## When the skill should be activated

Activate this skill when prompts mention:

- “SystemVerilog testbench”
- “write TB for …”
- “Verilator test”
- “self-checking testbench”
- “generate stimulus and checks”
- “review my testbench”

---

## Test Plan Procedure (Mandatory — Before Any Implementation)

Before writing any testbench code, create and present a test plan for user approval:

1. **Parse DUT interface and parameters** — identify clocks, resets, I/O ports, parameters, and operating modes.
2. **Identify major features to test** — list each functional block, operating mode, protocol, and boundary condition the DUT exposes.
3. **Define coverage points** — for each feature, specify what must be exercised: input ranges, edge cases, state transitions, error injection, corner cases, and cross-coverage between features.
4. **Build the test list** — a table with columns:

   | Test Name | Purpose | How to Test |
   |-----------|---------|-------------|
   | `test_reset_behavior` | Verify outputs go to known state on reset | Assert all outputs match reset values after reset assertion/deassertion |
   | … | … | … |

   - **Test Name**: descriptive `snake_case` name prefixed with `test_`.
   - **Purpose**: one sentence stating what the test proves.
   - **How to Test**: concrete stimulus and checking strategy (directed values, random sweep, assertion type, scoreboard comparison, etc.).

5. **Present the plan to the user and wait for approval** before writing any testbench code.

---

## Testbench Generation Procedure

After the test plan is approved, generate the testbench:

1. Parse DUT interface and parameters
2. **Search existing testbenches and `verif/vip/`** for reusable drivers, monitors, scoreboards, and helper tasks. Import and reuse them instead of writing from scratch.
3. Instantiate DUT using `systemverilog-core` style
4. Create:
   - clock generator
   - reset generator
   - **watchdog/timeout process (mandatory to prevent simulation hangs)**
   - **`delay_cc(int n)` task for consistent cycle-based delays (if not using an interface).**
4. Build stimulus process:
   - **Drive and sample data ONLY on `posedge clk` unless explicitly requested otherwise.**
   - **Use `delay_cc(n)` for all clock-cycle delays; prefer the task defined within the interface (e.g., `vif.delay_cc(n)`) over a local testbench task.**
5. Build checkers or assertions
6. **Prefer self-documenting code over comments** — use descriptive task/function names, meaningful signal names, and named constants. Only add comments to explain *why* (e.g., protocol quirks, timing constraints), never *what* the code does.
7. Add `$display` summary result
7. **Run `delay_cc(2)` before `$finish` to ensure waveform clarity.**
8. Ensure Verilator compatibility according to `references/verilator-compatibility.md`
9. Return a complete compilable testbench

---

## Testbench Review Procedure

1. **Verify a test plan exists** — check that tests correspond to a documented plan with features, coverage points, and test list. Flag any tests that appear ad-hoc or lack traceability to a plan.
2. Check naming conventions from `test-style-guide.md`
2. **Check for code reuse** — flag duplicated drivers, monitors, or helper tasks that already exist in `verif/vip/` or other testbenches. Recommend extracting shared logic into reusable components.
3. **Check for self-documenting code** — flag comments that explain *what* code does (rename or restructure instead); keep only *why* comments.
4. **Verify a watchdog/timeout is present to prevent infinite simulation hangs.**
3. **Check for `negedge clk` usage; flag if not explicitly requested.**
4. **Ensure `delay_cc(n)` is used for all cycle-based delays instead of `@(posedge clk)`.**
5. **If an interface with a clock is used, verify it defines a `delay_cc(int n)` task.**
6. **Ensure `delay_cc(2)` is run after the last stimulus/check before `$finish`.**
7. Ensure no unsynthesizable constructs inside DUT
5. Remove delays inside assertions if needed
6. Improve stimulus readability
7. Add missing reset sequencing
8. Suggest coverage or assertions

---

## References Provided

- Testbench style guide
- Verilator compatibility checklist
- Example testbenches under assets/examples

---

## Templates Provided

- Basic testbench
- Clock/reset drivers
- Self-checking testbench
- AXI-Lite bus master testbench
