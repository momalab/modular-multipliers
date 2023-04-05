`timescale 1 ns/1 ps
//----------------------------------------
//INPUT: X, Y,M with 0 ? X, Y ? M
//OUTPUT: P = X · Y mod M
//n: number of bits of X
//xi: ith bit of X
//1. P = 0;
//2. for (i = n - 1; i >= 0; i = i - 1){
//3. P = 2· P;
//4. I = xi · Y ;
//5. P = P + I;
//6. if (P >= M) P = P - M;
//7. if (P >= M) P = P - M; }
//----------------------------------------

module mod_mul_il_rad2 #(
  parameter NBITS = 4096,
  parameter PBITS = 2,
  parameter NBYP  = 2048    //NBITS/PBITS
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

reg  [NBITS-1 :0] a_loc;
reg  [NBITS-1 :0] y_loc;
reg  [NBITS-1 :0] b_loc_red_d;
reg               done_irq_p_loc;
reg               done_irq_p_loc_d;

wire [NBITS-1+PBITS  :0] y_loc_accum_pre;
wire [NBITS-1+PBITS  :0] y_loc_accum;
wire [NBITS-1+PBITS  :0] y_loc_accum_red_pre;
wire [NBITS-1+PBITS  :0] y_loc_accum_red;
wire [NBITS-1+PBITS  :0] b_loc;
wire [NBITS-1+PBITS  :0] b_loc_red_pre;

wire [NBITS-1 :0] y_loc_pre;
wire [NBITS-1 :0] b_loc_red;


//assign b_loc            =  enable_p ? {b, 2'b0} : {b_loc_red_d, 2'b0};
assign b_loc            = {b_loc_red_d, 2'b0};
assign b_loc_red_pre    = (b_loc > {m, 1'b0}) ? (b_loc - {m, 1'b0}) : b_loc;
assign b_loc_red        = (b_loc_red_pre > m) ? (b_loc_red_pre - m) : b_loc_red_pre;

//calculate (a*b)%m
//assign y_loc_pre        =  enable_p ? b : y_loc;
assign y_loc_accum_pre  =  a_loc[1] ? ({b_loc_red_d, 1'b0} + y_loc)   : y_loc;
assign y_loc_accum      =  a_loc[0] ? (b_loc_red_d + y_loc_accum_pre) : y_loc_accum_pre;

assign y_loc_accum_red_pre = (y_loc_accum > {m, 1'b0})    ? (y_loc_accum - {m, 1'b0})  : y_loc_accum;
assign y_loc_accum_red     = (y_loc_accum_red_pre >= m)   ? (y_loc_accum_red_pre -  m) : y_loc_accum_red_pre ;

always @ (posedge clk or negedge rst_n) begin
  if (rst_n == 1'b0) begin
    y_loc       <= {NBITS{1'b0}};
    a_loc       <= {NBITS{1'b0}};
  end
  else begin
    if (enable_p == 1'b1) begin
      a_loc <= a;
      y_loc <= {NBITS{1'b0}};
    end
    else if (|a_loc) begin
      y_loc <= y_loc_accum_red[NBITS-1 :0];
      a_loc <= {2'b0, a_loc[NBITS-1:2]};
    end 
  end
end


always @ (posedge clk or negedge rst_n) begin
  if (rst_n == 1'b0) begin
    b_loc_red_d <= {(NBITS){1'b0}};
  end
  else begin
    if (enable_p == 1'b1) begin
      b_loc_red_d <= b;
    end 
    else begin
      b_loc_red_d <= b_loc_red;
    end
  end
end



  
  always @ (posedge clk or negedge rst_n) begin
    if (rst_n == 1'b0) begin
      done_irq_p_loc    <= 1'b0;
      done_irq_p_loc_d  <= 1'b0;
    end
    else begin
      done_irq_p_loc    <= |a_loc | enable_p;  //enable_p for the case a == 1
      done_irq_p_loc_d  <= done_irq_p_loc  ;
    end
  end

  assign done_irq_p =  done_irq_p_loc_d & ~done_irq_p_loc;
  assign y          =  y_loc;



endmodule
