# Verilator Compatibility Rules

- Do not use `force` or `release`
- No PLI calls
- No delays inside assertions
- `$finish` required
- All clocks must use `always` block or forever loop
- Avoid extensive hierarchy name references
