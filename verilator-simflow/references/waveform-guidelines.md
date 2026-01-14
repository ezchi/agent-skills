# Waveform Dumping Guidelines

## Default waveform format

- **FST format is recommended and should be used by default**
- VCD should only be used for legacy tool compatibility

### Why FST?

- significantly smaller files than VCD
- faster tracing with Verilator
- faster loading in GTKWave
- native tool support with no post-processing

---

## Tracing policy

- tracing **must be enabled conditionally**
- avoid always-on waveform dumping in long simulations
- enable only for:
  - failing tests
  - focused debug scenarios
  - CI artifact capture when necessary

---

## Verilator command-line flags

Use:

--trace-fst
--trace-structs

```makefile
Example:
    verilator -Wall --cc --trace-fst --trace-structs top.sv
```


Notes:

- `--trace-fst` generates FST waveform support
- `--trace-structs` records packed/unpacked struct members

---

## C++ harness usage

Use the FST tracer class:

```cpp
#include "verilated_fst_c.h"

VerilatedFstC* tfp = new VerilatedFstC;

Verilated::traceEverOn(true);
top->trace(tfp, 99);

tfp->open("wave.fst");

// simulation loop…

tfp->close();
```


    
