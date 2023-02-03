`timescale 1 ns/1 ps

import "DPI" function string getenv_c(string name);


//`define NUMBITS     getenv_c("NBITS")
//`define PBITS       getenv_c("PBITS")
//`define DUTNAME     getenv_c("DESIGN")
//`define DUTNAME     mod_mul_il


module montgomery_mul_tb (
);

//`define NUMBITS     4096
//`define PBITS       8
//`define NUMBITS     4096
//`define DUTNAME     mod_mul_il_v3
//`define DUTNAME     mod_mul_il_v1
//`define DUTNAME     mod_mul_il_gen
//`define DUTNAME     mod_mul_il_rad2_v3
//`define DUTINSTNAME u_dut_inst
//`define VCD_NAME    u_dut_inst
//---------------------------------
//Local param reg/wire declaration
//---------------------------------

localparam  CLK_PERIOD   = 10;   //24 Mhz
//localparam  CLK_PERIOD   = `CLKPERIOD;   //24 Mhz

localparam  MUL_STAGE1   = `MUL_STAGE1;
localparam  MUL_STAGE2   = `MUL_STAGE2;
localparam  MUL_STAGE3   = `MUL_STAGE3;
//localparam  W            = `W;
localparam  NBITS        = `NUMBITS;
localparam  PBITS        = `PBITS;
localparam  L            = 2;

//localparam  NBITS    = 4096;
//$display ("KeyIter %h KeyIter",m);
//string  num_key_string   =  getenv_c("NUMKEY"); 
//int     num_key          =  num_key_string.atoi();



reg              CLK; 
reg              nRESET; 
reg [NBITS-1 :0] a; 
reg [NBITS-1 :0] b; 
reg [NBITS-1 :0] arga; 
reg [NBITS-1 :0] argb; 
reg [NBITS-1 :0] m; 
reg [$clog2(NBITS)+2 :0] m_size; 
reg              enable_p; 

wire [NBITS-1 :0] y; 
wire              done_irq_p; 

parameter W = NBITS/2; 

reg signed [NBITS-1 :0] x1; 
reg signed [NBITS-1 :0] y1; 
reg [NBITS-1 :0] p1; 
reg [NBITS-1 :0] q1; 
reg [NBITS-1 :0] g; 
reg [NBITS-1 :0] m_inv; 
reg [2*NBITS-1 :0] m_precalc; 
reg [NBITS-1 :0] R_1; 

reg [2*NBITS:0] r2_red;
reg [2*NBITS:0] r_red;

reg [3*NBITS-1 :0] temp_reg1; 
reg [3*NBITS-1 :0] temp_reg2; 
reg [2*NBITS-1 :0] temp_reg3; 

integer no_of_clocks; 
integer no_of_iter; 
integer i;

`ifdef NUMTRACE
//string  num_trace_string =  `NUMTRACE;
int     num_trace        =  `NUMTRACE;
reg [NBITS-1:0] ref_out[0:10-1];
reg [NBITS-1:0] cal_out[0:10-1];
reg [NBITS-1:0] a_in[0:10-1];
reg [NBITS-1:0] b_in[0:10-1];
//int     num_trace        =  num_trace_string.atoi();
`endif

`ifndef NUMTRACE
int     num_trace        = 10;
reg [NBITS-1:0] ref_out[0:10-1];
reg [NBITS-1:0] cal_out[0:10-1];
reg [NBITS-1:0] a_in[0:10-1];
reg [NBITS-1:0] b_in[0:10-1];
`endif

reg [31:0] out_idx;
reg [31:0] out_idx2;
reg [31:0] iteration;

//reg [NBITS-1:0] p;
//reg [NBITS-1:0] q;
reg [NBITS  :0] m2;

reg [NBITS-1:0] gcd;

`include "./montgomery_mul_tasks.v"
//------------------------------
//Clock and Reset generation
//------------------------------

initial begin
  CLK      = 1'b0; 
end

always @(posedge CLK) begin
   if(done_irq_p) begin
        cal_out[out_idx2%10] = y[NBITS-1:0];
        out_idx2 = out_idx2+1;
   end
end


always begin
  #(CLK_PERIOD/2) CLK = ~CLK; 
end



initial begin
   nRESET   = 1'b1;
   enable_p = 1'b0;
   out_idx = 'd0;
   out_idx2 = 'd0;
   iteration = num_trace;
   $display("Num of trace in testbench = ", num_trace);
   m        = {NBITS{1'd0}};
   a        = {NBITS{1'd0}};
   b        = {NBITS{1'd0}};
  repeat (2) begin
    @(posedge CLK);
  end
   nRESET    = 1'b0;

  repeat (2) begin
    @(posedge CLK);
  end
    @(negedge CLK);
  nRESET   = 1'b1;

  repeat (2) begin
    @(posedge CLK);
  end
  //$dumpfile(`VCD_NAME);
  //$dumpfile("abcd.vcd");
  //$dumpvars(0,`DUTNAME);
  #1
  m        = {NBITS{1'b1}};
  //m[W-1:0] = 'd1;
  arga     = m - 1;
  argb     = m - 3;
  //arga     = 1;
  //argb     = 3;
  //m = 7;
  m_size     = (NBITS == W*(L)) ? NBITS : W*(L+1);
  $display("m_size = ", m_size);
  r2_red = (1 << 2*m_size) % m;
  r_red  = (1 << m_size) % m;
  mont_precalc((1<< (W))%m, m, m_precalc);
  repeat (num_trace) begin
      $display($time, " modulus size = %d, m = %d", m_size, m);
      modmul (.arga (arga),.argb (argb));
      sequencer();
      r2_red = (1 << 2*m_size) % m;
      r_red  = (1 << m_size) % m;
      mont_precalc(((1 << (W))%m), m, m_precalc);
  end
  wait(out_idx == out_idx2);
//  for(i=0;i<num_trace;i=i+1) begin
//     if(ref_out[i] == cal_out[i]) begin
//      $display(" #------------------MONTGOMERY PASSED---------------------*");
//      $display(" << ARG A | ARG B | MODULUS M | R_1 | R \n << %d | %d | %d | %d | %d ", a_in[i], b_in[i], m, R_1, r_red);
//      $display(" << Expected Result2 | Calculated Result\n << %d | %d", ref_out[i], cal_out[i]);
//     end else begin
//        $display(" #------------------MONTGOMERY FAILED---------------------*");
//        $display(" << ARG A | ARG B | MODULUS M | R_1 | R \n << %d | %d | %d | %d | %d ", a_in[i], b_in[i], m, R_1, r_red);
//        $display(" << Expected Result2 | Calculated Result\n << %d | %d", ref_out[i], cal_out[i]);  
//     end 
//  end
  $finish; 
end


//------------------------------
//DUT
//------------------------------
`ifdef TC_MODULAR_MUL
montgomery_wrap #(
  .NBITS (NBITS),
  .PBITS (PBITS)
 ) u_dut_inst   (
  .clk           (CLK),
  .rst_n         (nRESET),
  .enable_p      (enable_p),
  .a             (arga),
  .b             (argb),
  .m             (m),
  .m_size        (m_size),
  .r_red         (r2_red[NBITS-1:0]),
  .y             (y),
  .done_irq_p    (done_irq_p)
);
`elsif TC_MONTGOMERY_MUL 
`DUTNAME #(
  .MUL_STAGE1 (MUL_STAGE1),
  .MUL_STAGE2 (MUL_STAGE2),
  .MUL_STAGE3 (MUL_STAGE3),
  .NBITS (NBITS),
  .PBITS (PBITS)
) `DUTNAME  (
  .clk           (CLK),
  .rst_n         (nRESET),
  .enable_p      (enable_p),
  .a             (arga),
  .b             (argb),
  .m             (m),
  .m_inv         (m_precalc ),
  .y             (y),
  .done_irq_p    (done_irq_p)
);
`endif

//------------------------------
//Track number of clocks
//------------------------------
initial begin
  no_of_clocks = 0; 
end
always@(posedge CLK)  begin
  no_of_clocks = no_of_clocks +1 ; 
  //$display($time, " << Number of Clocks value         %d", no_of_clocks);
  //$display($time, " << htrans_m[0] value              %b", ccs0001_tb.u_dut_inst.u_chip_core_inst.u_ahb_ic_inst.htrans_m[0][1]);
  //$display($time, " << vlaid_trans_s_by_m[s][0] value %b", ccs0001_tb.u_dut_inst.u_chip_core_inst.u_ahb_ic_inst.vlaid_trans_s_by_m[0][0]);
  //$display($time, " << vlaid_trans_s_by_m[s][1] value %b", ccs0001_tb.u_dut_inst.u_chip_core_inst.u_ahb_ic_inst.vlaid_trans_s_by_m[1][0]);
  //$display($time, " << SLAVE_BASE[0] value            %h", ccs0001_tb.u_dut_inst.u_chip_core_inst.u_ahb_ic_inst.SLAVE_BASE[0][31:16]);
  //$display($time, " << SLAVE_BASE[1] value            %h", ccs0001_tb.u_dut_inst.u_chip_core_inst.u_ahb_ic_inst.SLAVE_BASE[1][31:16]);
  //$display($time, " << haddr_m[0]  value              %h", ccs0001_tb.u_dut_inst.u_chip_core_inst.u_ahb_ic_inst.haddr_m[0][31:16]);
  //$display($time, " << memory dump              %h", ccs0001_tb.u_dut_inst.u_chip_core_inst.u_sram_wrap_inst.u_sram_inst.mem[0]);
end

endmodule
