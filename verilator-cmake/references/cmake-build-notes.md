# Verilator Build Rules

- `--cc` generates C++ output
- `--exe` when compiling harness
- testbench can be SystemVerilog or C++
- recommended flags:
  - --trace
  - --timing
  - -Wall
- do not use unsupported SV features
- integrate `sim_main.cpp` harness for easy execution
