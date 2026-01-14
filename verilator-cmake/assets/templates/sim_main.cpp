#include "V{{top_module}}.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

vluint64_t main_time = 0;

double sc_time_stamp() { return main_time; }

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);

    V{{top_module}} top;

    while (!Verilated::gotFinish()) {
        top.clk = !top.clk;

        top.eval();
        main_time++;
    }

    return 0;
}
