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
- **Clock Edge Usage: Do NOT drive or sample data on `negedge clk`. This is a hard ban — `negedge` for data creates setup/hold ambiguity and race conditions with `posedge`-clocked RTL.**
- **Waveform Clarity: Run `delay_cc(2)` before calling `$finish` to ensure last signals are clearly visible.**
- **Clock Delays: ALWAYS use `delay_cc(n)` task; DO NOT use `@(posedge clk)` or `repeat(n) @(posedge clk)` in stimulus.**
- **Interface Priority: Prefer `interface_inst.delay_cc(n)` over a local testbench `delay_cc(n)` if an interface is available.**
- **Interface Consistency: Interfaces with a clock MUST define a `delay_cc(int n)` task.**
- **No `#delay` of any kind** — `#0`, `#1`, `#1step`, `#<N>` are all banned in testbenches. They create inter-process race conditions by coupling behavior to simulator scheduling regions. Use `delay_cc(n)` for all time advancement.
- **Testbench NBA driving:** When a clocked testbench process drives DUT inputs, use `<=` (NBA) so the drive lands in the NBA region, after the DUT's Active-region `always_comb` evaluations. This prevents same-timestep read-before-write races.
- **`fork`/`join_none` synchronization:** Forked processes do not execute until the parent suspends (hits a blocking event or `wait`). After `fork`/`join_none`, always `delay_cc(1)` before relying on forked side-effects. (`delay_cc(0)` is a no-op — `repeat(0)` never fires.)
- **Named events — use `->>` (non-blocking trigger):** Use `->>` instead of `->` for named events. A blocking `->` can resolve before a concurrent `@(event)` is re-armed, causing trigger-before-wait deadlocks.
- **Edge-sensitive expressions:** Prefer `@(posedge clk iff (cond))` over `@(expr == val)`. The latter triggers on every change of `expr`, not just the transition to the target value, and races with the process that writes `expr`.
- assertions for protocol and reset correctness
