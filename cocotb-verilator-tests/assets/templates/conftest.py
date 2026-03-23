import os
import random
import time

import cocotb
import pytest


def pytest_addoption(parser):
    parser.addoption(
        "--waves",
        action="store_true",
        default=False,
        help="Enable waveform dumping (e.g., vcd/fst files)",
    )


@pytest.fixture(autouse=True)
def random_seed():
    """Seed the random module for reproducible-yet-varying test runs.

    Override with: COCOTB_RANDOM_SEED=<int> pytest ...
    """
    env_seed = os.environ.get("COCOTB_RANDOM_SEED")
    seed = int(env_seed) if env_seed else time.time_ns()
    random.seed(seed)
    cocotb.log.info("Random seed: %d  (reproduce with COCOTB_RANDOM_SEED=%d)", seed, seed)
    return seed
