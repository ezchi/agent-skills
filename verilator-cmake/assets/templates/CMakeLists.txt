cmake_minimum_required(VERSION 3.20)

project({{project_name}})

find_package(verilator)

if (NOT verilator_FOUND)
  message(FATAL_ERROR "Verilator was not found. Either install it, or set the VERILATOR_ROOT environment variable")
endif()

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
)

if(ENABLE_WAVEFORMS)
  list(APPEND VERILATOR_FLAGS --trace-fst)
endif()

`if [[SystemVerilog TB]]
set(PREFIX {{project_name}})
set(MAIN_DIR ${CMAKE_BINARY_DIR}/CMakeFiles/${PREFIX}.dir/${PREFIX}.dir)

add_executable(${PREFIX} ${MAIN_DIR}/${PREFIX}__main.cpp)
target_compile_options(${PREFIX} PRIVATE -Werror)
target_compile_features(${PREFIX} PRIVATE cxx_std_17)

list(APPEND VERILATOR_FLAGS --main)

verilate({{project_name}}
  INCLUDE_DIRS "."
  TOP_MODULE {{top_module}}
  PREFIX ${PREFIX}
  SOURCES ${RTL_SOURCES}
  VERILATOR_ARGS ${VERILATOR_FLAGS}
)
`endif

`if [[ C++ TB ]]

add_executable({{exe_name}}
  sim_main.cpp
)

verilator({{exe_name}}
  SOURCES ${RTL_SOURCES}
  TOP_MODULE {{top_module}}
  VERILATOR_ARGS ${VERILATOR_FLAGS}
)
`endif
