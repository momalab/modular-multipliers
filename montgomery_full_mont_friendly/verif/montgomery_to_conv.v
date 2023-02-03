
module montgomery_to_conv #(
  parameter NBITS = 2048,
  parameter PBITS = 1
 ) (
  input               clk,
  input               rst_n,
  input               enable_p,
  input  [NBITS-1 :0] a,
  input  [NBITS-1 :0] m,
  input  [NBITS-1 :0] r_red,
  input  [$clog2(NBITS)+2 :0] m_size,
  output [NBITS-1 :0] y,
  output              done_irq_p
);

montgomery_mul #(
  .NBITS (NBITS),
  .PBITS (PBITS)
 ) u_montgomery_mul_inst (
  .clk               (clk),             //input               
  .rst_n             (rst_n),           //input               
  .enable_p          (enable_p),        //input               
  .a                 (a),               //input  [NBITS-1 :0] 
  .b                 (r_red  ),         //input  [NBITS-1 :0] 
  .m                 (m),               //input  [NBITS-1 :0] 
  .m_size            (m_size),          //input  [10      :0] 
  .y                 (y),               //output [NBITS-1 :0] 
  .done_irq_p        (done_irq_p)       //output              
);

// mod_mul_il #(
//  .NBITS (NBITS)
// ) u_mod_mul_il_inst (
//  .clk               (clk),                    //input               
//  .rst_n             (rst_n),                  //input               
//  .enable_p          (enable_p),               //input               
//  .a                 (a),                      //input  [NBITS-1 :0] 
//  .b                 (r_red),                  //input  [NBITS-1 :0] 
//  .m                 (m),                      //input  [NBITS-1 :0] 
//  .y                 (y),                      //output [NBITS-1 :0] 
//  .done_irq_p        (done_irq_p)              //output              
//);

endmodule
