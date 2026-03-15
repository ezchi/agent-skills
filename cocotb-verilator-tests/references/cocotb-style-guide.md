# Cocotb Testbench Style Guide

## Naming Conventions
- Testbench files should be named `test_<module_name>.py`.
- Tests should be decorated with `@cocotb.test()` and named descriptively (e.g., `async def test_fifo_overflow(dut):`).
- Clocks should be generated using `cocotb.clock.Clock`.
- Avoid using delays like `Timer(10, "ns")` for synchronization in synchronous logic. Instead, always synchronize to the clock edge using `await RisingEdge(dut.clk)`.

## Project Structure & Runners
- **Pytest Runner:** Prefer `cocotb_tools.runner` via a Python script (e.g., `runner.py` or `conftest.py`) over a legacy `Makefile`.
- **Command Line:** Run simulations with `pytest -s runner.py` or just `pytest`.

## Best Practices
- **Timeouts:** All tests must have a `timeout_time` specified in the `@cocotb.test()` decorator to prevent simulation hangs.
- **Waveform Clarity:** Run at least 2 extra clock cycles using `await delay_cc(dut, 2)` before the test completes.
- **Clock Delays:** ALWAYS use a `delay_cc(dut, n)` helper function; DO NOT use `await RisingEdge(dut.clk)` or loops of them directly in the test logic.
- **Signal Driving:** Drive and sample data ONLY immediately after `RisingEdge(dut.clk)` (inside `delay_cc`). Avoid using falling edges (`FallingEdge`) unless explicitly requested.
- **Clock Generators:** Use `cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())`.
- **Initialization:** Use an explicit reset task. Ensure all control signals have known initial values before releasing reset.

## No Magic Numbers
- **Every meaningful literal must be a named constant.** Do not scatter bare numbers (other than 0 and 1) across test code. Define them at the top of the file or in a shared constants module.
- Use descriptive names that convey **meaning**, not the value itself.
- For values derived from RTL parameters, mirror the RTL constant names to keep traceability.

Good:
```python
FIFO_DEPTH     = 64
TIMEOUT_CYCLES = 256
BURST_LEN      = 16
DATA_MASK      = 0xFFFF_FFFF

@cocotb.test(timeout_time=500, timeout_unit="us")
async def test_fifo_full(dut):
    for _ in range(FIFO_DEPTH):
        dut.i_data.value = random.randint(0, DATA_MASK)
        dut.i_valid.value = 1
        await delay_cc(dut, 1)
```

Poor:
```python
@cocotb.test(timeout_time=500, timeout_unit="us")
async def test_fifo_full(dut):
    for _ in range(64):                          # what is 64?
        dut.i_data.value = random.randint(0, 0xFFFFFFFF)  # where does this mask come from?
        dut.i_valid.value = 1
        await delay_cc(dut, 1)
```
