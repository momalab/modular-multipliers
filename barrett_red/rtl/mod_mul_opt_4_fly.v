`timescale 1 ns/1 ps
module mod_mul_opt_4_fly #(
  parameter NBITS = 128,
  parameter ZBITS = 13,
  parameter PBITS = 0

 ) (
  input               clk,
  input               rst_n,
  input               enable_p,
  input               nmul,
  input  [NBITS-1 :0] a,
  input  [NBITS-1 :0] b,
  input  [NBITS-1 :0] m,
  input  [NBITS   :0] md,
  input  [$clog2(NBITS)+1:0]     k,
  input  [$clog2(NBITS)  :0]     k_shft_ah,     // (k >> 1)  - 1
  input  [$clog2(NBITS)  :0]     k_shft_ahxmd,  // (k >> 1)  + 1
  output [NBITS-1 :0] y,
  output [2*NBITS-1 :0] y_nom_mul,
  output              done_irq_p,
  output              done_nom_mul
);

wire done_barret;

nom_mul_4_stage #(
  .NBITS (NBITS),
  .PBITS (0)
 ) u_nom_mul_inst  (
  .clk           (clk),          //input                 
  .rst_n         (rst_n),        //input                 
  .enable_p      (enable_p),     //input                 
  .a             (a),            //input  [NBITS-1 :0]   
  .b             (b),            //input  [NBITS-1 :0]   
  .y             (y_nom_mul),    //output [2*NBITS-1 :0] 
  .done          (done_nom_mul)      //output  reg           
);

barrett_red_opt_4_fly  #(
  .NBITS (NBITS),
  .LOG2POLYDEG (ZBITS),
  .PBITS (0)
 ) u_barrett_red_inst (
  .clk           (clk),                      //input                   
  .rst_n         (rst_n),                    //input                   
  .enable_p      (~nmul & done_nom_mul),     //input                   
  .a             (y_nom_mul),                //input  [2*NBITS-1 :0]   
  .m             (m),                        //input  [NBITS-1 :0]     
  .k             (k),                        //input  [NBITS+15:0]     
  .k_shft_ah     (k_shft_ah),                        //input  [NBITS+15:0]     
  .k_shft_ahxmd  (k_shft_ahxmd),                        //input  [NBITS+15:0]     
  .md            (md),                       //input  [7:0]            
  .done          (done_barret),               //output reg              
  .y             (y)                         //)                          //output reg [NBITS-1 :0] 
);

mux2x1 #(.SIZE(1)) u_mux2x1 (.sel(nmul), .a(done_barret), .b(done_nom_mul), .out(done_irq_p));
//assign done_irq_p = nmul ? done_nom_mul : done_barret;



endmodule
