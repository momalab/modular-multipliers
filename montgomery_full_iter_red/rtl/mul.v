module mul #(
  parameter STAGE  = 1,
  parameter SIZE1  = 4,
  parameter SIZE2  = 4
 ) (
  input clk,
  input  [SIZE1-1 :0] a,
  input  [SIZE2-1 :0] b,
  output [SIZE1+SIZE2-1 :0] y
);

wire [SIZE1+SIZE2-1:0] y_temp[0:STAGE-1];
wire [SIZE1+SIZE2-1:0] y_prod;
genvar i;
generate
for(i=1; i<7; i=i+1) begin
 if(STAGE==i) begin
 if(i==1) begin
    DW02_mult #(.A_width(SIZE1), .B_width(SIZE2))
    U1 (.A(a), .B(b), .TC(1'b0), . PRODUCT(y_temp[0]));
    //async_dff #(.SIZE(SIZE1+SIZE2)) u_product 
    //(.CLK(clk), .D(y_prod), .Q(y_temp[0]));
 end else if(i==2) begin
    DW02_mult_2_stage #(.A_width(SIZE1), .B_width(SIZE2))
    U1 (.CLK(clk), .A(a), .B(b), .TC(1'b0), . PRODUCT(y_temp[1]));
 end else if(i==3) begin
    DW02_mult_3_stage #(.A_width(SIZE1), .B_width(SIZE2))
    U1 (.CLK(clk), .A(a), .B(b), .TC(1'b0), . PRODUCT(y_temp[2]));
 end else if(i==4) begin
    DW02_mult_4_stage #(.A_width(SIZE1), .B_width(SIZE2))
    U1 (.CLK(clk), .A(a), .B(b), .TC(1'b0), . PRODUCT(y_temp[3]));
 end else if(i==5) begin
    DW02_mult_5_stage #(.A_width(SIZE1), .B_width(SIZE2))
    U1 (.CLK(clk), .A(a), .B(b), .TC(1'b0), . PRODUCT(y_temp[4]));
 end else if(i==6) begin
    DW02_mult_6_stage #(.A_width(SIZE1), .B_width(SIZE2))
    U1 (.CLK(clk), .A(a), .B(b), .TC(1'b0), . PRODUCT(y_temp[5]));
 end
 end
end
endgenerate

assign y = y_temp[STAGE-1];

endmodule

