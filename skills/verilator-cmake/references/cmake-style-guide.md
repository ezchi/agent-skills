# CMake Style Guide for Verilator Projects

- minimum version 3.20 or later recommended
- use lowercase commands when possible
- group sources by function
- avoid hardcoded absolute paths
- prefer `target_include_directories`
- prefer `target_compile_definitions`
- each simulation target should have:
  - clear name
  - defined source list
  - output name
