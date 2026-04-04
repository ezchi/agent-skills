module fifo_tb;

  localparam LP_WIDTH = 32;

  logic clk;
  logic rst;
  logic push;
  logic pop;
  logic [LP_WIDTH-1:0] data_in;
  logic [LP_WIDTH-1:0] data_out;

  fifo dut (...); // fill as needed

  // clock
  always #5 clk = ~clk;

  // watchdog
  initial begin
    #100ms;
    $error("FIFO Simulation Timeout!");
    $finish;
  end

  // reset
  initial begin
    clk = 0;
    rst = 1;
    #20 rst = 0;
  end

  task automatic delay_cc(input int cycles);
    repeat (cycles) @(posedge clk);
  endtask : delay_cc

  initial begin
    push = 0;
    pop = 0;

    // push
    repeat (4) begin
      delay_cc(1);
      push = 1;
      data_in = $random;
    end

    push = 0;

    // pop
    repeat (4) begin
      delay_cc(1);
      pop = 1;
    end

    delay_cc(2);
    $finish;
  end

endmodule
