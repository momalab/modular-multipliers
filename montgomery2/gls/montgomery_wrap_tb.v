`timescale 1 ns/1 ps

`include "montgomery_wrap.v"
`include "montgomery_to_conv.v"
`include "montgomery_from_conv.v"

module montgomery_wrap_tb (
);

//---------------------------------
//Local param reg/wire declaration
//---------------------------------

localparam  CLK_PERIOD   = 4.167;   //24 Mhz

localparam  NBITS        = `NUMBITS;
localparam  PBITS        = `PBITS;
//localparam  NBITS    = 2048;


reg              CLK; 
reg              nRESET; 
reg [NBITS-1 :0] a; 
reg [NBITS-1 :0] b; 
reg [NBITS-1 :0] arga; 
reg [NBITS-1 :0] argb; 
reg [NBITS-1 :0] m; 
reg [10      :0] m_size; 
reg [2*(NBITS+1) :0] r_red; 
reg              enable_p; 

wire [NBITS-1 :0] y; 
wire              done_irq_p; 


reg [2*NBITS-1 :0] temp_reg1; 
reg [2*NBITS-1 :0] temp_reg2; 
reg [2*NBITS-1 :0] temp_reg3; 

integer no_of_clocks;

reg [NBITS-1 : 0] j; 

reg [NBITS  :0] m2;

reg [NBITS-1:0] p1;
reg [NBITS-1:0] q1;
reg [NBITS-1:0] gcd;

`ifdef NUMTRACE
//string  num_trace_string =  `NUMTRACE;
int     num_trace        =  `NUMTRACE;
//int     num_trace        =  num_trace_string.atoi();
`endif

`ifndef NUMTRACE
int     num_trace        = 10;
`endif
reg [31:0] iteration;


`include "./montgomery_mul_tasks.v"
//------------------------------
//Clock and Reset generation
//------------------------------

initial begin
  CLK      = 1'b0; 
end

always begin
  #(CLK_PERIOD/2) CLK = ~CLK; 
end



initial begin
   nRESET   = 1'b1;
   enable_p = 1'b0;
   iteration = num_trace; 
   m        = 2048'd0;
   a        = 2048'd0;
   b        = 2048'd0;
   m_size   = 11'd2047;
   r_red    = 2048'd0;
  repeat (2) begin
    @(posedge CLK);
  end
   nRESET    = 1'b0;

  repeat (2) begin
    @(posedge CLK);
  end
  //$dumpfile("abcd.vcd");
  $dumpfile(`VCD_NAME);
  $dumpvars(0,u_dut_inst.`DUTNAME);
  //$dumpvars(0,u_dut_inst.u_montgomery_to_conv_a_inst.`DUTNAME);
  //$dumpvars(0,u_dut_inst.u_montgomery_to_conv_b_inst.`DUTNAME);
  //$dumpvars(0,u_dut_inst.u_montgomery_from_conv.`DUTNAME);
  #1
  nRESET   = 1'b1;
  m        = 2048'd72639;
  a        = 2048'd5792;
  b        = 2048'd1229;
  //m_size   = 11'd0; //Variable size m_size does not work.
  //for(j=m;j>0;j=j/2) begin
  //  m_size = m_size + 1;
  //end
  m_size = NBITS-1;
  r_red    = (1 << 2*(m_size)) % m;
  //arga     = a;
  //argb     = b;
  m = 124215;
  arga = 74237%m;
  argb = 2998%m;
  r_red    = (1 << 2*(m_size)) % m;
  repeat (num_trace) begin
      $display($time, " modulus size = %d, m = %d", m_size, m);
      modmul (.arga (arga),.argb (argb));
      assert(std::randomize(arga));
      assert(std::randomize(argb));
      assert(std::randomize(m));
      iteration = iteration - 1;
      m[NBITS-1] = m[NBITS-1] | iteration[1];
      m[NBITS-2] = m[NBITS-2] | iteration[0];
      m = m %(1<<(NBITS-1));
      m[0]       = 1'b1;
      //m_size   = 11'd0; //Variable size m_size does not work.
      //for(j=m;j>0;j=j/2) begin
      //  m_size = m_size + 1;
      //end
      m_size = NBITS-1;
      r_red  = (1 << 2*(m_size)) % m;
      arga = arga%m;
      argb = argb%m;
  end
  repeat (20) begin
    @(posedge CLK);
  end
  //repeat (2) begin
  //  @(posedge CLK);
  //end
  //#1
  //enable_p = 1'b1;
  //@(posedge CLK);
  //#1
  //enable_p = 1'b0;

  $finish; 
end



//------------------------------
//DUT
//------------------------------
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
  .r_red         (r_red[NBITS-1:0]),
  .y             (y),
  .done_irq_p    (done_irq_p)
);


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
