---
name: verilator-cmake
description: |
  Provides capabilities to generate and maintain CMakeLists.txt files and
  supporting build infrastructure for Verilator-based SystemVerilog simulation
  projects. Includes executable targets, library builds, and C++ harness
  integration.
metadata:
  version: "1.2.0"
  depends_on:
    - systemverilog-core
    - systemverilog-tests
---

# Verilator CMake Skill

## Purpose

This skill creates and updates CMake build systems for:

- Verilator compiling SystemVerilog to C++
- generating simulation executables
- linking custom C++ test harnesses
- integrating SystemVerilog testbenches

This skill ensures build files are:

- portable
- reproducible
- idiomatic CMake
- compatible with Verilator best practices

---

## Capabilities

- Generate root `CMakeLists.txt` for a Verilator project
- Add targets for RTL modules and testbenches
- Create C++ simulation harness file
- Set include directory layout
- Add Verilator flags based on project needs
- Update an existing CMake build for new modules

---

## When to Activate

Activate when prompt mentions:

- “CMakeLists.txt for Verilator”
- “build SystemVerilog with CMake”
- “generate CMake project for Verilator”
- “Verilator compile script”
- “add Verilator target”

---

## Procedure for Creating New CMake Verilator Project

When asked to create a new CMake + Verilator project, verify you follow the **Robust Header Path** pattern:

1.  **Requirement Check**: Ensure `cmake_minimum_required` is at least 3.14.
2.  **C++ Standard**: 
    *   Use `target_compile_features(... PRIVATE cxx_std_20)`.
    *   **Reason**: Verilator 5.x timing and coroutine features (for SV testbenches) require C++20.
3.  **Explicit Output Directory**:
    *   Define a variable `VERILATOR_OUT_DIR` set to `${CMAKE_CURRENT_BINARY_DIR}/verilated_files`.
    *   Create this directory using `file(MAKE_DIRECTORY ...)`.
4.  **Explicit Includes**:
    *   Add `target_include_directories(... PRIVATE ${VERILATOR_OUT_DIR})` to the executable target.
5.  **Target Definition**:
    *   **C++ Testbench**: Add `main.cpp` to `add_executable`.
    *   **SystemVerilog Testbench**: Leave `add_executable` source list empty, and add `--main` to `verilate(VERILATOR_ARGS ...)`.
6.  **Explicit Prefix**:
    *   Always use the `PREFIX V<top_module>` argument in `verilate()`.

---

## Procedure for Updating Existing Project

1. Parse the user's current CMakeLists file
2. Identify `add_executable` or custom verilator command
3. Add new source files into source list
4. **Refactor Check**: If the existing CMakeLists does not use an explicit output directory or C++20, recommend or apply the refactoring to ensure compatibility with modern Verilator features.
5. Do not break existing targets
6. Maintain formatting rules from `cmake-style-guide.md`

---

## Templates Included

- `CMakeLists.txt` (Robust for both C++ and SV testbenches)
- `sim_main.cpp` harness

---

## References Included

- CMake style guide
- Verilator build notes
