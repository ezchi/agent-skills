---
name: Verilator 
description: Specialized knowledge for configuring, compiling, and writing SystemVerilog compatible with Verilator.
---

# Verilator Development Expert

## Description
Specialized knowledge for configuring, compiling, and writing SystemVerilog compatible with Verilator. This skill focuses on avoiding C++ conversion pitfalls, ensuring correct build ordering, and using robust coding patterns.

## 1. CMake & Build Configuration
*   **Dependency Ordering is Critical:** Unlike some commercial simulators, Verilator requires source files to be listed in dependency order.
    *   *Correct:* `SOURCES my_package.sv my_module.sv testbench.sv` (Package defined before use).
    *   *Incorrect:* `SOURCES testbench.sv my_package.sv` (Will cause "Reference to package before declaration" errors).
*   **Integration Pattern:**
    *   Use `find_package(verilator REQUIRED)`.
    *   Use the `verilate()` CMake macro (if available in the environment) to handle C++ generation and linking automatically.
    *   Enable tracing (`--trace`) and automatic main generation (`--main`) for efficient testing of pure SV modules.

## 2. SystemVerilog Coding Best Practices
*   **Dynamic Arrays & Queues:**
    *   **No Variable Slicing:** Verilator does *not* support variable-indexed slicing on dynamic arrays (e.g., `dyn_arr[i +: 4]` is illegal).
    *   **Workaround:** Copy the desired chunk into a fixed-size temporary array or scalar inside a loop, then process that temporary variable.
*   **Streaming Operators (`<<`, `>>`):**
    *   **Avoid Nested Streaming on Queues:** Complex streaming assignments between dynamic arrays of different types (e.g., byte queue to word queue) often fail C++ conversion (`VL_COPY_Q` type mismatch).
    *   **Best Practice:** Apply streaming operators to **fixed-size** chunks or scalars.
    *   *Example:* Iterate through the dynamic array, extract a fixed number of bytes into a temporary buffer, and apply the stream operator to that buffer.
*   **Casting:**
    *   Use **Width Casting**: `WORD_WIDTH'(value)`.
    *   Avoid Type Casting for width: `logic'[WORD_WIDTH]'(value)` can cause syntax errors in Verilator.

## 3. Debugging Strategies
*   **C++ Backend Errors:** If you see errors like `VL_COPY_Q` or `no matching function for call`, it implies the SystemVerilog construct cannot be cleanly mapped to Verilator's C++ types. **Refactor to simpler loops.**
*   **Simplicity over Brevity:** Verilator converts SV to C++. A "verbose" SV `for` loop often translates to efficient C++ code. Do not force "one-line" SV solutions (like complex streams) if the tool fights them.

## 4. Example: Robust Packing Pattern
When packing bytes into words (or similar resizing):
```systemverilog
// 1. Allocate destination
words = new[num_words];
// 2. Allocate fixed-size temp buffer
bytes_t chunk = new[BYTES_PER_WORD]; 

for (int i = 0; i < num_words; i++) begin
   // 3. Simple Loop Copy (Safe & supported)
   for (int j = 0; j < BYTES_PER_WORD; j++) begin
      chunk[j] = source_data[i*BYTES_PER_WORD + j];
   end
   // 4. Stream on fixed chunk (Safe & supported)
   words[i] = { << 8 { chunk } };
end
```
