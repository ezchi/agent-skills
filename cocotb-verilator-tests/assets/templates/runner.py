import pytest
from pathlib import Path
from cocotb_tools.runner import get_runner

def test_dut_runner(pytestconfig):
    """Build and run cocotb tests for the DUT using Verilator."""
    
    # 1. Setup paths
    # Assuming:
    # project_root/
    #   src/dut.sv
    #   tests/cocotb/
    #     conftest.py
    #     runner.py
    #     test_dut.py
    
    curr_dir = Path(__file__).parent
    rtl_dir  = curr_dir.parent.parent / "src"
    
    # 2. Get Runner Option
    # Usage: pytest runner.py --waves
    waves = pytestconfig.getoption("waves")
    
    runner = get_runner("verilator")
    
    # 3. Build Model
    runner.build(
        sources=[rtl_dir / "dut.sv"],
        hdl_toplevel="dut",
        always=True,
        waves=waves,
        build_dir=curr_dir / "sim_build",
        build_args=["--timescale", "1ns/1ps"]
    )
    
    # 4. Run Test
    runner.test(
        hdl_toplevel="dut",
        test_module="test_dut",
        waves=waves,
        build_dir=curr_dir / "sim_build"
    )

if __name__ == "__main__":
    # To run this script directly, we manually invoke pytest
    import sys
    pytest.main(sys.argv)
