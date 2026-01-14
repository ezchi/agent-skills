interface {{interface_name}} #(parameter int P_WIDTH = {{width}});
  logic clk;
  logic rst;
  logic [P_WIDTH-1:0] data;
  logic valid;
  logic ready;
endinterface
