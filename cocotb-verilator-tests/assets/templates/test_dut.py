import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

async def delay_cc(dut, cycles=1):
    """Synchronize with the rising edge of the clock for a number of cycles."""
    for _ in range(cycles):
        await RisingEdge(dut.clk)

async def reset_dut(dut, cycles=5):
    """Reset the DUT."""
    dut.rst.value = 1
    await delay_cc(dut, cycles)
    dut.rst.value = 0
    await delay_cc(dut, 1)

@cocotb.test(timeout_time=10, timeout_unit="ms")
async def basic_test(dut):
    """A basic generic test for the DUT."""
    
    # 1. Start the clock
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    
    # 2. Reset the DUT
    await reset_dut(dut)
    
    # 3. Apply stimulus
    # dut.input_signal.value = 1
    # await delay_cc(dut, 1)
    
    # 4. Check results
    # assert dut.output_signal.value == expected_value, f"Output was {dut.output_signal.value}, expected {expected_value}"
    
    # 5. Run 2 more cycles at the end before finishing
    await delay_cc(dut, 2)
