# Cocotb Testbench Style Guide

## Naming Conventions
- Testbench files should be named `test_<module_name>.py`.
- Tests should be decorated with `@cocotb.test()` and named descriptively (e.g., `async def test_fifo_overflow(dut):`).
- Clocks should be generated using `cocotb.clock.Clock`.
- Avoid using delays like `Timer(10, "ns")` for synchronization in synchronous logic. Instead, always synchronize to the clock edge using `await RisingEdge(dut.clk)`.

## Project Structure & Runners
- **Pytest Runner:** Prefer `cocotb_tools.runner` via a Python script (e.g., `runner.py` or `conftest.py`) over a legacy `Makefile`.
- **Command Line:** Run simulations with `pytest -s runner.py` or just `pytest`.

## Build Directories
- **Out-of-source builds:** Build artifacts must go under `<repo_root>/build/cocotb/<test_dir_name>/`, never inside the source tree. This keeps the repo clean and avoids `sim_build/` clutter.
- **Per-test isolation:** Each test directory gets its own build directory so tests can run in parallel (`pytest -n auto`) without conflicting. Use the `build_dir` fixture from `conftest.py`.
- **Never hardcode `sim_build`** as a build path. Always use the `build_dir` fixture.

Good:
```python
def test_dut_runner(pytestconfig, build_dir):
    runner = get_runner("verilator")
    runner.build(
        sources=[rtl_dir / "dut.sv"],
        hdl_toplevel="dut",
        build_dir=build_dir,  # out-of-source, per-test
        ...
    )
    runner.test(
        hdl_toplevel="dut",
        test_module="test_dut",
        build_dir=build_dir,
        ...
    )
```

Poor:
```python
def test_dut_runner(pytestconfig):
    runner = get_runner("verilator")
    runner.build(
        build_dir=curr_dir / "sim_build",  # pollutes source tree, blocks parallel runs
        ...
    )
```

## Best Practices
- **Timeouts:** All tests must have a `timeout_time` specified in the `@cocotb.test()` decorator to prevent simulation hangs.
- **Waveform Clarity:** Run at least 2 extra clock cycles using `await delay_cc(dut, 2)` before the test completes.
- **Clock Delays:** ALWAYS use a `delay_cc(dut, n)` helper function; DO NOT use `await RisingEdge(dut.clk)` or loops of them directly in the test logic.
- **Signal Driving:** Drive and sample data ONLY immediately after `RisingEdge(dut.clk)` (inside `delay_cc`). Avoid using falling edges (`FallingEdge`) unless explicitly requested.
- **Clock Generators:** Use `cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())`.
- **Initialization:** Use an explicit reset task. Ensure all control signals have known initial values before releasing reset.

## Reproducible Randomness
- **Every test file that uses randomness must seed `random` at the top of each test** using a seed derived from the environment or the current time.
- Use `COCOTB_RANDOM_SEED` environment variable to override the seed for reproducibility. If unset, derive a seed from `time.time_ns()` so each run differs.
- **Always log the seed** at the start of the test so failures can be reproduced by re-running with `COCOTB_RANDOM_SEED=<value>`.
- Use the `random_seed` pytest fixture (provided by `conftest.py`) — do not call `random.seed()` manually in tests.

Good:
```python
@cocotb.test(timeout_time=500, timeout_unit="us")
async def test_fifo_random(dut, random_seed):
    for _ in range(BURST_LEN):
        dut.i_data.value = random.randint(0, DATA_MASK)
        ...
```

Poor:
```python
@cocotb.test(timeout_time=500, timeout_unit="us")
async def test_fifo_random(dut):
    random.seed(42)  # same values every run — defeats the purpose of randomization
    ...
```

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
