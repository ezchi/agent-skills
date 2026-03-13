# Makefile for Cocotb with Verilator

# Simulator and Language
SIM ?= verilator
TOPLEVEL_LANG ?= verilog

# RTL Source Files
VERILOG_SOURCES += $(PWD)/../../src/dut.sv

# Top-level module name in SystemVerilog
TOPLEVEL = dut

# Python test module name (without .py)
MODULE = test_dut

# Waveform dumping (set WAVES=1 to enable)
WAVES ?= 0
ifeq ($(WAVES), 1)
    EXTRA_ARGS += --trace --trace-fst --trace-structs
endif

# Include cocotb makefile
include $(shell cocotb-config --makefiles)/Makefile.sim
