module example_fifo #(
  parameter P_WIDTH = 32,
  parameter P_DEPTH = 16
)(
  input  logic iClk,
  input  logic iRst,
  input  logic iPush,
  input  logic iPop,
  input  logic [P_WIDTH-1:0] iData,
  output logic [P_WIDTH-1:0] oData,
  output logic oFull,
  output logic oEmpty
);

// TODO: FIFO logic following style guide

endmodule
