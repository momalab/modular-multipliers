`define OLD
module mxn_calc #(
  parameter NBITS  = 4096,
  parameter PBITS  = 1,
  parameter MLSIZE = 1 << PBITS

 ) (
  input                           clk,
  input                           rst_n,
  input                           enable_p,
  input  [NBITS-1 :0]             m,
  input  [NBITS-1 :0]             b,
  output                          mxn_done,
  output reg [NBITS+PBITS -1 :0]  mxn[0 : MLSIZE-1],
  output reg [NBITS+PBITS -1 :0]  bxn[1 : MLSIZE-1]
);

reg [NBITS+PBITS -1 :0]  mxn2[0 : MLSIZE-1];
reg [NBITS+PBITS -1 :0]  mxn3[0 : MLSIZE-1];
reg [NBITS+PBITS -1 :0]  bxn2[0 : MLSIZE-1];
reg  [PBITS :0] cnt;
reg  [NBITS+PBITS -1 :0]  madd;
reg  [NBITS+PBITS-1  :0]  badd;
reg  [NBITS+PBITS-1  :0]  badd_red;
wire [NBITS       +1 :0]  badd_sub_m;
reg  [NBITS+PBITS -1 :0]  bxn_loc[1 : MLSIZE];

reg mxn_done_pre;

genvar i;

integer j;

`ifdef OLD
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

assign mxn_done = enable_p ? 1'b0 : (cnt[PBITS] & ~mxn_done_pre);

  
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
  mxn2[0]     = 'd0;
  mxn2[1]     = m;
  bxn[0]     = 0;
  bxn[1]     = b;
  
end

generate
  for (i = 2; i <= MLSIZE; i = i+2) begin : mxn_even
    always @* begin
      mxn2[i] = {mxn2[i/2][NBITS+PBITS -1 :0], 1'b0};
    end
  end
endgenerate



generate
  for (i = 3; i < MLSIZE; i = i+2) begin : mxn_odd
    always @ (posedge clk or negedge rst_n) begin
      if (rst_n == 1'b0) begin
        mxn2[i] <= {(NBITS+PBITS){1'b0}};
      end
      else begin
        if (cnt[PBITS-1 :0] == i) begin
          mxn2[i] <= madd;
        end 
      end
    end
  end
endgenerate

always @ (posedge clk or negedge rst_n) begin
  if (rst_n == 1'b0) begin
    madd <= {(NBITS+PBITS){1'b0}};
  end
  else begin
    if (enable_p == 1'b1) begin
      madd <= {m, 1'b0};
    end 
    else if (cnt[PBITS] == 1'b1) begin
      madd <= {(NBITS+PBITS){1'b0}};
    end
    else begin
      madd <= madd + m;
    end 
  end
end

//assign badd_sub_m = badd - m;
assign badd_red   = badd;//badd_sub_m[NBITS+1] ? badd : badd_sub_m;

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

assign mxn[0] = mxn2[0];
assign mxn[1] = m[1] ? mxn2[1] : mxn2[3]; 
assign mxn[2] = mxn2[2]; 
assign mxn[3] = m[1] ? mxn2[3] : mxn2[1]; 
`else

always @* begin
   for(j=0;j<MLSIZE;j=j+1) begin
     mxn2[j]     = j*m;
   end
end

always @* begin
   if(MLSIZE==2) begin
   for(j=0;j<MLSIZE;j=j+1) begin
     mxn3[j]     = mxn2[j];
   end
   end else begin
     mxn3[0] = mxn2[0];
     mxn3[1] = m[1] ? mxn2[1] : mxn2[3]; 
     mxn3[2] = mxn2[2]; 
     mxn3[3] = m[1] ? mxn2[3] : mxn2[1]; 
   end
end

always @ (posedge clk or negedge rst_n) begin
  if (rst_n == 1'b0) begin
   for(j=0;j<MLSIZE;j=j+1) begin
    mxn[j] <= {(NBITS+PBITS){1'b0}};
   end
  end else begin
   if(enable_p) begin
   for(j=0;j<MLSIZE;j=j+1) begin
      mxn[j] <= mxn3[j];
   end
   end
  end
end

always @ (posedge clk or negedge rst_n) begin
  if (rst_n == 1'b0) begin
   for(j=0;j<MLSIZE;j=j+1) begin
    bxn[j] <= {(NBITS+PBITS){1'b0}};
   end
  end else begin
   if(enable_p) begin
   for(j=0;j<MLSIZE;j=j+1) begin
      bxn[j] <= j*b;
   end
   end
  end
end

async_dff #(.SIZE(1)) u_enable_dff (.D(enable_p), .CLK(clk), .ASYNC_RESET(rst_n), .Q(mxn_done));  

`endif
endmodule
