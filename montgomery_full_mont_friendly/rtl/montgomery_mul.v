//------------------------------------------------------------
//Input X,Y < p < 2^(k-1)
// with 2^(k-1) < p < 2^n and p = 2t + 1. with t is natural no.
//Output u = X.Y.2^(-k) mod p
//1.  u =0
//2.  for i = 0; i < n; i++ do
//      u = u + xi.Y
//      if u[0] == 1'b1 then
//        u = u + p;
//      end if
//      u = u div 2;
//    end for
//3.  if u >= p then
//      u = u -p
//    end if
//------------------------------------------------------------

//`define BEHAVIOR

module montgomery_mul #(
  parameter MUL_STAGE1 = 1,
  parameter MUL_STAGE2 = 1,
  parameter NBITS = 2048,
  parameter W = NBITS,
  parameter L = NBITS/W,
  parameter PBITS = 1
 ) (
  input               clk,
  input               rst_n,
  input               enable_p,
  input  [NBITS-1 :0] a,
  input  [NBITS-1 :0] b,
  input  [NBITS-1 :0] m,
  output [NBITS-1 :0] y,
  output              done_irq_p
);

//--------------------------------------
//reg/wire declaration
//--------------------------------------
genvar  i;
genvar j;

wire [NBITS-1:0]   m_input;

wire [2*NBITS-1:0] ab_w;
wire [2*NBITS-1:0] ab[0:2*L];

wire [NBITS-1:0] qm_w[0:L-1];
wire [NBITS-1:0] qm[0:L-1];

wire [2*NBITS  :0]  z_w[0:L-1];
wire [  NBITS+1:0]  zm;
wire [  NBITS-1:0]  out_w;
wire [  NBITS-1:0]  out;

wire [ MUL_STAGE1+L*(MUL_STAGE2+1)+1:0] out_en;

wire [2*NBITS-W-1:0] t1h[0:L-1];
wire [W-1:0] t1l[0:L-1];
wire [W-1:0] t2[0:L-1];
wire         carry[0:L-1];
wire [2*NBITS-W  :0] t1hc_w[0:L-1];
wire [2*NBITS-W  :0] t1hc[0:L-1];

assign out_en[0] = enable_p;
assign m_input = {m[NBITS-1:W], {(W-1){1'b0}}, 1'b1};
generate
  for (i = 0; i < MUL_STAGE1+L*(MUL_STAGE2+1)+1; i = i+1) begin : yxn_even
    async_dff #(.SIZE(1)) u_en_dff (.D(out_en[i]), .CLK(clk), .ASYNC_RESET(rst_n), .Q(out_en[i+1])); 
  end
endgenerate

//---1 clock cycle--
mul #(.STAGE(MUL_STAGE1), .SIZE1(NBITS), .SIZE2(NBITS)) u_mul_0 (.clk(clk), .a(a), .b(b), .y(ab_w)); 
async_dff #(.SIZE(2*NBITS)) u_ab0_dff (.D(ab_w), .CLK(clk), .ASYNC_RESET(rst_n), .Q(ab[0]));

generate
  for(i=0;i<L;i=i+1) begin
  //---2 clock cycle---
  assign t1h[i] = ab[0+2*i][2*NBITS-1:W];
  assign t1l[i] = ab[0+2*i][W-1:0];
  add #(.NBITS(W)) u_add_pre (.a(~t1l[i]), .b({{(W-1){1'b0}}, 1'b1}), .cout(), .y(t2[i]));
  //assign t2[i] = ~t1l[i] + 1;
  assign carry[i] = t2[i][W-1] | t1l[i][W-1];
  mul #(.STAGE(MUL_STAGE2), .SIZE1(W), .SIZE2(NBITS-W)) u_mul_2 (.clk(clk), .a(t2[i]), .b(m_input[NBITS-1:W]), .y(qm_w[i]));
  add #(.NBITS(2*NBITS-W*(1+i))) u_add_0 (.a(t1h[i][2*NBITS-W*(1+i)-1:0]), .b({{(2*NBITS-1-W*(1+i)){1'b0}}, carry[i]}), .cout(t1hc_w[i][2*NBITS-W*(1+i)]), .y(t1hc_w[i][2*NBITS-W*(1+i)-1:0]));
//Check for different FF depth
//  add #(.NBITS(2*NBITS+1-W)) u_add_1 (.a({{(NBITS+1-W){1'b0}}, qm_w[i]}), .b(t1hc_w[i]), .cout(ab[1+2*i][2*NBITS+1-W]), .y(ab[1+2*i][2*NBITS-W:0]));
//  async_dff #(.SIZE(NBITS)) u_qm_dff (.D(qm_w[i]), .CLK(clk), .ASYNC_RESET(rst_n), .Q(qm[i])); 
//  async_dff #(.SIZE(2*NBITS-W+1)) u_t1hc_dff (.D(t1hc_w[i]), .CLK(clk), .ASYNC_RESET(rst_n), .Q(t1hc[i])); 
//  assign ab[1+2*i][2*NBITS-1:2*NBITS+2-W] = 'd0;
//  async_dff #(.SIZE(2*NBITS)) u_qm2_dff (.D({{(W-3){1'b0}}, ab[1+2*i][2*NBITS+2-W:0]}), .CLK(clk), .ASYNC_RESET(rst_n), .Q(ab[2+2*i])); 
// else
  async_dff #(.SIZE(NBITS)) u_qm_dff (.D(qm_w[i]), .CLK(clk), .ASYNC_RESET(rst_n), .Q(qm[i])); 
  async_dff #(.SIZE(2*NBITS-W*(1+i)+1), .STAGE(MUL_STAGE2)) u_t1hc_dff (.D(t1hc_w[i][2*NBITS-W*(1+i):0]), .CLK(clk), .ASYNC_RESET(rst_n), .Q(t1hc[i][2*NBITS-W*(1+i):0]));
  //---3 clock cycle---
  add #(.NBITS(2*NBITS+1-W*(1+i))) u_add_1 (.a({{(NBITS+1-W*(1+i)){1'b0}}, qm[i]}), .b(t1hc[i][2*NBITS-W*(1+i):0]), .cout(), .y(ab[1+2*i][2*NBITS-W*(1+i):0]));
  assign ab[1+2*i][2*NBITS-1:2*NBITS+1-W*(1+i)] = 'd0;
  async_dff #(.SIZE(2*NBITS-W*(1+i)+1)) u_qm2_dff (.D({ab[1+2*i][2*NBITS-W*(1+i):0]}), .CLK(clk), .ASYNC_RESET(rst_n), .Q(ab[2+2*i][2*NBITS-W*(1+i):0])); 
//
end
endgenerate
//  //---4 clock cycle--
//  mul #(.STAGE(MUL_STAGE2), .SIZE1(NBITS), .SIZE2(NBITS)) u_mul_4 (.a(ab[MUL_STAGE2+MUL_STAGE3][NBITS-1:0]), .b(m_inv), .y(q_w[1])); 
//  async_dff #(.SIZE(NBITS)) u_q4_dff (.D(q_w[1][NBITS-1:0]), .CLK(clk), .ASYNC_RESET(rst_n), .Q(q[1]));
//  generate
//  for(j=0;j<MUL_STAGE2;j=j+1) begin 
//  async_dff #(.SIZE(2*NBITS)) u_ab4_dff (.D(ab[0+MUL_STAGE2+MUL_STAGE3+j]), .CLK(clk), .ASYNC_RESET(rst_n), .Q(ab[1+MUL_STAGE2+MUL_STAGE3+j])); 
//  end
//  endgenerate
//  //---5 clock cycle--
//  mul #(.STAGE(MUL_STAGE3), .SIZE1(W), .SIZE2(NBITS)) u_mul_5 (.a(q[1]), .b(m), .y(qm_w[1])); 
//  generate
//  for(j=0;j<MUL_STAGE3-1;j=j+1) begin 
//  async_dff #(.SIZE(2*NBITS)) u_ab6_dff (.D(ab[2*MUL_STAGE2+MUL_STAGE3+j]), .CLK(clk), .ASYNC_RESET(rst_n), .Q(ab[1+2*MUL_STAGE2+MUL_STAGE3+j])); 
//  end
//  endgenerate
//  add #(.NBITS(2*NBITS)) u_add_5 (.a(ab[2*MUL_STAGE2+2*MUL_STAGE3-1]), .b(qm_w[1]), .cout(z_w[1][2*NBITS]), .y(z_w[1][2*NBITS-1:0]));
//  async_dff #(.SIZE(2*NBITS)) u_qm2_dff (.D({{(W-1){1'b0}}, z_w[1][2*NBITS:W]}), .CLK(clk), .ASYNC_RESET(rst_n), .Q(ab[2*MUL_STAGE2+2*MUL_STAGE3])); 
 
  //---6 clock cycle--
 
sub #(.NBITS(NBITS+1)) u_sub_0 (.a(ab[2*L][NBITS:0]), .b({1'b0, m_input}), .cout(zm[NBITS+1]), .y(zm[NBITS:0]));
mux2x1 #(.SIZE(NBITS)) u_zm_mux (.a(zm[NBITS-1:0]), .b(ab[2*L][NBITS-1:0]), .sel(zm[NBITS+1]), .out(out_w)); 
async_dff #(.SIZE(NBITS)) u_out_dff (.D(out_w), .CLK(clk), .ASYNC_RESET(rst_n), .Q(out)); 

assign y = out;
assign done_irq_p = out_en[MUL_STAGE1+L*(MUL_STAGE2+1)+1];

endmodule
