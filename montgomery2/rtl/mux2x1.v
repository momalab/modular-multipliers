module mux2x1 #(
parameter SIZE = 8
) (
input [SIZE-1:0] a,                
input [SIZE-1:0] b,                
input            sel,              
output[SIZE-1:0] out);             
  
assign out = sel ? b : a;  
            
endmodule  
