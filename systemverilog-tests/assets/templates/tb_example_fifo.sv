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

  // reset
  initial begin
    clk = 0;
    rst_n = 1;
    #20 rst = 0;
  end

  initial begin
    push = 0;
    pop = 0;

    // push
    repeat (4) begin
      @(posedge clk);
      push = 1;
      data_in = $random;
    end

    push = 0;

    // pop
    repeat (4) begin
      @(posedge clk);
      pop = 1;
    end

    $finish;
  end

endmodule
