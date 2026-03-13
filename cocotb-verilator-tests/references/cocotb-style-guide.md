# Cocotb Testbench Style Guide

## Naming Conventions
- Testbench files should be named `test_<module_name>.py`.
- Tests should be decorated with `@cocotb.test()` and named descriptively (e.g., `async def test_fifo_overflow(dut):`).
- Clocks should be generated using `cocotb.clock.Clock`.
- Avoid using delays like `Timer(10, "ns")` for synchronization in synchronous logic. Instead, always synchronize to the clock edge using `await RisingEdge(dut.clk)`.

## Best Practices
- **Timeouts:** All tests must have a `timeout_time` specified in the `@cocotb.test()` decorator to prevent simulation hangs.
- **Waveform Clarity:** Run at least 2 extra clock cycles using `await delay_cc(dut, 2)` before the test completes.
- **Clock Delays:** ALWAYS use a `delay_cc(dut, n)` helper function; DO NOT use `await RisingEdge(dut.clk)` or loops of them directly in the test logic.
- **Signal Driving:** Drive and sample data ONLY immediately after `RisingEdge(dut.clk)` (inside `delay_cc`). Avoid using falling edges (`FallingEdge`) unless explicitly requested.
- **Clock Generators:** Use `cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())`.
- **Initialization:** Use an explicit reset task. Ensure all control signals have known initial values before releasing reset.
