# SystemVerilog Style Guide

**Audience**: RTL designers and verification engineers working with **RTL**, **SVA**, **Verilator**, **C++**, and **Cocotb**.

**Goals**:

* Clean, readable, maintainable code ("Clean Code" principles).
* Predictable synthesis and simulation behavior.
* Minimal tool friction (especially Verilator).
* Non-intrusive, optional verification (SVA does not change design behavior).

---

## 1. Core Principles (Clean Code Applied to SV)

1. **Clarity over cleverness**

   * Prefer explicit logic over compact but opaque constructs.
   * Avoid implicit sizing, implicit nets, and ambiguous expressions.

2. **Single responsibility**

   * One module = one well-defined function.
   * One always block = one intent (seq or comb, never both).
   * No more than 4 arguments for a function or task, use struct or class to group arguments.

3. **Local reasoning**

   * A reader should understand behavior without searching other files.
   * Avoid hidden dependencies via `include or global macros.

4. **Avoid Duplication**

   * Reuse code as possible as it can to avoid duplication.
   * Abstract common functionality for reuse.
   
5. **Fail fast**

   * Assertions for illegal states.
   * Defensive default assignments.

---

## 2. File & Directory Architecture (Scalable & Reusable)

The directory structure must support **multiple modules**, **unit tests**, **integration tests**, and **reuse** of both RTL and verification components.

```
repo/
├── rtl/
│   ├── core/
│   │   ├── fifo_async.sv
│   │   ├── arb_rr.sv
│   │   └── core_pkg.sv
│   ├── interfaces/
│   │   └── axi_stream_if.sv
│   ├── blocks/
│   │   └── dma_engine.sv
│   └── common/
│       ├── pkg_types.sv
│       ├── pkg_params.sv
│       └── synchronizers.sv
│
├── verif/
│   ├── sva/
│   │   ├── fifo_async_sva.sv
│   │   └── arb_rr_sva.sv
│   ├── tb_unit/
│   │   ├── tb_fifo_async.sv
│   │   └── tb_arb_rr.sv
│   ├── tb_integration/
│   │   └── tb_dma_subsystem.sv
│   └── vip/
│       ├── axi_stream_agent.sv
│       └── scoreboards.sv
│
├── sim/
│   ├── verilator/
│   │   └── verilator.mk
│   └── cocotb/
│       ├── tests/
│       │   ├── test_fifo_async.py
│       │   └── test_dma_subsystem.py
│       └── common/
│           └── drivers.py
│
├── scripts/
│   ├── lint_sv.sh
│   └── check_style.py
│
└── docs/
│   └── design_notes.md
```

### Rules

* **One RTL module per file**.
* RTL must not depend on verification code.
* Verification components (agents, scoreboards) must be reusable across testbenches.
* Unit tests target *one module*; integration tests target *multiple modules*.

---

## 3. Naming Conventions (Clean Code Driven)

### 3.1 General Rules

* Names must answer: **what**, not **how**.
* Avoid abbreviations unless industry-standard.
* Prefer longer names over comments.
* Use active high reset by default.
* Use synchronous reset by default.
* One definition per line.
Good
```verilog
state_t state_curr;
state_t state_next;
```

Poor
```verilog
state_t state_curr, state_next;
```

### 3.2 Signals

| Type                          | Convention           | Example               |
|-------------------------------|----------------------|-----------------------|
| Clock                         | `clk_<domain>`       | `clk_core`            |
| Reset (active-high)           | `rst_<domain>`       | `rst_dbg`             |
| Input                         | `i<name>`            | `iValid`              |
| Output                        | `o<name>`            | `oReady`              |
| Internal logic                | `<descriptive_name>` | `fifo_level`          |
| Current FSM state             | `state_curr`         | `state_curr`          |
| Next FSM state                | `state_next`         | `state_next`          |
| State name                    | `S_<name>`           | `S_IDLE`              |
| Combinational wire            | `<name>_c`           | `grant_c`             |
| Parameters                    | `P_<NAME>`           | `P_DEPTH`             |
| Localparams                   | `LP_<NAME>`          | `LP_ADDR_W`           |
| Interface                     | `<name>_intf`        | `mac_10g_rx_intf`     |
| Instance of interface         | `<name>_if`          | `rx_if`               |
| Instance of virtual interface | `<name>_vif`         | `rx_vif`              |
| Package                       | `<name>_pkg`         | `formatter_utils_pkg` |


### 3.3 User-Defined Types & Enums

```systemverilog
typedef enum logic [1:0] {
  S_IDLE,
  S_BUSY,
  S_ERR
} state_t;
```

* Enum names: `<thing>_e`
* Enum values: `THING_<VALUE>`

### 3.4 Modules & Instances

* Module: `snake_case`
* Instance: `u_<module>`

```systemverilog
arb_rr u_arb_rr (
  .clk_core (clk_core),
  .rst_core (rst_core)
);
```

---

## 4. RTL Coding Rules (Synthesizable)

### 4.1 Finite State Machine (FSM) Style (Mandatory)

FSMs must follow a strict, reviewable structure.

#### Naming

* Current state: `state_curr`
* Next state: `state_next`
* State type: `<fsm_name>_state_t`

```systemverilog
typedef enum logic [1:0] {
  S_IDLE,
  S_BUSY,
  S_ERR
} foo_state_t;
```

#### Structure

* Exactly **two always blocks**:

  1. Sequential state register
  2. Combinational next-state logic
* No output logic inside the state register block

```systemverilog
foo_state_t state_curr;
foo_state_t state_next;

always_ff @(posedge clk_core) begin
  if (rst_core)
    state_curr <= S_IDLE;
  else
    state_curr <= state_next;
end

always_comb begin
  state_next = state_curr; // default

  unique case (state_curr)
    S_IDLE: if (i_start) state_next = S_BUSY;
    S_BUSY: if (done)    state_next = S_IDLE;
    S_ERR:               state_next = S_IDLE;
    default:             state_next = S_IDLE;
  endcase
end
```

#### Rules

* Default assignment to `state_next` is mandatory
* `unique case` or `priority case` required
* All enum values must be covered
* No combinational outputs driven directly from `state_curr`

### 4.2 Defaults Are Mandatory

* Every `always_comb` must fully assign all outputs.
* Use **early defaults**.

### 4.3 No Implicit Nets

```systemverilog
`default_nettype none
```

Restore at EOF if needed.

### 4.4 Avoid Gotchas

| Gotcha            | Rule                         |
|-------------------|------------------------------|
| Blocking in seq   | Use `<=` only                |
| Mixed comb/seq    | One block, one role          |
| X-optimism        | Explicit resets, assertions  |
| Width mismatch    | Explicit casts               |
| `logic` vs `wire` | Use `logic` unless tri-state |

---

## 5. Parameters & Packages

* Put shared types/constants in packages.
* Avoid `define except for guards.

```systemverilog
package pkg_types;
  typedef logic [31:0] data_t;
endpackage
```

---

## 6. Assertions & SVA (Non-Intrusive by Design)

### 6.1 Philosophy

* Assertions must **observe only**.
* Never drive signals.
* Must be removable without functional impact.

### 6.2 Placement Strategy

1. **Preferred**: Separate `_sva.sv` file
2. Bound using `bind`

```systemverilog
bind fifo_async fifo_async_sva u_fifo_async_sva (.*);
```

### 6.3 Naming

| Item      | Convention        |
|-----------|-------------------|
| Property  | `p_<description>` |
| Assertion | `a_<description>` |
| Cover     | `c_<description>` |

### 6.4 Clocking Blocks

```systemverilog
clocking cb @(posedge clk_core);
  input rst_core;
  input i_valid, o_ready;
endclocking
```

### 6.5 Example Assertion

```systemverilog
property p_valid_eventually_ready;
  disable iff (!rst_core)
  valid |-> ##[1:$] ready;
endproperty

a_valid_eventually_ready: assert property (p_valid_eventually_ready);
```

### 6.6 Verilator Notes

* Enable with `--assert`.
* Avoid complex temporal operators with unbounded ranges in hot paths.

---

## 7. Cocotb & Verilator Compatibility

### 7.1 RTL Rules for Cocotb

* Ports must be **2-state clean** when possible.
* Avoid force/release semantics.
* Use simple packed arrays instead of unpacked for ports.

### 7.2 Naming for Python Access

```python
dut.i_valid.value = 1
await RisingEdge(dut.clk_core)
```

Avoid escaped identifiers or hierarchical hacks.

### 7.3 DPI & C++ Interop

* Keep DPI functions in dedicated files.
* No side-effects in DPI used by assertions.

---

## 8. Commenting & Documentation

* Comment **why**, not **what**.
* Header per file:

```systemverilog
// Module: fifo_async
// Purpose: Dual-clock FIFO with gray-coded pointers
// Notes: Optimized for Verilator + Cocotb
```

---

## 9. Linting & Self-Checks

### Mandatory Checks

* No inferred latches
* No unused signals
* No implicit nets
* All enums fully covered

---

## 10. Synthesis

- No simulation-only constructs in RTL outputs
- Verilator lint pass required

## 11. Gemini AI Context (Paste into System Prompt)

```
You are generating SystemVerilog code following a strict clean-code RTL & verification style:
- Scalable repo architecture with reusable RTL and verification modules
- One module per file, snake_case module names
- Explicit clock/reset naming (clk_*, rst_*)
- FSM state naming: state_curr / state_next
- User-defined types must end with _t
- always_ff / always_comb only, one intent per block
- Early default assignments in all combinational logic
- No implicit nets (`default_nettype none`)
- Non-intrusive SVA in separate *_sva.sv files using bind
- Assertions observe only, never drive signals
- Verilator + Cocotb compatible (no exotic SV features)
- Prefer clarity and maintainability over compactness
```

---

## 12. Slash Commands (AI-Assisted Review – Detailed & Reference-Based)

These slash commands are intended to be used with Gemini or other LLM-based code reviewers.
Each command defines **scope**, **checks**, and **expected output**.

### `/sv-style-check`
**Scope**: File or module

Checks:
- Naming conventions (signals, modules, instances)
- `state_curr` / `state_next` usage for FSMs
- `_t` suffix for all user-defined types
- One module per file
- Consistent indentation and alignment

Output:
- List of violations with line numbers
- Suggested renames or refactors

---

### `/sv-synth-check`
**Scope**: RTL only

Checks:
- Non-synthesizable constructs (`initial`, delays, force/release)
- Correct usage of `always_ff` / `always_comb`
- No inferred latches
- Reset completeness for sequential logic
- No combinational feedback loops

Output:
- Synthesis risk summary
- Severity-ranked issues

---

### `/sv-sva-check`
**Scope**: Assertion files (`*_sva.sv`)

Checks:
- Assertions are observation-only
- No signal driving or side effects
- Proper `disable iff` reset usage
- Bind safety (no hierarchical references)
- Property / assertion naming (`p_`, `a_`, `c_`)

Output:
- Intrusiveness risk assessment
- Assertion quality score

---

### `/sv-verilator-check`
**Scope**: RTL + SVA

Checks:
- Unsupported SV features (classes, mailboxes, dynamic arrays)
- Assertion compatibility with `--assert`
- Performance risks (unbounded temporal ranges in hot clocks)
- DPI isolation

Output:
- Verilator compatibility report
- Performance warnings

---

### `/sv-clean-code`
**Scope**: RTL + verification

Checks:
- Long or overloaded always blocks
- Ambiguous or abbreviated names
- Hidden coupling via packages or macros
- Comment quality (why vs what)

Output:
- Readability and maintainability score
- Refactoring suggestions

---

## 13. Recommended Defaults

- `timescale 1ns/1ps
- `default_nettype none
- Explicit resets in all sequential logic

---

**This guide is intended to be enforceable, reviewable, and automation-friendly.**
