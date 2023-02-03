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

module y_calc #(
  parameter NBITS = 2048,
  parameter PBITS = 1,
  parameter MLSIZE = 1 << PBITS
 ) (
  input               clk,
  input               rst_n,
  input               enable_p,
  input  [NBITS-1 :0] a,
  input  [NBITS+PBITS-1 :0] bxn [1:MLSIZE-1],
  input  [NBITS+PBITS-1 :0] mxn [0:MLSIZE-1],
  input  [NBITS      -1 :0] m               ,
  input  [$clog2(NBITS) :0] m_size,
  output [NBITS-1 :0] y,
  output              done_irq_p
);


//--------------------------------------
//reg/wire declaration
//--------------------------------------
reg [NBITS+PBITS-1 :0] y_loc_w;
reg [NBITS-1 :0] a_loc_w;
reg [11      :0] m_size_cnt_w;

reg [NBITS+PBITS-1 :0] y_loc;
wire [NBITS+PBITS :0] bxn_add;
reg [NBITS-1 :0] a_loc;
reg              done_irq_p_loc;
reg              done_irq_p_loc_d;
reg [11      :0] m_size_cnt;

wire             module_en;
wire             module_en_d;

reg [NBITS+PBITS-1   :0]  bxn_2[0 : MLSIZE-1];
wire [PBITS-1:0] a_loc_sel;
wire [PBITS-1:0] b_loc_sel;
wire [NBITS+PBITS-1:0] b_loc_red_2;
wire [PBITS-1:0] zero_value;

wire [NBITS+PBITS-1:0] mxn_sel;
wire [NBITS+PBITS :0] y_loc_red;
wire [NBITS+PBITS :0] b_loc_mul_a_loc_i ;
wire [NBITS+PBITS+1 :0] b_loc_mul_a_loc ;
wire [NBITS+PBITS+1 :0] y_loc_for_red ;
//--------------------------------------
//a*b*(2^-n) mod m
//--------------------------------------
integer j;

always @* begin
  bxn_2[0] = 'd0;
  for (j=1; j<MLSIZE; j=j+1) begin
     bxn_2[j] = bxn[j];
  end
end

assign a_loc_sel = a_loc[PBITS-1:0];
assign b_loc_sel = b_loc_mul_a_loc_i[PBITS-1:0];
//assign mxn_sel   =  |m_size_cnt[11:1] ? mxn[b_loc_sel] : mxn[b_loc_sel[0]];
assign mxn_sel   =  |m_size_cnt[11:1] ? mxn[b_loc_sel] : (m[1] ? mxn[{{(PBITS-1){1'b0}}, b_loc_sel[0]}] : mxn[{b_loc_sel[0], b_loc_sel[0]}]);
assign zero_value= y_loc_for_red[PBITS-1:0];
mux #(.NBITS(NBITS+PBITS), .PBITS(PBITS)) u_bxn_mux (.in(bxn_2), .sel(a_loc_sel), .out(b_loc_red_2)); 
add #(.NBITS(NBITS+PBITS)) u_add_1 (.a(y_loc), .b(b_loc_red_2), .cout(bxn_add[NBITS+PBITS]), .y(bxn_add[NBITS+PBITS-1:0])); 
//assign b_loc_mul_a_loc = b_loc_mul_a_loc_i + mxn[0];
//assign bxn_add = bxn[1] + y_loc;
//mux2x1 #(.SIZE(NBITS+PBITS+1)) u_bloc_mux (.b(bxn_add), .a({1'b0, y_loc}), .sel(|a_loc_sel), .out(b_loc_mul_a_loc_i));
assign b_loc_mul_a_loc_i = bxn_add; 
add #(.NBITS(NBITS+PBITS+1)) u_add_0 (.a(b_loc_mul_a_loc_i), .b({{1'b0}, mxn_sel}), .cout(b_loc_mul_a_loc[NBITS+PBITS+1]), .y(b_loc_mul_a_loc[NBITS+PBITS:0])); 
//assign b_loc_mul_a_loc_i    = a_loc[0] ? (b + y_loc) : y_loc;
//mux2x1 #(.SIZE(NBITS+2)) u_yloc_mux (.a(b_loc_mul_a_loc_i), .b(b_loc_mul_a_loc), .sel(b_loc_mul_a_loc_i[0]), .out(y_loc_for_red)); 
//assign y_loc_for_red        = (b_loc_sel != 'd0) ? (b_loc_mul_a_loc ) : b_loc_mul_a_loc_i;
assign y_loc_for_red = b_loc_mul_a_loc;

sub #(.NBITS(NBITS+PBITS)) u_sub (.a(y_loc[NBITS+PBITS-1:0]), .b({{(PBITS){1'b0}}, m}), .cout(y_loc_red[NBITS+PBITS]), .y(y_loc_red[NBITS+PBITS-1:0])); 
//assign y_loc_red = y_loc - m;

always @ (*) begin
    if (enable_p == 1'b1) begin
      a_loc_w          = a;
      y_loc_w          = {(NBITS+PBITS){1'b0}};
    end
    else if (|m_size_cnt[11:1]) begin
      y_loc_w = {y_loc_for_red[NBITS+PBITS+1 :PBITS]};
      a_loc_w = {{(PBITS){1'b0}}, a_loc[NBITS-1 :PBITS]};
    end 
    else if (|m_size_cnt[11:0]) begin
      y_loc_w = {y_loc_for_red[NBITS+PBITS :PBITS-1]};
      a_loc_w = {1'b0, a_loc[NBITS-1 :PBITS-1]};
    end 
    else begin
      if (y_loc_red[NBITS+PBITS] == 1'b0) begin
        y_loc_w = y_loc_red[NBITS+PBITS-1:0];
        a_loc_w = {{(PBITS){1'b0}}, a_loc[NBITS-1 :PBITS-1]};
      end
      else begin
        y_loc_w = y_loc;
        a_loc_w = {{(PBITS){1'b0}}, a_loc[NBITS-1 :PBITS-1]};
      end
    end
end
async_dff #(.SIZE(NBITS+PBITS)) u_y_loc_dff (.D(y_loc_w), .CLK(clk), .ASYNC_RESET(rst_n), .Q(y_loc));  
async_dff #(.SIZE(NBITS)) u_a_loc_dff (.D(a_loc_w), .CLK(clk), .ASYNC_RESET(rst_n), .Q(a_loc));  
async_dff #(.SIZE(1)) u_module_en_dff (.D(|m_size_cnt[11:0]), .CLK(clk), .ASYNC_RESET(rst_n), .Q(module_en));  
async_dff #(.SIZE(1)) u_module_en_d_dff (.D(module_en), .CLK(clk), .ASYNC_RESET(rst_n), .Q(module_en_d));  

always @ (*) begin
    if (enable_p == 1'b1) begin
      m_size_cnt_w    = m_size;
    end
    else if (|m_size_cnt[11:0]) begin
      if(m_size_cnt < PBITS) begin
         m_size_cnt_w = 'd0;
      end else begin
         m_size_cnt_w    = m_size_cnt-PBITS;//(Ex for 2048 bits, one need to count form 0 to 2047)
      end
    end else begin
         m_size_cnt_w = m_size_cnt;
    end
end

async_dff #(.SIZE(12)) u_m_size_cnt_dff (.D(m_size_cnt_w), .CLK(clk), .ASYNC_RESET(rst_n), .Q(m_size_cnt));  

//always @ (posedge clk or negedge rst_n) begin
//  if (rst_n == 1'b0) begin
//    done_irq_p_loc_d  <= 1'b0;
//  end
//  else begin
//    done_irq_p_loc_d  <= done_irq_p_loc  ;
//  end
//end

async_dff #(.SIZE(1)) u_p_loc_d_dff (.D(done_irq_p_loc), .CLK(clk), .ASYNC_RESET(rst_n), .Q(done_irq_p_loc_d));  

//assign done_irq_p =  done_irq_p_loc & ~done_irq_p_loc_d;
assign done_irq_p =  ~module_en & module_en_d;
assign y          =  y_loc[NBITS-1 :0];

endmodule
 
