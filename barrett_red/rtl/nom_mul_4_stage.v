module nom_mul_4_stage #(
  parameter NBITS = 128,
  parameter PBITS = 0
)(
 input  clk,
 input  rst_n,
 input  enable_p,
 input  wire [NBITS-1:0]   a,
 input  wire [NBITS-1:0]   b,
 output wire [2*NBITS-1:0] y,
 output reg  done
);

DW02_mult_4_stage #(
  .A_width (NBITS),
  .B_width (NBITS)
 )u_dw02_mult_4_stage_inst (
 .CLK             (clk),
 .A               (a),
 .B               (b),
 .TC              (1'b0),
 .PRODUCT         (y)
);


reg	piped1, piped2, piped3, piped4, piped5;

always @ (posedge clk or negedge rst_n) begin
  if (rst_n == 1'b0) begin
	piped1 <= 1'b0;
	piped2 <= 1'b0;
    done   <= 1'b0;
  end
  else begin
	piped1 <= enable_p;
	piped2 <= piped1;
    done   <= piped2;
  end
end



endmodule
