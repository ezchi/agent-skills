import os
import random
import subprocess
import time
from pathlib import Path

import cocotb
import pytest


def pytest_addoption(parser):
    parser.addoption(
        "--waves",
        action="store_true",
        default=False,
        help="Enable waveform dumping (e.g., vcd/fst files)",
    )
    parser.addoption(
        "--seed",
        type=int,
        default=None,
        help="Random seed for reproducible test runs (overrides COCOTB_RANDOM_SEED)",
    )


@pytest.fixture(autouse=True)
def random_seed(request):
    """Seed the random module for reproducible-yet-varying test runs.

    Priority: --seed CLI flag > COCOTB_RANDOM_SEED env var > time.time_ns()
    Reproduce a run: pytest --seed=<value> ...
    """
    cli_seed = request.config.getoption("--seed")
    env_seed = os.environ.get("COCOTB_RANDOM_SEED")
    if cli_seed is not None:
        seed = cli_seed
    elif env_seed:
        seed = int(env_seed)
    else:
        seed = time.time_ns()
    random.seed(seed)
    cocotb.log.info("Random seed: %d  (reproduce with --seed=%d)", seed, seed)
    return seed


@pytest.fixture
def build_dir():
    """Return an out-of-source build directory unique to this test directory.

    Layout: <repo_root>/build/cocotb/<test_dir_name>/

    Each test directory gets its own build dir so tests can run in parallel
    without clobbering each other, and the source tree stays clean.
    """
    test_dir = Path(__file__).parent
    repo_root = _find_repo_root(test_dir)
    build_path = repo_root / "build" / "cocotb" / test_dir.name
    build_path.mkdir(parents=True, exist_ok=True)
    return build_path


def _find_repo_root(start: Path) -> Path:
    """Walk up from *start* to find the repository root (contains .git)."""
    candidate = start.resolve()
    while candidate != candidate.parent:
        if (candidate / ".git").exists():
            return candidate
        candidate = candidate.parent
    # Fallback: use git rev-parse
    result = subprocess.run(
        ["git", "rev-parse", "--show-toplevel"],
        capture_output=True,
        text=True,
        cwd=start,
    )
    if result.returncode == 0:
        return Path(result.stdout.strip())
    # Last resort: two levels up from the test directory
    return start.parent.parent
