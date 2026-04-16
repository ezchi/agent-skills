# Cocotb Testbench Style Guide

## Verification Integrity

- **Never compromise test quality to make tests pass.** If a test fails, the DUT is wrong — not the test. Do not loosen assertions, reduce transaction counts, widen tolerance margins, comment out checks, or skip scenarios.
- **Maximize assertion density.** Every output with a defined relationship must be checked. Every protocol invariant must have a monitor coroutine asserting it continuously. Unchecked signals are silent corruption waiting to happen.
- **Scoreboard every data path.** If data enters and exits the DUT, a scoreboard must compare every transaction. Do not rely on waveform inspection.
- **Test error paths, not just happy paths.** Error/overflow/underflow outputs must be tested for both assertion (when the condition occurs) and non-assertion (when it should not occur). A test suite that only exercises normal operation is incomplete.
- **Check on every transaction, not at the end.** Assertions and scoreboard checks should fire per-transaction in a monitor coroutine, not in a summary block at test completion. Late checking hides the cycle where corruption began.
- **Monitor coroutines for protocol invariants.** Use `cocotb.start_soon()` to launch background coroutines that continuously check protocol rules (e.g., "valid must not rise during reset", "data must be stable while valid and not ready"). These catch violations regardless of which stimulus sequence is running.

## Naming Conventions
- Testbench files should be named `test_<module_name>.py`.
- Tests should be decorated with `@cocotb.test()` and named descriptively (e.g., `async def test_fifo_overflow(dut):`).
- Clocks should be generated using `cocotb.clock.Clock`.
- **No `Timer()` or `NextTimeStep()` allowed.** Never use `Timer(N, "ns")` or `NextTimeStep()` to advance time or synchronize — they are incompatible with Verilator and create race conditions in synchronous designs. Always synchronize to the clock edge via `await RisingEdge(dut.clk)` or use `ReadOnly()` for sampling.
- **No `FallingEdge` for driving or sampling.** It creates setup/hold races with `posedge`-clocked RTL. Use only `RisingEdge`.

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
- **Signal Driving:** Drive and sample data ONLY immediately after `RisingEdge(dut.clk)` (inside `delay_cc`). **`FallingEdge` is banned** for driving or sampling — it creates setup/hold races with `posedge`-clocked RTL.
- **Clock Generators:** Use `cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())`.
- **Initialization:** Use an explicit reset task. Ensure all control signals have known initial values before releasing reset.
- **SystemVerilog structs:** Always model each RTL `struct` used by the testbench with a dedicated Python class. Do not represent structs as loose dicts, tuples, or anonymous packed integers in drivers, monitors, or scoreboards.

### Race Condition Awareness (Cocotb Scheduling)

Cocotb uses trigger phases that map to the IEEE 1800 scheduling regions.
Understanding them prevents read/write races:

* **Drive after `RisingEdge`.**  `await RisingEdge(dut.clk)` resumes in the
  Active region.  Driving signals here is correct — the values propagate through
  combinational logic before the next clock edge.
* **Sample in `ReadOnly` if needed.**  If you must sample a signal that is being
  driven in the same timestep by other coroutines, use
  `await cocotb.triggers.ReadOnly()` to wait until the Postponed region where all
  values are settled.  Prefer this over inserting zero-time delays.
* **Never use `ReadWrite` for normal driving.**  `ReadWrite` re-enters the Active
  region and can re-trigger delta cycles.  It is almost never needed in
  well-structured tests.
* **No `Timer` or `NextTimeStep`.** These triggers are strictly forbidden. `Timer` (even with 0 delay) and `NextTimeStep` create scheduling races and are incompatible with Verilator's clock-driven model. Use `RisingEdge` or `ReadOnly` instead.

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

## Test Categories (Both Required)

- **Directed tests:** Deterministic stimulus for specific scenarios — reset behavior, boundary values, known protocol edge cases. Every test suite must have at least one directed test.
- **Random constrained tests:** Randomized stimulus within legal constraints for broad coverage. Every test suite must have at least one random constrained test. Random tests must use the `random_seed` fixture and log their seed.

## Transaction Protocol Rules

When the DUT uses valid/ready, valid/data, request/grant, or similar handshake interfaces:

- **Back-to-back transactions (mandatory test):** Send consecutive transactions with zero idle cycles between them. This stresses pipeline, handshake, and state machine logic.
- **Random inter-transaction gaps (mandatory test):** Insert `random.randint(0, MAX_GAP)` idle cycles between transactions. This tests the DUT under varying throughput and exposes idle-state bugs.
- **Random data when valid is deasserted (mandatory):** When `valid` (or equivalent qualifier) is low, drive random garbage on data buses. NEVER leave data at zero or at the last valid value. This catches bugs where the DUT samples data outside the valid window.

Good:
```python
async def drive_txn(dut, data):
    dut.i_valid.value = 1
    dut.i_data.value = data
    await delay_cc(dut, 1)
    dut.i_valid.value = 0
    dut.i_data.value = random.randint(0, DATA_MASK)  # random garbage when invalid

async def drive_with_random_gap(dut, data):
    await drive_txn(dut, data)
    gap = random.randint(0, MAX_GAP)
    for _ in range(gap):
        dut.i_data.value = random.randint(0, DATA_MASK)  # keep data random while idle
        await delay_cc(dut, 1)
```

Poor:
```python
async def drive_txn(dut, data):
    dut.i_valid.value = 1
    dut.i_data.value = data
    await delay_cc(dut, 1)
    dut.i_valid.value = 0
    dut.i_data.value = 0  # BUG: data is zero when invalid — hides sampling bugs
```

## Stress Tests (Mandatory)

- **Every DUT must have at least one stress test.** A stress test is a long-running random test that exercises the DUT under sustained load.
- Parameterize the transaction count via a named constant `NUM_STRESS_TXNS` (default: thousands, e.g., 10_000).
- Stress tests must combine: back-to-back bursts, random gaps, random data, and random valid/invalid patterns.
- Use a scoreboard or reference model to verify correctness across the entire run.
- Stress tests must be reproducible via the `random_seed` fixture / `COCOTB_RANDOM_SEED` environment variable.

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
