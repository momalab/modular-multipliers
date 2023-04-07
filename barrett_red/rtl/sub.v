module sub #(
  parameter NBITS  = 4
 ) (
  input  [NBITS-1 :0] a,
  input  [NBITS-1 :0] b,
  output              cout,
  output [NBITS-1 :0] y
);

wire [NBITS:0] out;

//assign out = a - b;
//assign cout = out[NBITS];
//assign y    = out[NBITS-1:0];
DW01_sub #(.width(NBITS))
U1 (.A(a), .B(b), .CI(1'b0), .DIFF(y), .CO(cout));


endmodule

module sub_3 #(
  parameter NBITS  = 4
   ) (
     input  [NBITS-1 :0] a,
       input  [NBITS-1 :0] b,
         input               c,
           output              cout,
             output [NBITS-1 :0] y
             );

             wire [NBITS:0] out;

             assign out = a - b - c;

             assign cout = out[NBITS];
             assign y    = out[NBITS-1:0];

             endmodule

