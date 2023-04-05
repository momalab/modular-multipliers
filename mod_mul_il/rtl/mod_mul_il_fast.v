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

module mod_mul_il_fast #(
  parameter NBITS  = 4,
  parameter PBITS  = 1

 ) (
  input               clk,
  input               rst_n,
  input               enable_p,
  input  [NBITS-1 :0] a,
  input  [NBITS-1 :0] b,
  input  [NBITS-1 :0] m,
  input  [$clog2(NBITS)-1 :0] m_msb,
  output [NBITS-1 :0] y,
  output              done_irq_p
);

//--------------------------------------
//localparam/reg/wire declaration
//--------------------------------------

localparam MLSIZE = 1 << PBITS;

reg  [NBITS+PBITS   :0] a_loc;   //+PBITS to take care of when NBITS is non multiple of PBITS

reg  [NBITS-1 :0]       b_loc_red;
reg                     done_irq_p_loc;
reg                     done_irq_p_loc_d;

reg  [PBITS :0]           cnt;
reg  [NBITS+PBITS -1 :0]  madd;
reg  [NBITS          :0]  badd;
reg  [NBITS       -1 :0]  badd_red;
wire [NBITS       +1 :0]  badd_sub_m;
reg  [NBITS+PBITS -1 :0]  bxn_loc[1 : MLSIZE];

wire bxn_done;
reg  bxn_done_pre;

reg [NBITS+PBITS+2  :0]  y_loc_accum;
reg [NBITS+PBITS+3  :0]  y_loc_accum_red;
reg [NBITS+PBITS+2  :0]  y_loc;
reg [NBITS+PBITS+3 :0]   y_loc_red;

wire [NBITS+PBITS+2     :0] mxn;
reg [NBITS          -1 :0]  bxn[0 : MLSIZE-1];


wire [NBITS+PBITS+2 :0] il_add_a;
wire [NBITS+PBITS+2 :0] il_add_b;
wire [NBITS+PBITS+3 :0] il_add_y;
wire [NBITS+PBITS+2 :0] il_sub_a;
wire [NBITS+PBITS+2 :0] il_sub_b;
wire [NBITS+PBITS+3 :0] il_sub_y;

reg last_lap; 
reg last_lap_d; 

genvar  i;
integer j;


//calculate (a*b)%m

assign mxn = mxn << (PBITS+1);

always @* begin
  b_loc_red  = bxn[0];
  for (j=0; j<=MLSIZE; j=j+1) begin
    b_loc_red  = (a_loc[NBITS : NBITS-PBITS+1] == j) ? bxn[j] : b_loc_red;
  end
end

assign y_loc_accum     = last_lap ? y_loc : il_add_y;
assign y_loc_accum_red = il_sub_y;
assign y_loc_red       = y_loc_accum_red[NBITS+PBITS+3] ? y_loc_accum : y_loc_accum_red;


always @ (posedge clk or negedge rst_n) begin
  if (rst_n == 1'b0) begin
    y_loc <= {(NBITS+PBITS+3){1'b0}};
    a_loc <= {(NBITS+1){1'b0}};
  end
  else begin
    if (bxn_done == 1'b1) begin
      y_loc <= {(NBITS+PBITS+3){1'b0}};
      a_loc <= {a, 1'b1};
    end
    else if (last_lap || |a_loc[NBITS-1 :0]) begin
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
    done_irq_p_loc    <= |a_loc[NBITS-1 :0] | bxn_done;  //enable_p for the case a == 1
    done_irq_p_loc_d  <= done_irq_p_loc  ;
  end
end

  assign done_irq_p =  last_lap_d & ~last_lap;
  assign y          =  y_loc;

always @ (posedge clk or negedge rst_n) begin
  if (rst_n == 1'b0) begin
    last_lap    <= 1'b0;
    last_lap_d  <= 1'b0;
  end
  else begin
    last_lap_d  <= last_lap;
    if (done_irq_p_loc_d & ~done_irq_p_loc) begin
      last_lap    <= 1'b1;
    end
    else if ((last_lap == 1'b1) && (il_sub_y[NBITS+PBITS+3]) == 1'b1) begin
      last_lap    <= 1'b0;
    end
  end
end



always @ (posedge clk or negedge rst_n) begin
  if (rst_n == 1'b0) begin
    cnt <= {1'b1, {(PBITS){1'b0}}};
  end
  else begin
    if (enable_p == 1'b1) begin
      cnt <= {{(PBITS-1){1'b0}}, 1'b1, 1'b0};   //start the counter with 2
    end 
    else if (cnt[PBITS] == 1'b1)  begin         //Check for overflow
      cnt <= {1'b1, {(PBITS){1'b0}}};
    end
    else begin
      cnt  <= cnt + 1'b1;
    end
  end
end

assign bxn_done = enable_p ? 1'b0 : (cnt[PBITS] & ~bxn_done_pre);

  
always @ (posedge clk or negedge rst_n) begin
  if (rst_n == 1'b0) begin
    bxn_done_pre    <= 1'b1;
  end
  else begin
    if (enable_p == 1'b1) begin
      bxn_done_pre    <= 1'b0;
    end 
    else begin
      bxn_done_pre    <= cnt[PBITS];
    end
  end
end



always @* begin
  bxn[0]     = 0;
  bxn[1]     = b;
end

assign badd_sub_m = il_sub_y;
assign badd_red   = badd_sub_m[NBITS+1] ? badd : badd_sub_m;

always @ (posedge clk or negedge rst_n) begin
  if (rst_n == 1'b0) begin
    badd <= {(NBITS){1'b0}};
  end
  else begin
    if (enable_p == 1'b1) begin
      badd <= {b, 1'b0};
    end 
    else if (cnt[PBITS] == 1'b1) begin
      badd <= {(NBITS){1'b0}};
    end
    else begin
      badd <= il_add_y;
    end 
  end
end

generate
  for (i = 2; i < MLSIZE; i = i+1) begin : bxn_all
    always @ (posedge clk or negedge rst_n) begin
      if (rst_n == 1'b0) begin
        bxn[i] <= {NBITS{1'b0}};
      end
      else begin
        if (cnt[PBITS-1 :0] == i) begin
          bxn[i] <= badd_red;
        end 
      end
    end
  end
endgenerate

assign il_add_a = ~bxn_done_pre ?  {{(PBITS+3){1'b0}}, badd_red} : {y_loc, {PBITS{1'b0}}};
assign il_add_b = ~bxn_done_pre ?  {{(PBITS+3){1'b0}}, b}        : b_loc_red;

assign il_sub_a = ~bxn_done_pre              ?  {{(PBITS+2){1'b0}}, badd}     : y_loc_accum;
assign il_sub_b = (~bxn_done_pre | last_lap) ?  {{(PBITS+3){1'b0}}, m}        : mxn;

il_add #(
  .NBITS  (NBITS),
  .PBITS  (PBITS)
 ) u_il_add_inst (
  .a   (il_add_a),
  .b   (il_add_b),
  .y   (il_add_y)
);

il_sub #(
  .NBITS  (NBITS),
  .PBITS  (PBITS)
 ) u_il_sub_inst (
  .a (il_sub_a),
  .b (il_sub_b),
  .y (il_sub_y)
);


endmodule
