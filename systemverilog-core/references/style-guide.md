# SystemVerilog Style Guide

**Audience**: RTL designers and verification engineers working with **RTL**, **SVA**, **Verilator**, **C++**, and **Cocotb**.

**Goals**:

* Clean, readable, maintainable code ("Clean Code" principles).
* Predictable synthesis and simulation behavior.
* Minimal tool friction (especially Verilator).
* Non-intrusive, optional verification (SVA does not change design behavior).

---

## Core Principles (Clean Code Applied to SV)

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

## File & Directory Architecture (Scalable & Reusable)

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

## Naming Conventions (Clean Code Driven)

### General Rules

* Names must answer: **what**, not **how**.
* Avoid abbreviations unless industry-standard.
* Prefer longer names over comments.
* Use active high reset by default.
* Use synchronous reset by default.
* One definition per line.
* **`i_` and `o_` prefixes are strictly for module ports.** Do not use them for task/function arguments or internal local variables.
Good
```verilog
state_t state_curr;
state_t state_next;
```

Poor
```verilog
state_t state_curr, state_next;
```
### File Name

* **File names must match the entity name** defined inside.
* **Mandatory Suffixes**: Every file MUST use the appropriate suffix for its type to be valid.
  * Module: `<module_name>.sv`
  * Package: `<package_name>_pkg.sv`
  * Class: `<class_name>_ct.svh`
  * Interface: `<interface_name>_intf.sv`
  * Testbench: `<module_name>_tb.sv`

| Type      | Suffix   | Example             |
|-----------|----------|---------------------|
| Interface | _intf.sv | `axi_stream_intf.sv`|
| Package   | _pkg.sv  | `core_pkg.sv`       |
| Class     | _ct.svh  | `driver_ct.svh`     |
| Testbench | _tb.sv   | `fifo_tb.sv`        |


### Signals

| Type                          | Convention               | Example               |
|-------------------------------|--------------------------|-----------------------|
| Clock                         | `clk` (or `clk_<domain>`) | `i_clk`, `clk_core`   |
| Reset                         | `rst` or `reset`         | `i_rst`, `i_reset`    |
| Input                         | `i_<name>`           | `i_valid`             |
| Output                        | `o_<name>`           | `o_ready`             |
| Internal logic                | `<descriptive_name>` | `fifo_level`          |
| Current FSM state             | `state_curr`         | `state_curr`          |
| Next FSM state                | `state_next`         | `state_next`          |
| State name                    | `S_<name>`           | `S_IDLE`              |
| Combinational wire            | `<name>_c`           | `grant_c`             |
| Parameters                    | `P_<NAME>`           | `P_DEPTH`             |
| Localparams                   | `LP_<NAME>`          | `LP_ADDR_W`           |
| Interface                     | `<name_intf>`        | `mac_10g_rx_intf`     |
| Instance of interface         | `<name>_if`          | `rx_if`               |
| Instance of virtual interface | `<name>_vif`         | `rx_vif`              |
| Package                       | `<name>_pkg`         | `formatter_utils_pkg` |

**Note on Clock & Reset Ports**: When clock and reset are module ports, they **MUST** follow the `i_` or `o_` prefix rule (e.g., `i_clk`, `i_rst`, `i_reset`). Internal clock/reset signals or top-level signals may omit the prefix (e.g., `clk`, `rst`).


### 3.3 User-Defined Types & Enums

* All user-defined types (structs, enums, typedefs) must end with `_t`.
* Enum values must be uppercase: `THING_<VALUE>`.
* **Always use `packed` for structs and unions** unless explicitly required otherwise (e.g., for DPI-C interop or tool-specific constraints). Unpacked structs are not synthesizable in a portable way and cause Verilator warnings.
* **Always group related signals into a `typedef struct packed`**. If two or more signals travel together (e.g., valid + data, address + burst + size), define a struct to carry them. This reduces port clutter, prevents signal mismatches, and improves readability.

```systemverilog
typedef enum logic [1:0] {
  STATE_IDLE,
  STATE_BUSY,
  STATE_ERR
} state_t;

typedef struct packed {
  logic [31:0] data;
  logic        valid;
} packet_t;
```

#### Grouping Related Signals (Mandatory)

When multiple signals share a logical relationship, they **must** be grouped into a packed struct. Do not pass them as separate ports or declare them as loose signals.

Good — related signals grouped:
```systemverilog
typedef struct packed {
  logic [31:0] addr;
  logic [7:0]  len;
  logic [2:0]  size;
  logic        valid;
} axi_ar_req_t;

module read_controller (
  input  axi_ar_req_t i_ar_req,
  output logic        o_ar_ready
);
```

Poor — related signals declared separately:
```systemverilog
module read_controller (
  input  logic [31:0] i_ar_addr,
  input  logic [7:0]  i_ar_len,
  input  logic [2:0]  i_ar_size,
  input  logic        i_ar_valid,
  output logic        o_ar_ready
);
```

### 3.4 Modules & Instances

* Module: `snake_case`
* Instance: `u_<module>`

```systemverilog
arb_rr u_arb_rr (
  .i_clk (clk),
  .i_rst (rst)
);
```

---
    
## RTL Coding Rules (Synthesizable)


### Packed Arrays and Structs (Mandatory)

* **Always use packed arrays** (`logic [N-1:0]`) instead of unpacked arrays for ports and synthesizable signals. Unpacked arrays have limited tool support and are not portable across simulators and synthesis tools.
* **Always use `packed` qualifier on structs and unions** in RTL code. Packed structs map directly to bit vectors, making them safe for ports, assignments, and concatenation.
* Unpacked arrays are only permitted for memories/register files where tool-specific inference is required, or when explicitly requested.

Good:
```systemverilog
logic [3:0][7:0] data_bytes;  // packed array of 4 bytes

typedef struct packed {
  logic [15:0] payload;
  logic [3:0]  tag;
} tagged_data_t;
```

Poor:
```systemverilog
logic [7:0] data_bytes [0:3];  // unpacked — avoid unless memory inference needed

typedef struct {               // missing packed — not portable
  logic [15:0] payload;
  logic [3:0]  tag;
} tagged_data_t;
```

### Memory Block Addressing (Power-of-2 Allocation)

When a design contains multiple logical blocks mapped into a shared memory space, **all blocks must be allocated the same power-of-2 number of entries** (equal to or greater than the largest block's actual need). This guarantees the address is a simple concatenation of `{block_index, element_index}` with uniform field widths — no adders, multipliers, or variable-width decode needed.

* All blocks share the **same** power-of-2 entry count (pad unused entries in smaller blocks).
* The address is `{block_idx, elem_idx}` — top bits select the block, bottom bits select the element.
* Define `localparam` for block count and entries-per-block; derive address width with `$clog2`.

Good — uniform power-of-2 allocation, address by concatenation:
```systemverilog
// 4 blocks, each allocated 16 entries (2^4), even if some use fewer
localparam int unsigned LP_NUM_BLOCKS       = 4;
localparam int unsigned LP_ENTRIES_PER_BLOCK = 16;  // 2^4
localparam int unsigned LP_BLOCK_IDX_W      = $clog2(LP_NUM_BLOCKS);       // 2
localparam int unsigned LP_ELEM_IDX_W       = $clog2(LP_ENTRIES_PER_BLOCK); // 4
localparam int unsigned LP_ADDR_W           = LP_BLOCK_IDX_W + LP_ELEM_IDX_W; // 6

// Address = {block_idx, elem_idx}
// addr[5:4] = block index,  addr[3:0] = element index
logic [LP_BLOCK_IDX_W-1:0] block_idx;
logic [LP_ELEM_IDX_W-1:0]  elem_idx;
logic [LP_ADDR_W-1:0]      mem_addr;

assign mem_addr = {block_idx, elem_idx};
```

Poor — different sizes per block, requires adder for base offset:
```systemverilog
localparam int unsigned LP_BLOCK_A_ENTRIES = 12;  // not power of 2
localparam int unsigned LP_BLOCK_B_ENTRIES = 10;  // different size

// Requires: addr = base + idx, where base = 0, 12, 22...
// This needs an adder — avoid
assign block_b_addr = LP_BLOCK_A_ENTRIES + block_b_idx;  // adder in critical path
```

### Minimum Width Rules (Resource Efficiency)

Always follow the minimum width rules for SystemVerilog RTL design to optimize resources.
*   Match bit-widths exactly to the required range.
*   For standard Ethernet MTU (up to 4095 bytes), a 12-bit width (`[11:0]`) is sufficient.
*   Use custom types (e.g., `pkt_len_t`) to enforce consistent widths across the design.

### Finite State Machine (FSM) Style (Mandatory)

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

always_ff @(posedge clk) begin
  if (rst)
    state_curr <= S_IDLE;
  else
    state_curr <= state_next;
end

always_comb begin
  state_next = state_curr; // default

  unique case (state_curr)
    S_IDLE: if (i_start) state_next = S_BUSY;
    S_BUSY: if (i_done)  state_next = S_IDLE;
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

### Defaults Are Mandatory

* Every `always_comb` must fully assign all outputs.
* Use **early defaults**.

### No Implicit Nets

Every SystemVerilog file must start with `` `default_nettype none `` and end with `` `default_nettype wire `` to prevent implicit net declarations and ensure clean compilation units.

```systemverilog
`default_nettype none

module my_module (...);
  ...
endmodule

`default_nettype wire
```

### Avoid Gotchas

| Gotcha            | Rule                         |
|-------------------|------------------------------|
| Blocking in seq   | Use `<=` only                |
| Mixed comb/seq    | One block, one role          |
| X-optimism        | Explicit resets, assertions  |
| Width mismatch    | Explicit casts               |
| `logic` vs `wire` | Use `logic` unless tri-state |

---

## Parameters, Constants & Packages

### No Magic Numbers (Mandatory)

Every literal number that carries design meaning **must** be replaced with a named `localparam` or `parameter`. Bare literals (other than 0, 1, and simple bit-width specifiers) are not permitted in RTL.

* Use `localparam` for module-internal constants.
* Use `parameter` for values intended to be overridden at instantiation.
* Name must describe the **meaning**, not the value.
* Avoid `` `define`` except for include guards.

Good:
```systemverilog
localparam int unsigned LP_FIFO_DEPTH   = 64;
localparam int unsigned LP_ADDR_W       = $clog2(LP_FIFO_DEPTH);  // 6
localparam int unsigned LP_TIMEOUT_CC   = 256;  // clock cycles

logic [LP_ADDR_W-1:0] wr_ptr;

if (counter == LP_TIMEOUT_CC) ...
```

Poor:
```systemverilog
logic [5:0] wr_ptr;           // magic width — where does 6 come from?

if (counter == 256) ...        // magic number — what is 256?
```

### Package Organization (Structured & Reusable)

Packages must be **scoped by functional domain**, not dumped into a single monolithic package. Each package should be independently importable so that a module only pulls in what it needs.

#### Scoping Rules

* **One package per logical domain** — e.g., bus definitions, algorithm parameters, block-specific types.
* A package should contain **closely related** types, constants, and functions only.
* If a package grows beyond ~100 lines or spans unrelated concerns, split it.
* Packages **must not** depend on modules; they may depend on other packages.
* Keep the dependency chain shallow — avoid deep `import` chains across packages.

#### Naming Convention

* Package name: `<domain>_pkg` (e.g., `axi_pkg`, `dma_pkg`, `eth_common_pkg`).
* File name: `<domain>_pkg.sv` — must match the package name.

#### Recommended Package Hierarchy

```
rtl/
├── common/
│   ├── types_pkg.sv          # Project-wide primitive typedefs (data_t, addr_t)
│   └── math_pkg.sv           # Shared utility functions (max, clog2_ceil)
├── bus/
│   ├── axi_pkg.sv            # AXI types, constants, enums
│   └── axi_stream_pkg.sv     # AXI-Stream specific types
├── blocks/
│   ├── dma_pkg.sv            # DMA-specific types, register map constants
│   └── eth_rx_pkg.sv         # Ethernet RX block types and parameters
```

#### Structure Within a Package

Order contents consistently: imports first, then localparams, then typedefs, then functions.

```systemverilog
package dma_pkg;

  // ── Imports ──
  import types_pkg::addr_t;
  import types_pkg::data_t;

  // ── Constants ──
  localparam int unsigned LP_NUM_CHANNELS   = 4;
  localparam int unsigned LP_MAX_BURST_LEN  = 256;
  localparam int unsigned LP_DESC_ENTRIES    = 16;  // power of 2

  // ── Types ──
  typedef enum logic [1:0] {
    DMA_IDLE,
    DMA_READ,
    DMA_WRITE,
    DMA_DONE
  } dma_state_t;

  typedef struct packed {
    addr_t                  src_addr;
    addr_t                  dst_addr;
    logic [$clog2(LP_MAX_BURST_LEN)-1:0] burst_len;
  } dma_desc_t;

  // ── Functions ──
  function automatic logic is_valid_channel(input logic [$clog2(LP_NUM_CHANNELS)-1:0] ch);
    return ch < LP_NUM_CHANNELS;
  endfunction

endpackage
```

#### Import Rules

* Prefer **explicit imports** (`import pkg::symbol`) over wildcard (`import pkg::*`) to keep dependencies visible.
* Wildcard import is acceptable inside a testbench or when the package is small and tightly coupled.

Good:
```systemverilog
import dma_pkg::dma_desc_t;
import dma_pkg::LP_NUM_CHANNELS;
```

Acceptable in testbenches:
```systemverilog
import dma_pkg::*;
```

---

## SystemVerilog Classes

Classes are primarily used for verification components (agents, scoreboards, etc.).

### Rules

* **One class per file**.
* Class names must end with `_ct`.
* Class definition must be in a file named `<class_name>.svh` (e.g., `my_driver_ct.svh`).
* Class header files (`*.svh`) **must only** be included inside a SystemVerilog package (`*_pkg.sv`).
* **All header files (`*.svh`) must be wrapped in `ifndef` guards** to prevent multiple inclusion.

```systemverilog
// my_driver_ct.svh
`ifndef MY_DRIVER_CT_SVH
`define MY_DRIVER_CT_SVH

class my_driver_ct;
  // ...
endclass

`endif // MY_DRIVER_CT_SVH
```

```systemverilog
package my_component_pkg;
  // Included classes
  `include "driver_ct.svh"
  `include "monitor_ct.svh"
  `include "agent_ct.svh"
endpackage
```

---

## Assertions & SVA (Non-Intrusive by Design)

### Philosophy

* Assertions must **observe only**.
* Never drive signals.
* Must be removable without functional impact.

### Placement Strategy

1. **Preferred**: Separate `_sva.sv` file
2. Bound using `bind`

```systemverilog
bind fifo_async fifo_async_sva u_fifo_async_sva (.*);
```

### Naming

| Item      | Convention        |
|-----------|-------------------|
| Property  | `p_<description>` |
| Assertion | `a_<description>` |
| Cover     | `c_<description>` |

### Clocking Blocks

```systemverilog
clocking cb @(posedge clk_core);
  input rst_core;
  input i_valid, o_ready;
endclocking
```

### Example Assertion

```systemverilog
property p_valid_eventually_ready;
  disable iff (!rst_core)
  valid |-> ##[1:$] ready;
endproperty

a_valid_eventually_ready: assert property (p_valid_eventually_ready);
```

### Verilator Notes

* Enable with `--assert`.
* Avoid complex temporal operators with unbounded ranges in hot paths.

---

## Cocotb & Verilator Compatibility

### RTL Rules for Cocotb

* Ports must be **2-state clean** when possible.
* Avoid force/release semantics.
* Use simple packed arrays instead of unpacked for ports.

### Naming for Python Access

```python
dut.i_valid.value = 1
await RisingEdge(dut.clk_core)
```

Avoid escaped identifiers or hierarchical hacks.

### DPI & C++ Interop

* Keep DPI functions in dedicated files.
* No side-effects in DPI used by assertions.

---

## Commenting & Documentation

* Comment **why**, not **what**.
* Header per file:

```systemverilog
// Module: fifo_async
// Purpose: Dual-clock FIFO with gray-coded pointers
// Notes: Optimized for Verilator + Cocotb
```

---

## Linting & Self-Checks

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
- File names must match the entity name (module, package, class, interface)
- One class per file, named <class_name>.svh (e.g., my_driver_ct.svh)
- Class names must end with _ct
- All *.svh files must be wrapped in `ifndef guards
- Classes must be included ONLY in SystemVerilog packages (*_pkg.sv)
- All user-defined types (structs, enums, typedefs) must end with _t
- Explicit clock/reset naming (clk, rst, reset)
- Input/Output naming (i_*, o_*) for module ports only (including clocks and resets)
- FSM state naming: state_curr / state_next
- always_ff / always_comb only, one intent per block
- Early default assignments in all combinational logic
- No implicit nets (`default_nettype none`)
- Non-intrusive SVA in separate *_sva.sv files using bind
- Assertions observe only, never drive signals
- Verilator + Cocotb compatible (no exotic SV features)
- Always use packed arrays and packed structs (no unpacked unless explicitly required)
- Group related signals into typedef struct packed — never pass them as separate loose ports
- Multi-block memory: power-of-2 entries per block, address = {block_idx, elem_idx} — no multiply
- No magic numbers — use named localparam/parameter for every meaningful literal
- Packages scoped by functional domain (axi_pkg, dma_pkg) — no monolithic dump packages
- Prefer explicit imports (import pkg::symbol) over wildcard in RTL
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
- Minimum width for counters and registers (no over-sizing)

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
