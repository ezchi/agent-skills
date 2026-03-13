import pytest

def pytest_addoption(parser):
    parser.addoption(
        "--waves", 
        action="store_true", 
        default=False, 
        help="Enable waveform dumping (e.g., vcd/fst files)"
    )
