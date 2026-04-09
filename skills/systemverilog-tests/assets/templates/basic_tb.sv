`timescale 1ns/100ps

module {{dut_name}}_tb;

localparam int LP_WIDTH = {{width}};
localparam int LP_NUM_STRESS_TXNS = 10_000;
localparam int LP_MAX_GAP = 8;

logic clk;
logic rst;

// DUT I/O
{{dut_port_declarations}}

// Clock
initial begin
    clk = 0;
    forever #0.5 clk = ~clk;
end

// Watchdog
initial begin
    #1ms;
    $error("Simulation timeout reached!");
    $finish;
end

// Random seed — accept +seed=<N> for reproducibility
int unsigned seed;
initial begin
    if (!$value$plusargs("seed=%d", seed)) seed = $urandom;
    $display("Random seed: %0d  (reproduce with +seed=%0d)", seed, seed);
end

task automatic delay_cc(input int cycles);
    repeat (cycles) @(posedge clk);
endtask : delay_cc


// Reset
task automatic reset_pulse();
    rst <= 1;
    delay_cc(5);
    rst <= 0;
endtask

// DUT instance
{{dut_instantiation}}

initial begin
    reset_pulse();

    // Apply stimulus sequences
    {{stimulus_sequence}}

    delay_cc(2);
    $finish;
end

endmodule
