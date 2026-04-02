import pytest
from pathlib import Path
from cocotb_tools.runner import get_runner

# ---------------------------------------------------------------------------
# Build directory layout (out-of-source, per-test):
#   <repo_root>/build/cocotb/<test_dir_name>/
#
# This keeps the source tree clean and allows parallel test execution since
# each test gets its own isolated build directory.
# ---------------------------------------------------------------------------

SIMULATOR = "verilator"


def test_dut_runner(pytestconfig, build_dir):
    """Build and run cocotb tests for the DUT using Verilator."""

    # 1. Setup paths
    curr_dir = Path(__file__).parent
    rtl_dir = curr_dir.parent.parent / "src"

    # 2. Get runner options
    waves = pytestconfig.getoption("waves")

    runner = get_runner(SIMULATOR)

    # 3. Build model — each test writes to its own build_dir
    runner.build(
        sources=[rtl_dir / "dut.sv"],
        hdl_toplevel="dut",
        always=True,
        waves=waves,
        build_dir=build_dir,
        build_args=["--timescale", "1ns/1ps"],
    )

    # 4. Run test
    runner.test(
        hdl_toplevel="dut",
        test_module="test_dut",
        waves=waves,
        build_dir=build_dir,
    )


if __name__ == "__main__":
    import sys

    pytest.main(sys.argv)
