module {{module_name}} #(
  parameter integer P_WIDTH = {{width}}
)(
  input  logic i_clk,
  input  logic i_rst,
  input  logic [P_WIDTH-1:0] i_din,
  output logic [P_WIDTH-1:0] o_dout
);

  // Combinational logic here
  // Sequential logic here

endmodule
