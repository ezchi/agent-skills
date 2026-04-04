#include "verilated.h"
#include "verilated_fst_c.h"
#include "Vtop.h"

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);

    Vtop *top = new Vtop;

#if VM_TRACE
    Verilated::traceEverOn(true);
    VerilatedFstC* tfp = new VerilatedFstC;
    top->trace(tfp, 99);
    tfp->open("wave.fst");
#endif

    while (!Verilated::gotFinish()) {
        // clock + eval loop here
    }

#if VM_TRACE
    tfp->close();
#endif

    delete top;
    return 0;
}
