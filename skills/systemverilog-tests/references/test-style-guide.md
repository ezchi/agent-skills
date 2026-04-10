# SystemVerilog Testbench Style Guide

## Verification Integrity

- **Never compromise test quality to make tests pass.** If a test fails, the DUT is wrong — not the test. Do not loosen assertions, reduce transaction counts, widen tolerance margins, comment out checks, or skip scenarios.
- **Maximize assertion density.** Every output with a defined relationship must be checked. Every protocol invariant must have a concurrent assertion. Unchecked signals are silent corruption waiting to happen.
- **Scoreboard every data path.** If data enters and exits the DUT, a scoreboard must compare every transaction. Do not rely on waveform inspection.
- **Test error paths, not just happy paths.** Error/overflow/underflow outputs must be tested for both assertion (when the condition occurs) and non-assertion (when it should not occur). A test suite that only exercises normal operation is incomplete.
- **Check on every transaction, not at the end.** Assertions and scoreboard checks should fire per-transaction or per-cycle, not in a summary block at the end of the test. Late checking hides the cycle where corruption began.
- **Concurrent assertions for protocol invariants.** Use `assert property` for rules that must hold at all times (e.g., "valid must not rise during reset", "data must be stable while valid && !ready"). These catch violations regardless of which test is running.

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

## Reproducible Randomness

- **Seed via plusarg:** Every testbench that uses random stimulus MUST accept `+seed=<N>` via `$value$plusargs`. If not provided, derive a seed from `$urandom`.
- **Log the seed:** Always `$display` the seed at simulation start so failures can be reproduced with `+seed=<value>`.
- **Use `$urandom` / `$urandom_range`** for all random stimulus generation. Never use `$random` (signed, old-style).
- **Prefer random data over hardcoded constants** wherever possible. Hardcode only when testing a specific known boundary or protocol requirement.

Good:
```systemverilog
int unsigned seed;
initial begin
    if (!$value$plusargs("seed=%d", seed)) seed = $urandom;
    $display("Random seed: %0d  (reproduce with +seed=%0d)", seed, seed);
end
```

Poor:
```systemverilog
initial begin
    data_in = 32'hDEAD_BEEF;  // hardcoded — covers one value forever
end
```

## Test Categories (Both Required)

- **Directed tests:** Deterministic stimulus for specific scenarios — reset behavior, boundary values, known protocol edge cases. Every test suite must have at least one directed test.
- **Random constrained tests:** Randomized stimulus within legal constraints for broad coverage. Every test suite must have at least one random constrained test. Random tests must log their seed.

## Transaction Protocol Rules

When the DUT uses valid/ready, valid/data, request/grant, or similar handshake interfaces:

- **Back-to-back transactions (mandatory test):** Send consecutive transactions with zero idle cycles between them. This stresses pipeline, handshake, and state machine logic.
- **Random inter-transaction gaps (mandatory test):** Insert `$urandom_range(0, MAX_GAP)` idle cycles between transactions. This tests the DUT under varying throughput and exposes idle-state bugs.
- **Random data when valid is deasserted (mandatory):** When `valid` (or equivalent qualifier) is low, drive random garbage on data buses. NEVER leave data at zero or at the last valid value. This catches bugs where the DUT samples data outside the valid window.

Good:
```systemverilog
task automatic drive_txn(input logic [WIDTH-1:0] data);
    o_valid <= 1;
    o_data  <= data;
    delay_cc(1);
    o_valid <= 0;
    o_data  <= $urandom;  // random garbage when invalid
endtask

task automatic drive_with_random_gap();
    drive_txn($urandom);
    // Random idle gap
    repeat ($urandom_range(0, LP_MAX_GAP)) begin
        o_data <= $urandom;  // keep data random while idle
        delay_cc(1);
    end
endtask
```

Poor:
```systemverilog
task automatic drive_txn(input logic [WIDTH-1:0] data);
    o_valid <= 1;
    o_data  <= data;
    delay_cc(1);
    o_valid <= 0;
    o_data  <= '0;  // BUG: data is zero when invalid — hides sampling bugs
endtask
```

## Stress Tests (Mandatory)

- **Every DUT must have at least one stress test.** A stress test is a long-running random test that exercises the DUT under sustained load.
- Parameterize the transaction count via `LP_NUM_STRESS_TXNS` (default: thousands, e.g., 10_000).
- Stress tests must combine: back-to-back bursts, random gaps, random data, and random valid/invalid patterns.
- Use a scoreboard or reference model to verify correctness across the entire run.
- Stress tests must be reproducible via the `+seed=<N>` plusarg.
