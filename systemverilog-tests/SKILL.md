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

## Testbench Generation Procedure

When generating a testbench:

1. Parse DUT interface and parameters
2. Instantiate DUT using `systemverilog-core` style
3. Create:
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

1. Check naming conventions from `test-style-guide.md`
2. **Check for self-documenting code** — flag comments that explain *what* code does (rename or restructure instead); keep only *why* comments.
3. **Verify a watchdog/timeout is present to prevent infinite simulation hangs.**
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
