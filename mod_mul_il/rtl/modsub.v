
module modsub #(
  parameter NBITS = 4096

 ) (
  input               clk,
  input  [NBITS+1 :0] a,
  input  [NBITS+1 :0] b,
  output [NBITS+1 :0] y
);

assign  y = a - b;

endmodule

