module il_add #(
  parameter NBITS  = 4,
  parameter PBITS  = 2
 ) (
  input  [NBITS+PBITS+2 :0] a,
  input  [NBITS+PBITS+2 :0] b,
  output [NBITS+PBITS+3 :0] y
);

assign y = a + b;

endmodule
