cmake_minimum_required(VERSION 3.14)

project({{project_name}})

find_package(verilator REQUIRED)

if (NOT verilator_FOUND)
  message(FATAL_ERROR "Verilator was not found. Either install it, or set the VERILATOR_ROOT environment variable")
endif()

# Define Sources
set(RTL_SOURCES
  {{rtl_file_list}}
)

set(VERILATOR_FLAGS
  -Wall
  --cc
  -O3
  --trace-structs
  --timing
  --compiler clang
  -Wno-fatal
)

if(ENABLE_WAVEFORMS)
  list(APPEND VERILATOR_FLAGS --trace-fst)
endif()

# --- Simulation Target Setup ---

set(TARGET_NAME {{exe_name}})

# 1. Define the executable
#    For C++ testbench: add your main.cpp
#    For SystemVerilog testbench: leave empty (verilate --main will provide the entry point)
add_executable(${TARGET_NAME} {{main_cpp_if_exists}})

# 2. Use C++20 if using Verilator --timing (highly recommended for SV testbenches)
target_compile_features(${TARGET_NAME} PRIVATE cxx_std_20)

# 3. Define a dedicated output directory for Verilator generated files
#    This prevents header-not-found issues by keeping generated files in a known location.
set(VERILATOR_OUT_DIR ${CMAKE_CURRENT_BINARY_DIR}/verilated_files)
file(MAKE_DIRECTORY ${VERILATOR_OUT_DIR})

message(STATUS "Verilator Output Directory: ${VERILATOR_OUT_DIR}")

# 4. Add the output directory to the target's include path
#    This ensures C++ testbenches can find "V{{top_module}}.h"
target_include_directories(${TARGET_NAME} PRIVATE ${VERILATOR_OUT_DIR} .)

# 5. Invoke Verilator to generate C++ models and attach them to the target
verilate(${TARGET_NAME}
  INCLUDE_DIRS "."
  TOP_MODULE {{top_module}}
  PREFIX V{{top_module}}           # Explicitly naming the C++ class is best practice
  DIRECTORY ${VERILATOR_OUT_DIR} # Output to the known directory
  SOURCES ${RTL_SOURCES}
  VERILATOR_ARGS
    ${VERILATOR_FLAGS}
    {{main_flag_if_sv_tb}}       # --main if using a SystemVerilog testbench
)
