---
name: verilator-cmake
description: |
  Provides capabilities to generate and maintain CMakeLists.txt files and
  supporting build infrastructure for Verilator-based SystemVerilog simulation
  projects. Includes executable targets, library builds, and C++ harness
  integration.
metadata:
  version: "1.0.0"
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

When asked to create a new CMake + Verilator project:

1. Create minimum CMake version header
2. Declare project name and language
3. Add Verilator package check
4. Define SystemVerilog source list
5. Invoke `verilator_generate` or custom command
6. Create executable simulation target
7. Link against Verilator libraries
8. Output valid complete `CMakeLists.txt`

---

## Procedure for Updating Existing Project

1. Parse the user's current CMakeLists file
2. Identify `add_executable` or custom verilator command
3. Add new source files into source list
4. Preserve user options and comments
5. Do not break existing targets
6. Maintain formatting rules from `cmake-style-guide.md`

---

## Templates Included

- project-level CMakeLists
- library build
- executable verilator build
- sim_main.cpp harness

---

## References Included

- CMake style guide
- Verilator build notes
