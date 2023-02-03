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
  parameter NBITS = 2048,
  parameter PBITS = 1
 ) (
  input               clk,
  input               rst_n,
  input               enable_p,
  input  [NBITS-1 :0] a,
  input  [NBITS-1 :0] b,
  input  [NBITS-1 :0] m,
  input  [$clog2(NBITS) :0] m_size,
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
reg  [NBITS-1 :0]       b_loc_red_2;
reg                     done_irq_p_loc;
reg                     done_irq_p_loc_d;

reg  [NBITS+PBITS   :0] y_loc_accum;

reg [NBITS+PBITS+1  :0]  yxn[0 : MLSIZE-1];

genvar  i;
integer j;

wire [NBITS+PBITS -1 :0]  mxn[0 : MLSIZE-1];
wire [NBITS+PBITS -1 :0]  bxn[1 : MLSIZE-1];
reg [NBITS*MLSIZE       -1 :0]  bxn_all;
wire [NBITS-1 :0] y_1;

wire mxn_done;
wire yxn_done_1;

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

y_calc #(
  .NBITS  (NBITS),
  .PBITS  (PBITS),
  .MLSIZE (MLSIZE)
 ) u_yxn_calc_1_inst (
  .clk          (clk),
  .rst_n        (rst_n),
  .enable_p     (mxn_done),
//  .y_acc        ('d0),
  .a            (a),
  .bxn          (bxn),
  .mxn          (mxn),
  .m            (m  ),
  .m_size       (m_size),
  .y            (y),
  .done_irq_p   (done_irq_p)
);

endmodule
