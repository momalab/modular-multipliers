//---------------------------------------------------
//Barrett Reduction:
// For modulus Size n bits
// a = x*y;  //2n bits
//High level idea is : a mod m = a - m * floor(a/m) 
//Approximate 1/m to md/2^k ; k = 2*ceil(log2 modulus) =  2*n
// md is n+1 bits
// a mod m = a       - m      * (a*md/2^k)
//Algo 1
//         = a       - m      * (ah*2^(n-1)     + al)*md/2^2*n
//         = a       - m      * (ah*2^(n-1)     + al)*md/2^2*n
//         = a       - m      * (ah*md/2^(n+1)  + al*md/2^2*n)
//         = 2n bits - n bits * (n+1 bits       + 0 bit)
//         = a       - m      * (ah*md/2^(n+1))
//         = a       - m      * Q
//         For modulus m = 1 mod 2*N ; N is degree of polynomial
//         Q can be written as (mh*2^(log 2*N) + 1)*Q
//---------------------------------------------------
//Algo 2
//         = a       - m      * (ah*2^(n)       + al)*md/2^2*n
//         = a       - m      * (ah*2^(n)       + al)*md/2^2*n
//         = a       - m      * (ah*md/2^(n)    + al*md/2^2*n)
//         = 2n bits - n bits * (n+1 bits       + 1 bit)
//         = a       - m      * (ah*md/2^(n)    + al*md/2^2*n)
//---------------------------------------------------

module barrett_red_opt_4_fly  #(
  parameter NBITS       = 128,
  parameter LOG2POLYDEG = 13,
  parameter PBITS       = 0

 ) (
  input                          clk,
  input                          rst_n,
  input                          enable_p,
  input  [2*NBITS-1 :0]          a,
  input  [NBITS-1 :0]            m,
  input  [$clog2(NBITS)+1:0]     k,
  input  [$clog2(NBITS)  :0]     k_shft_ah,     // (k >> 1)  - 1
  input  [$clog2(NBITS)  :0]     k_shft_ahxmd,  // (k >> 1)  + 1
  input  [NBITS:0]               md,
  input  [NBITS+1 :0]            mx3,
  output reg                     done,
  output  [NBITS-1 :0]           y
);

reg [NBITS-1 :0]        y_w;

wire [NBITS-1        :0] m_loc;

wire [2*NBITS-1          :0] ah;

wire [2*NBITS+1   :0]  ahxmd;

reg  [2*NBITS+1 :0]       ahxmd_shftd;

wire done_nom_mul1;
wire done_nom_mul2;

reg done_nom_mul2_d;

wire [2*NBITS :0]     y_red_w;
reg  [NBITS+1 :0]     y_red;
reg  [NBITS+2 :0]     y_red_sub_m;
reg  [NBITS+3 :0]     y_red_sub_mx2;


//assign ah     = a >> k_shft_ah;
left_shift #(.SIZE(2*NBITS)) u_left_shift_2 (.in(a), .sbits(k_shft_ah), .out(ah));
//always @(*) begin
//    if(k_shft_ah <= LOG2POLYDEG) begin
//           ah     = a >> NBITS-1;
//    end else if(k_shft_ah < NBITS) begin
//           ah     = a >> k_shft_ah;
//    end else begin
//           ah     = a >> NBITS-1;
//    end
//end

assign m_loc  = {m[NBITS-1 : LOG2POLYDEG+1], {(LOG2POLYDEG){1'b0}}, 1'b1};

nom_mul_4_stage #(
  .NBITS (NBITS+1),
  .PBITS (PBITS)) u_mul1_inst (
   .clk           (clk),          //input                 
   .rst_n         (rst_n),        //input                 
   .enable_p      (enable_p),     //input                 
   .a             (ah[NBITS:0]),
   .b             (md),
   .y             (ahxmd),
   .done          (done_nom_mul1)      //output  reg           
);


localparam ALOCDEPTH = 6;
wire [2*NBITS-1   :0]  a_loc[ALOCDEPTH-1:0];
reg  [2*NBITS-1   :0]  a_loc_w[ALOCDEPTH-1:0];

mux2x1 #(.SIZE(2*NBITS)) u_mux2x1 (.sel(enable_p), .a(a_loc[0]), .b(a), .out(a_loc_w[0]));
//always @ (*) begin
//    if (enable_p == 1'b1) begin
//      a_loc_w[0] = a;
//    end else begin 
//      a_loc_w[0] = a_loc[0];
//    end
//end
async_dff #(.SIZE(NBITS*2)) u_a_loc_dff (.D(a_loc_w[0]), .CLK(clk), .ASYNC_RESET(rst_n), .Q(a_loc[0]));

genvar i;
generate 
  for (i=1; i < ALOCDEPTH; i=i+1) begin
       async_dff #(.SIZE(NBITS*2)) u_a_loc_d_dff (.D(a_loc[i-1]), .CLK(clk), .ASYNC_RESET(rst_n), .Q(a_loc[i]));
  end
endgenerate



//bit size of y_loc       = 3*NBITS
//bit size of ahxmd_shftd = 2*NBITS

left_shift #(.SIZE(2*NBITS+2)) u_left_shift_1 (.in(ahxmd), .sbits({1'b0, k_shft_ahxmd}), .out(ahxmd_shftd));
//assign  ahxmd_shftd = ahxmd >> k_shft_ahxmd;
//always @(*) begin
//    if(k_shft_ahxmd <= LOG2POLYDEG) begin
//           ahxmd_shftd     = ahxmd >> NBITS+1;
//    end else if(k_shft_ahxmd <= NBITS+1) begin
//           ahxmd_shftd     = ahxmd >> k_shft_ahxmd;
//    end else begin
//           ahxmd_shftd     = ahxmd >> NBITS+1;
//    end
//end

wire [2*NBITS :0]  shftdXm;
nom_mul_4_stage #(
  .NBITS ((1 + NBITS)),
  .PBITS (PBITS)) u_mul2_inst (
   .clk           (clk),          //input                 
   .rst_n         (rst_n),        //input                 
   .enable_p      (done_nom_mul1),  //input                 
   .a             (ahxmd_shftd[NBITS:0]),
   .b             ({1'b0, m_loc}),
   .y             ({UNCONNECTED1,shftdXm}),
   .done          (done_nom_mul2)      //output  reg           
);




//always @ (posedge clk or negedge rst_n) begin
//  if (rst_n == 1'b0) begin
//    y_red <= {2*NBITS{1'b0}};
//  end
//  else if (done_nom_mul2 == 1'b1) begin
//    y_red <= a_loc[ALOCDEPTH-1] - shftdXm;
//  end
//end
sub #(.NBITS(NBITS*2+1)) u_y_red_w_sub (.a({1'b0, a_loc[ALOCDEPTH-1]}), .b(shftdXm), .cout(), .y(y_red_w));
async_dff #(.SIZE(NBITS+2)) u_y_red_dff (.D(y_red_w[NBITS+1:0]), .CLK(clk), .ASYNC_RESET(rst_n), .Q(y_red));

//always @ (posedge clk or negedge rst_n) begin
//  if (rst_n == 1'b0) begin
//    done        <= 1'b0;
//  end
//  else begin
//    done_nom_mul2_d <= done_nom_mul2;
//    done            <= done_nom_mul2_d;
//  end
//end
async_dff #(.SIZE(1)) u_done_dff (.D(done_nom_mul2), .CLK(clk), .ASYNC_RESET(rst_n), .Q(done_nom_mul2_d));
async_dff #(.SIZE(1)) u_done2_dff (.D(done_nom_mul2_d), .CLK(clk), .ASYNC_RESET(rst_n), .Q(done));


//assign y_red_sub_m    = y_red - m_loc;
//assign y_red_sub_mx2  = y_red - {m_loc, 1'b0};
sub #(.NBITS(NBITS+3)) u_y_red_sub (.a({1'b0, y_red}), .b({1'b0, 1'b0, 1'b0, m_loc}), .cout(), .y(y_red_sub_m));
sub #(.NBITS(NBITS+4)) u_y_red2_sub (.a({1'b0, 1'b0, y_red}), .b({1'b0, 1'b0, 1'b0, m_loc, 1'b0}), .cout(), .y(y_red_sub_mx2));

y_mux #(.NBITS(NBITS)) u_y_mux (.done_nom_mul2_d(done_nom_mul2_d), .y(y), .y_red(y_red), .y_red_sub_m(y_red_sub_m), .y_red_sub_mx2(y_red_sub_mx2), .y_w(y_w));
//always @ (*) begin
//  if (done_nom_mul2_d == 1'b1) begin
//    if (y_red_sub_m[NBITS+2] == 1'b1) begin
//      y_w = y_red;
//    end
//    else if (y_red_sub_mx2[NBITS+3] == 1'b1) begin
//      y_w = y_red_sub_m;
//    end
//    else begin
//      y_w = y_red_sub_mx2;
//    end
//  end else begin
//    y_w = y;
//  end
//end

async_dff #(.SIZE(NBITS)) u_y_dff (.D(y_w), .CLK(clk), .ASYNC_RESET(rst_n), .Q(y));


endmodule
