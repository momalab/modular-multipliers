module mux # (
parameter NBITS = 8,
parameter PBITS = 1,
parameter MLSIZE = 1 << PBITS
) (
input [NBITS-1:0] in [0:MLSIZE-1],
input [PBITS-1:0] sel,
output reg [NBITS-1:0] out
);
integer j;
always @* begin
  out = in[0];
  for (j=0; j<MLSIZE; j=j+1) begin
     if(j==sel) begin
        out = in[j];
        break;
     end
  end
end

endmodule
