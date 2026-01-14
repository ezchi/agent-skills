---
name: systemverilog-tests
description: |
  Provides capabilities for generating, refactoring, and reviewing
  SystemVerilog testbenches, including self-checking tests compatible
  with Verilator simulation workflows.
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
4. Build stimulus process
5. Build checkers or assertions
6. Add `$display` summary result
7. Ensure Verilator compatibility according to `references/verilator-compatibility.md`
8. Return a complete compilable testbench

---

## Testbench Review Procedure

1. Check naming conventions from `test-style-guide.md`
2. Ensure no unsynthesizable constructs inside DUT
3. Remove delays inside assertions if needed
4. Improve stimulus readability
5. Add missing reset sequencing
6. Suggest coverage or assertions

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
