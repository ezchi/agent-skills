module example_fifo #(
  parameter P_WIDTH = 32,
  parameter P_DEPTH = 16
)(
  input  logic i_clk,
  input  logic i_rst,
  input  logic i_push,
  input  logic i_pop,
  input  logic [P_WIDTH-1:0] i_din,
  output logic [P_WIDTH-1:0] o_dout,
  output logic o_full,
  output logic o_empty
);

// TODO: FIFO logic following style guide

endmodule
