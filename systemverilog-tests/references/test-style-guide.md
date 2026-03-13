# SystemVerilog Testbench Style Guide

## Naming

- testbench modules end with `_tb`
- clock: `clk`
- reset active-high: `rst`
- stimulus tasks use `task automatic`
- interface instances use `<name>_if`

## Structure

1. timescale directive
2. DUT import
3. signal declarations
4. clock/reset generators
5. DUT instance
6. stimulus process
7. checkers/scoreboards
8. finish condition

## Best Practices

- self-checking wherever possible
- **MANDATORY: include a timeout watchdog (e.g., `#10ms $error("Simulation Timeout"); $finish;`)**
- avoid magic numbers
- use parameters and localparams
- **Clock Edge Usage: Do NOT drive or sample data on `negedge clk` unless specifically requested.**
- **Waveform Clarity: Run `delay_cc(2)` before calling `$finish` to ensure last signals are clearly visible.**
- **Clock Delays: ALWAYS use `delay_cc(n)` task; DO NOT use `@(posedge clk)` or `repeat(n) @(posedge clk)` in stimulus.**
- **Interface Priority: Prefer `interface_inst.delay_cc(n)` over a local testbench `delay_cc(n)` if an interface is available.**
- **Interface Consistency: Interfaces with a clock MUST define a `delay_cc(int n)` task.**
- do not use `#1` delay scattering for behavior
- assertions for protocol and reset correctness
