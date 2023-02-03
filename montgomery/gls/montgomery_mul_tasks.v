
task automatic gcdExtended(input [NBITS-1:0]a1, input[NBITS-1:0]b1, output [NBITS:0]p, output [NBITS:0] q, output [NBITS-1:0] gcd);
begin
   //$display("a1 = %d, b1 = %d",a1, b1);
   if(a1 == 0) begin
       p = 0;
       q = 1;
       gcd = b1;
       //$display("p = %d, q = %d",p, q);
   end else begin
       gcdExtended(b1%a1, a1, p1, q1, gcd);
       //$display("p = %d, q = %d",p, q);
       //$display("p1 = %d, q1 = %d",p1, q1);
       //$display("a1 = %d, b1 = %d",a1, b1);
       p = q1 - (b1/a1)*p1;
       q = p1;
       //$display("p = %d, q = %d",p, q);
   end
end
endtask

task automatic modInverse(input[NBITS-1:0] a, input[NBITS-1:0] m, output signed[NBITS-1:0] res); begin
    //$display("before gcdExtended is %d", x1);
    gcdExtended(a, m, x1, y1, g);
    if (g != 1) begin
        //$display("Inverse doesn't exist");
    end else begin
        // m is added to handle negative x
        //$display("gcdExtended is %d", x1);
        if(x1<0) begin
          res = (x1+m) % m;
        end else begin
          res = (x1) % m;
        end
        //$display("Modular multiplicative inverse is %d", res);
    end
end
endtask

task automatic mont_precalc(input[NBITS-1:0] a, input[NBITS-1:0] m, output[2*NBITS-1:0] res); begin
    modInverse(a, m, m_inv);
    res = (m_inv*(2**NBITS) - 1) / m;
end
endtask

task sequencer();
  begin
      if(out_idx%1 == 0) begin
  	  $display("Latency = %d", out_idx - out_idx2);
      	  wait(out_idx == out_idx2);
          assert(std::randomize(m));
          m[NBITS-1] = m[NBITS-1] | iteration[1];
          m[NBITS-2] = m[NBITS-2] | iteration[0];
          m[0] = 1'b1;
          m[15:0] = 'h0001;
      end
      assert(std::randomize(arga));
      assert(std::randomize(argb));
      iteration = iteration - 1;
      arga = arga%m;
      argb = argb%m;
  end
endtask

task modmul  (input [NBITS-1 :0] arga,input [NBITS-1 :0] argb);
  begin
    $display(" #------------------MODMUL STARTED---------------------*");
    #1
    //a        = {{(NBITS-1){1'b1}}, 1'b0} | arga;
    //b        = {{(NBITS-1){1'b1}}, 1'b0} | argb;
    a        = arga;
    b        = argb;
    m2 = 'd0;
    m2[NBITS] = 1'b1;
    //$display("m2 = %x, m = %x, p1 = %x, q1 = %x, gcd = %x",m2,m,p1,q1, gcd);
    //gcdExtended(m,m2,p1,q1,gcd);
    //$display("m2 = %x, m = %x, p1 = %x, q1 = %x, gcd = %x",m2,m,p1,q1, gcd);
    
`ifdef TC_MODULAR_MUL 
    temp_reg1 = (a*b)%m;
`elsif TC_MONTGOMERY_MUL
    //$display("mod inverse started."); 
    modInverse(r_red, m, R_1);
    temp_reg1 = (a*b*R_1)%m;
`endif
    a_in[out_idx] = a;
    b_in[out_idx] = b;
    ref_out[out_idx] = temp_reg1;
    out_idx = out_idx +1;
    temp_reg2 = no_of_clocks;
    enable_p  = 1'b1;
    @(posedge CLK);
    #1 enable_p = 1'b0;
    //wait (mod_mul_il_tb.u_dut_inst.u_mxn_calc_inst.mxn_done == 1'b1)
    //temp_reg3 = no_of_clocks - temp_reg2;
    //wait (done_irq_p == 1'b1)
//    temp_reg2 = no_of_clocks - temp_reg2;
//    if (y[NBITS-1 :0] == temp_reg1) begin
//`ifdef TC_MODULAR_MUL 
//      $display(" #------------------MODMUL PASSED---------------------*");
//      $display(" << NUM CYCLES for precalculation    : %d", temp_reg3);
//      $display(" << NUM CYCLES for complete operation: %d", temp_reg2);
//    $display(" << ARG A | ARG B | MODULUS M\n%d | %d | %d", arga, argb, m);
//    $display(" << Expected Result | Calculated Result\n << %d | %d", temp_reg1, y[NBITS-1:0]);
//`elsif TC_MONTGOMERY_MUL 
//      $display(" #------------------MONTGOMERY PASSED---------------------*");
//      $display(" << NUM CYCLES for precalculation    : %d", temp_reg3);
//      $display(" << NUM CYCLES for complete operation: %d", temp_reg2);
//    $display(" << ARG A | ARG B | MODULUS M | R_1 | R \n << %d | %d | %d | %d | %d ", arga, argb, m, R_1, r_red);
//    $display(" << Expected Result2 | Calculated Result\n << %d | %d", temp_reg1, y[NBITS-1:0]);
//`endif
//    end
//    else begin
//`ifdef TC_MODULAR_MUL 
//    $display(" #------------------MODMUL FAILED---------------------*");
//    $display(" << ARG A | ARG B | MODULUS M\n << %d | %d | %d", arga, argb, m);
//    $display(" << Expected Result | Calculated Result\n << %d | %d", temp_reg1, y[NBITS-1:0]);
//`elsif TC_MONTGOMERY_MUL 
//    $display(" #------------------MONTGOMERY FAILED---------------------*");
//    $display(" << ARG A | ARG B | MODULUS M | R_1 | R \n << %d | %d | %d | %d | %d ", arga, argb, m, R_1, r_red);
//    $display(" << Expected Result2 | Calculated Result\n << %d | %d", temp_reg1, y[NBITS-1:0]);
//`endif
//    end
//    repeat (2) begin
//      @(posedge CLK);
//    end
  end
endtask


