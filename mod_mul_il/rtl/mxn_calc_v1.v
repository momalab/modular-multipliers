module mxn_calc_v1 #(
  parameter NBITS  = 4096,
  parameter PBITS  = 1,
  parameter MLSIZE = 1 << PBITS

 ) (
  input                           clk,
  input                           rst_n,
  input                           enable_p,
  input  [NBITS-1 :0]             m,
  input  [NBITS-1 :0]             b,
  output                          bxn_done,
  output reg [NBITS+PBITS -1 :0]  mxn[1 : MLSIZE],
  output reg [NBITS       -1 :0]  bxn[0 : MLSIZE-1]
);


reg  [PBITS :0] cnt;
reg  [NBITS+PBITS -1 :0]  madd;
reg  [NBITS          :0]  badd;
reg  [NBITS       -1 :0]  badd_red;
wire [NBITS       +1 :0]  badd_sub_m;
reg  [NBITS+PBITS -1 :0]  bxn_loc[1 : MLSIZE];

reg mxn_done_pre;

genvar i;

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

assign bxn_done = enable_p ? 1'b0 : (cnt[PBITS] & ~mxn_done_pre);

  
always @ (posedge clk or negedge rst_n) begin
  if (rst_n == 1'b0) begin
    mxn_done_pre    <= 1'b1;
  end
  else begin
    if (enable_p == 1'b1) begin
      mxn_done_pre    <= 1'b0;
    end 
    else begin
      mxn_done_pre    <= cnt[PBITS];
    end
  end
end



always @* begin
  bxn[0]     = 0;
  bxn[1]     = b;
end

assign badd_sub_m = badd - m;
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
      badd <= badd_red + b;
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




endmodule
