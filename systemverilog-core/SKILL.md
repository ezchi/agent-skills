---
name: systemverilog-core
description: |
  Core skill for generating, refactoring, and reviewing SystemVerilog RTL
  using templates and a structured style guide.
metadata:
  version: "1.0.0"
---

# SystemVerilog Core Skill

## What this skill does

This skill helps with:

- Generating SystemVerilog RTL modules using templates.
- Applying a consistent coding style.
- Reviewing existing RTL for design and style issues.
- Refactoring code to improve readability and correctness.

## When to use

Use this skill for any prompt involving:

- SystemVerilog code generation
- Style-compliant RTL creation
- Reviewing or refactoring modules
- Building common interfaces or templates

Example triggers:

- “Generate a SystemVerilog module for a FIFO”
- “Refactor this RTL to follow our style guide”
- “Review this design for reset and synthesizability issues”

---

## Generate SystemVerilog Code

### Inputs
- A functional description or specification
- Interface information (ports, widths, clocks, resets)
- Optional style constraints

### Steps

1. Identify top-level entity name, inputs, outputs, and parameters.
2. Select an appropriate template from `assets/templates/`.
3. Apply naming and structural rules from the style guide
   in `references/style-guide.md`.
4. Insert interface declarations and logic placeholders.
5. Add comments and documentation stubs.
6. Return a complete `.sv` file.

---

## Review / Refactor Existing Code

### Inputs
- A SystemVerilog file or snippet

### Steps

1. Parse the code for modules, interfaces, and logic blocks.
2. Check naming conventions.
3. Verify sequential and combinational rules.
4. Identify and correct anti-patterns (inferred latches, blocking vs non-blocking).
5. Suggest improvements, including interface templates where appropriate.
6. Output a cleaned version or review notes.

---

## Style Guide Reference

Use the rules in `references/style-guide.md` for all RTL generation
and review tasks.

---

## Templates

Available templates in `assets/templates/`:

- `module_basic.sv` – starting point for simple modules  
- `fsm_template.sv` – finite state machine pattern  
- `interface_template.sv` – for logic interfaces

---

## Examples

See `assets/examples/` for example RTL consuming these patterns.

