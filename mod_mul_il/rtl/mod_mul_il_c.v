//Oleg's code :
// for (int i = 0; i < 4096; ++i)
//    {
//        p <<= 1;    // 1 bit more = 4097
//        p = reduce1Rca(p, m);
//        p = addRca(p, high(a) * b);
//        p = reduce1Rca(p, m);
//        a <<= 1; a.resize(4096);
//    }

module mod_mul_il_c #(
  parameter NBITS     = 4096,
  parameter PBITS     = 1

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

localparam LOG2NBITS     = $clog2(NBITS);
//--------------------------------------
//reg/wire declaration
//--------------------------------------

reg  [LOG2NBITS :0] cnt;

reg  [NBITS-1 :0] a_loc;
reg  [NBITS-1 :0] y_loc;
reg  [NBITS-1 :0] b_loc;
reg               done_irq_p_loc;
reg               done_irq_p_loc_d;

wire [NBITS   :0] y_loc_accum;
wire [NBITS+1 :0] y_loc_accum_sub_m;
wire [NBITS   :0] y_loc_accum_red;

wire [NBITS+1 :0] y_loc_sub_m;
wire [NBITS   :0] y_loc_red;
wire [NBITS-1 :0] b_loc_red;

//calculate (a*b)%m
assign y_loc_sub_m = {y_loc, 1'b0} - m;
assign y_loc_red   = y_loc_sub_m[NBITS+1] ? {y_loc, 1'b0} : y_loc_sub_m[NBITS:0];

assign y_loc_accum       = a_loc[NBITS-1] ? (b_loc + y_loc_red) : y_loc_red;
assign y_loc_accum_sub_m = y_loc_accum - m;
assign y_loc_accum_red   = y_loc_accum_sub_m[NBITS+1] ? y_loc_accum[NBITS-1 :0] : y_loc_accum_sub_m[NBITS-1 :0];


always @ (posedge clk or negedge rst_n) begin
  if (rst_n == 1'b0) begin
    y_loc <= {NBITS{1'b0}};
    a_loc <= {NBITS{1'b0}};
    b_loc <= {NBITS{1'b0}};
  end
  else begin
      if (enable_p == 1'b1) begin
        a_loc <= a;
        b_loc <= b;
        y_loc <= {NBITS{1'b0}};
      end
      else if (~cnt[LOG2NBITS]) begin
        y_loc <= y_loc_accum_red[NBITS-1:0];
        a_loc <= {a_loc[NBITS-2:0], 1'b0};
      end 
  end
end

  
  always @ (posedge clk or negedge rst_n) begin
    if (rst_n == 1'b0) begin
      done_irq_p_loc    <= 1'b1;
      done_irq_p_loc_d  <= 1'b1;
    end
    else begin
      done_irq_p_loc    <= cnt[LOG2NBITS];  //enable_p for the case a == 1
      done_irq_p_loc_d  <= done_irq_p_loc  ;
    end
  end

  assign done_irq_p =  ~done_irq_p_loc_d & done_irq_p_loc;
  assign y          =  y_loc;

  
  always @ (posedge clk or negedge rst_n) begin
    if (rst_n == 1'b0) begin
      cnt <= {1'b1,{(LOG2NBITS){1'b0}}};
    end
    else if (enable_p == 1'b1) begin
      cnt <= {(LOG2NBITS+1){1'b0}};
    end
    else if (~cnt[LOG2NBITS]) begin
      cnt <= cnt + 1'b1;
    end
  end



endmodule
