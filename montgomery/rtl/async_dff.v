module async_dff #(
 parameter SIZE = 8
) (
input [SIZE-1:0] D, // Data input 
input CLK, // clock input 
input ASYNC_RESET, // asynchronous reset low level 
output reg [SIZE-1:0] Q // output Q
);
 
always @(posedge CLK or negedge ASYNC_RESET) 
begin
 if(ASYNC_RESET==1'b0)
  Q <= {(SIZE){1'b0}}; 
 else 
  Q[SIZE-1:0] <= D[SIZE-1:0]; 
end 

endmodule 
