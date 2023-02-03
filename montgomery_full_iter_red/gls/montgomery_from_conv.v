module montgomery_from_conv #(
  parameter NBITS = 2048,
  parameter PBITS = 1
 ) (
  input               clk,
  input               rst_n,
  input               enable_p,
  input  [NBITS-1 :0] a,
  input  [NBITS-1 :0] m,
  input  [NBITS-1 :0] m_inv,
  output [NBITS-1 :0] y,
  output              done_irq_p
);

`DUTNAME `DUTNAME
  (
  .clk               (clk),             //input               
  .rst_n             (rst_n),           //input               
  .enable_p          (enable_p),        //input               
  .a                 (a),               //input  [NBITS-1 :0] 
  .b                 (2048'b1),         //input  [NBITS-1 :0] 
  .m                 (m),               //input  [NBITS-1 :0] 
  .m_inv            (m_inv),          //input  [10      :0] 
  .y                 (y),               //output [NBITS-1 :0] 
  .done_irq_p        (done_irq_p)       //output              
);



endmodule
