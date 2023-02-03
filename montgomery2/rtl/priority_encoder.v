module priority_encoder #(
parameter NBITS = 8,
parameter PBITS = 1,
parameter MLSIZE = 1 << PBITS
) (
input [NBITS+PBITS+1:0] yxn[0:MLSIZE/2], 
input [NBITS-1:0] y_loc_accum,
input             y_loc_th, 
output reg [NBITS-1:0] out);             
  
integer j;

wire y_loc_tinv;

assign y_loc_tinv = !y_loc_th;
always @* begin
  out = y_loc_th ? y_loc_accum[NBITS-1:0] : yxn[0];
  for (j = 0; j<MLSIZE/2; j = j+1) begin 
     if(yxn[y_loc_tinv+j][NBITS+PBITS+1] == 1'b0)
        out = yxn[y_loc_tinv+j][NBITS-1:0];
  end
end

            
endmodule  
