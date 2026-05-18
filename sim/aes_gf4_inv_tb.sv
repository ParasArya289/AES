// Exhaustive testbench for aes_gf4_inv.sv — all 16 inputs.
// Verifies: for a!=0, a * a_inv == identity; for a==0, a_inv == 0.
// Reference uses Canright 2005 NAND-based GF(2^4) multiply (GF_MULS_4).

module aes_gf4_inv_tb;
  timeunit 1ns;
  timeprecision 1ps;

  logic [3:0] a, a_inv;

  aes_gf4_inv dut (.a(a), .a_inv(a_inv));

  // GF(2^2) NB multiply — Canright GF_MULS_2 (NAND-based)
  function automatic [1:0] gf22_muls(input [1:0] A, input logic ab, input [1:0] B, input logic cd);
    logic abcd, p, q;
    abcd = ~(ab & cd);
    p    = (~(A[1] & B[1])) ^ abcd;
    q    = (~(A[0] & B[0])) ^ abcd;
    return {p, q};
  endfunction

  // GF(2^2) NB multiply-and-scale — Canright GF_MULS_SCL_2
  function automatic [1:0] gf22_muls_scl(input [1:0] A, input logic ab, input [1:0] B, input logic cd);
    logic t, p, q;
    t = ~(A[0] & B[0]);
    p = (~(ab & cd)) ^ t;
    q = (~(A[1] & B[1])) ^ t;
    return {p, q};
  endfunction

  // GF(2^4) multiply — Canright GF_MULS_4
  function automatic [3:0] gf4_muls(input [3:0] x, input [3:0] y);
    logic [1:0] xh, xl, yh, yl, a_sum, b_sum, ph, pl, pm;
    logic Xh, Xl, Xx, Yh, Yl, Yx;
    xh = x[3:2]; xl = x[1:0];
    yh = y[3:2]; yl = y[1:0];
    a_sum = xh ^ xl; b_sum = yh ^ yl;
    Xh = xh[1]^xh[0]; Xl = xl[1]^xl[0]; Xx = a_sum[1]^a_sum[0];
    Yh = yh[1]^yh[0]; Yl = yl[1]^yl[0]; Yx = b_sum[1]^b_sum[0];
    ph = gf22_muls(xh, Xh, yh, Yh);
    pl = gf22_muls(xl, Xl, yl, Yl);
    pm = gf22_muls_scl(a_sum, Xx, b_sum, Yx);
    return {ph ^ pm, pl ^ pm};
  endfunction

  integer ai, errors;
  logic [3:0] identity, prod;

  initial begin
    errors = 0;

    // Find multiplicative identity
    identity = 4'hx;
    for (integer e = 1; e < 16; e++) begin
      logic all_ok;
      all_ok = 1;
      for (integer x = 1; x < 16; x++) begin
        if (gf4_muls(e[3:0], x[3:0]) !== x[3:0]) all_ok = 0;
      end
      if (all_ok) begin
        identity = e[3:0];
        $display("INFO: GF(2^4) multiplicative identity = 0x%01x", e[3:0]);
        break;
      end
    end

    if (identity === 4'hx) begin
      $display("FAIL: no multiplicative identity found — field arithmetic is broken");
      errors++;
    end else begin
      // Check zero
      a = 4'h0; #1;
      if (a_inv !== 4'h0) begin
        $display("FAIL: inv(0) = 0x%01x, expected 0x0", a_inv);
        errors++;
      end
      // Check all nonzero
      for (ai = 1; ai < 16; ai++) begin
        a = ai[3:0]; #1;
        prod = gf4_muls(a, a_inv);
        if (prod !== identity) begin
          $display("FAIL: 0x%01x * inv(0x%01x)=0x%01x = 0x%01x, expected 0x%01x",
                   a, a, a_inv, prod, identity);
          errors++;
        end
      end
    end

    if (errors == 0)
      $display("PASS: aes_gf4_inv — all 16 inputs correct (0 errors)");
    else
      $display("FAIL: aes_gf4_inv — %0d errors", errors);
    $finish;
  end

endmodule
