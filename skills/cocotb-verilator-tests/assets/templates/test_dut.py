import random
from collections import deque

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

# Named constants — mirror RTL parameters for traceability
DATA_WIDTH       = 32
DATA_MASK        = (1 << DATA_WIDTH) - 1
MAX_GAP          = 8
NUM_STRESS_TXNS  = 10_000
BURST_LEN        = 16


async def delay_cc(dut, cycles=1):
    """Synchronize with the rising edge of the clock for a number of cycles."""
    for _ in range(cycles):
        await RisingEdge(dut.clk)


async def start_clock(dut):
    """Start the simulation clock."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())


async def reset_dut(dut, cycles=5):
    """Drive the reset pulse — call this for mid-test resets."""
    dut.rst.value = 1
    dut.i_valid.value = 0
    dut.i_data.value = random.randint(0, DATA_MASK)  # random data even during reset
    await delay_cc(dut, cycles)
    dut.rst.value = 0
    await delay_cc(dut, 1)


async def setup_dut(dut):
    """Initialize the DUT — starts the clock and drives reset."""
    await start_clock(dut)
    await reset_dut(dut)


async def drive_txn(dut, data):
    """Drive a single transaction — random garbage on data when valid is low."""
    dut.i_valid.value = 1
    dut.i_data.value = data
    await delay_cc(dut, 1)
    dut.i_valid.value = 0
    dut.i_data.value = random.randint(0, DATA_MASK)  # random when invalid


async def drive_with_random_gap(dut, data):
    """Drive a transaction followed by a random idle gap with random data."""
    await drive_txn(dut, data)
    gap = random.randint(0, MAX_GAP)
    for _ in range(gap):
        dut.i_data.value = random.randint(0, DATA_MASK)  # keep data random while idle
        await delay_cc(dut, 1)


# ──────────────────────────────────────────────
# Directed test: back-to-back transactions
# ──────────────────────────────────────────────
@cocotb.test(timeout_time=10, timeout_unit="ms")
async def test_back_to_back(dut):
    """Send consecutive transactions with zero idle cycles."""
    await setup_dut(dut)

    expected = deque()
    for _ in range(BURST_LEN):
        data = random.randint(0, DATA_MASK)
        expected.append(data)
        dut.i_valid.value = 1
        dut.i_data.value = data
        await delay_cc(dut, 1)

    dut.i_valid.value = 0
    dut.i_data.value = random.randint(0, DATA_MASK)  # random when invalid

    # TODO: Read and verify output against expected queue

    await delay_cc(dut, 2)


# ──────────────────────────────────────────────
# Random test: random gaps between transactions
# ──────────────────────────────────────────────
@cocotb.test(timeout_time=10, timeout_unit="ms")
async def test_random_gaps(dut):
    """Randomize idle cycles between transactions to test varying throughput."""
    await setup_dut(dut)

    expected = deque()
    for _ in range(BURST_LEN):
        data = random.randint(0, DATA_MASK)
        expected.append(data)
        await drive_with_random_gap(dut, data)

    # TODO: Read and verify output against expected queue

    await delay_cc(dut, 2)


# ──────────────────────────────────────────────
# Stress test: sustained random traffic
# ──────────────────────────────────────────────
@cocotb.test(timeout_time=100, timeout_unit="ms")
async def test_stress(dut):
    """Long-running random test with mixed back-to-back and gapped transactions."""
    await setup_dut(dut)

    scoreboard = deque()
    errors = 0

    for i in range(NUM_STRESS_TXNS):
        data = random.randint(0, DATA_MASK)
        scoreboard.append(data)

        # Randomly choose back-to-back or gapped
        if random.random() < 0.5:
            dut.i_valid.value = 1
            dut.i_data.value = data
            await delay_cc(dut, 1)
        else:
            await drive_with_random_gap(dut, data)

        # TODO: Monitor output side, pop from scoreboard, compare

    dut.i_valid.value = 0
    dut.i_data.value = random.randint(0, DATA_MASK)

    # TODO: Drain remaining entries from scoreboard

    assert errors == 0, f"Stress test failed with {errors} errors in {NUM_STRESS_TXNS} transactions"

    await delay_cc(dut, 2)
