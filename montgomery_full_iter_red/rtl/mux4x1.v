module mux4x1 #(
parameter SIZE = 8
) (
input [SIZE-1:0] a,               
input [SIZE-1:0] b,               
input [SIZE-1:0] c,               
input [SIZE-1:0] d,               
input [1:0]      sel,             
output[SIZE-1:0] out);            
  
assign out = sel[1] ? (sel[0] ? d : c) : (sel[0] ? b : a);  
            
endmodule  
