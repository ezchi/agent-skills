# Verilator Compatibility Rules

- Do not use `force` or `release`
- No PLI calls
- No delays inside assertions
- `$finish` required
- **Timeout Watchdog required to prevent simulation hangs (e.g., `#10ms $error("Timeout"); $finish;`)**
- All clocks must use `always` block or forever loop
- Avoid extensive hierarchy name references
