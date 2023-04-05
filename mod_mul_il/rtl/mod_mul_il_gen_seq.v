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

module mod_mul_il_gen #(
  parameter NBITS  = 4096,
  parameter PBITS  = 1

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

//localparam BSIZE  = PBITS*$ceil(NBITS/PBITS);      //If if NBITS not divisible by PBITS
//localparam PRED   = 4'b0;                          //0 = > sequential reducion, B => Parallel reduction, B-1 => 2 step reduction
//localparam ALSIZE = 1'b1 << PBITS;                 //LUT size
localparam MLSIZE = 1 << PBITS;

reg  [NBITS+PBITS   :0] a_loc;   //+PBITS to take care of when NBITS is non multiple of PBITS
reg  [NBITS+PBITS-1 :0] y_loc;
reg  [NBITS-1 :0]       y_loc_red;

reg  [NBITS-1 :0]       b_loc_red;
reg                     done_irq_p_loc;
reg                     done_irq_p_loc_d;

reg  [NBITS+PBITS   :0] y_loc_accum;

reg [NBITS+PBITS+1  :0]  yxn[0 : MLSIZE-1];

genvar  i;
integer j;

wire [NBITS+PBITS -1 :0]  mxn[0 : MLSIZE-1];
wire [NBITS       -1 :0]  bxn[0 : MLSIZE-1];

wire mxn_done;



//calculate (a*b)%m

always @* begin
  b_loc_red  = bxn[0];
  for (j=0; j<=MLSIZE; j=j+1) begin
    b_loc_red  = (a_loc[NBITS : NBITS-PBITS+1] == j) ? bxn[j] : b_loc_red;
  end
end

assign y_loc_accum = {y_loc, {PBITS{1'b0}}} + b_loc_red;

generate
  for (i = 0; i < MLSIZE; i = i+1) begin : yxn_even
    always @* begin
      yxn[i] = y_loc_accum - mxn[i];
    end
  end
endgenerate

always @* begin
  y_loc_red  = y_loc_accum;
  for (j=0; j<MLSIZE; j=j+1) begin
    y_loc_red  = yxn[j][PBITS+NBITS+1] ? y_loc_red : yxn[j];
  end
end


always @ (posedge clk or negedge rst_n) begin
  if (rst_n == 1'b0) begin
    y_loc <= {NBITS{1'b0}};
    a_loc <= {(NBITS+1){1'b0}};
  end
  else begin
    if (mxn_done == 1'b1) begin
      y_loc <= {NBITS{1'b0}};
      a_loc <= {a, 1'b1};
    end
    else if (|a_loc[NBITS-1 :0]) begin
      y_loc <= y_loc_red[NBITS-1 :0];
      a_loc <= {a_loc[NBITS-PBITS :0], {PBITS{1'b0}}};
    end 
  end
end


  
always @ (posedge clk or negedge rst_n) begin
  if (rst_n == 1'b0) begin
    done_irq_p_loc    <= 1'b0;
    done_irq_p_loc_d  <= 1'b0;
  end
  else begin
    done_irq_p_loc    <= |a_loc[NBITS-1 :0] | mxn_done;  //enable_p for the case a == 1
    done_irq_p_loc_d  <= done_irq_p_loc  ;
  end
end

  assign done_irq_p =  done_irq_p_loc_d & ~done_irq_p_loc;
  assign y          =  y_loc;
//mxn[0] = m; mxn[1] = m*2; mxn[2] = m*3 ; mxn[3] = m*4; mxn[4] = m*5;

mxn_calc #(
  .NBITS  (NBITS),
  .PBITS  (PBITS),
  .MLSIZE (MLSIZE)
 ) u_mxn_calc_inst (
  .clk          (clk),
  .rst_n        (rst_n),
  .enable_p     (enable_p),
  .m            (m),
  .b            (b),
  .mxn_done     (mxn_done),
  .mxn          (mxn),
  .bxn          (bxn)
);


endmodule
