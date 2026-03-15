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

### Generating a Cocotb Testbench

1. **Understand the DUT Interface:** Identify clocks, resets, and I/O signals of the SystemVerilog module.
2. **Generate the Test File:** Use `assets/templates/test_dut.py` as a baseline to create the Cocotb testbench.
   - Set up the clock generator (`cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())`).
   - Write a reset routine.
   - Implement asynchronous driver and monitor tasks.
   - Create tests using `@cocotb.test()` with timeouts to prevent hangs.
3. **Generate the Makefile:** Provide `assets/templates/Makefile` to run the simulation, properly pointing to Verilator as the `SIM` engine.

### Reviewing a Cocotb Testbench

1. Verify naming conventions and structure against `references/cocotb-style-guide.md`.
2. Ensure timeouts are specified for tests to avoid simulation hangs.
3. Ensure signals are driven using the appropriate mechanisms (`.value = ...`).
4. Look for potential race conditions or missing `await` statements.
5. Check for magic numbers — all meaningful literals must be named constants at the top of the file or in a shared module.

## Available Resources

### Templates

- `assets/templates/test_dut.py` - Standard Cocotb testbench template
- `assets/templates/runner.py` - Pytest runner using cocotb_tools.runner

### References

- `references/cocotb-style-guide.md` - Guidelines and best practices for writing tests in Cocotb
