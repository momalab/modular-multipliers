module async_dff #(
 parameter SIZE = 8,
 parameter STAGE = 1
) (
input [SIZE-1:0] D, // Data input 
input CLK, // clock input 
input ASYNC_RESET, // asynchronous reset low level 
output [SIZE-1:0] Q // output Q
);

reg [SIZE-1:0] data [1:STAGE];

integer i;
 
always @(posedge CLK or negedge ASYNC_RESET) 
begin
 if(ASYNC_RESET==1'b0) begin
  for(i=1;i<STAGE+1;i=i+1) begin
     data[i] <= {(SIZE){1'b0}};
  end
 end else begin 
  for(i=1;i<STAGE+1;i=i+1) begin
     if(i==1) begin
       data[i] <= D;
     end else begin
       data[i] <= data[i-1];
     end
  end
 end 
end 

assign Q = STAGE ? data[STAGE] : D;

endmodule 
