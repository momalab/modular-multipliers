module il_add #(
  parameter NBITS  = 4,
 ) (
  input  [NBITS-1 :0] a,
  input  [NBITS-1 :0] b,
  output [NBITS-1 :0] y
);

y = a + b;

endmodule
