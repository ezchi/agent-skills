`timescale 1ns/100ps

module {{dut_name}}_tb;

localparam int LP_WIDTH = {{width}};

logic clk;
logic rst;

// DUT I/O
{{dut_port_declarations}}

// Clock
initial begin
    clk = 0;
    forever #0.5 clk = ~clk;
end

task automatic delay_cc(input int cycles);
    repeat (cycles) @(posedge clk);
endtask : cc


// Reset
task automatic reset_pulse();
    rst <= 1;
    delay_cc(5);
    rst_n <= 1;
endtask

// DUT instance
{{dut_instantiation}}

initial begin
    reset_pulse();

    // TODO: stimulus here
    #1us;
    $finish;
end

endmodule
