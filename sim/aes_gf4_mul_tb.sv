// Exhaustive testbench for aes_gf4_mul.sv — all 16x16=256 input combinations.
// Reference model uses Canright 2005 NAND-based GF(2^2) multiply (GF_MULS_2).

module aes_gf4_mul_tb;
  timeunit 1ns;
  timeprecision 1ps;

  logic [3:0] a, b, p;

  aes_gf4_mul dut (.a(a), .b(b), .p(p));

  // GF(2^2) NB multiply — Canright GF_MULS_2 (NAND-based):
  //   abcd = ~(ab & cd),  Q[1] = ~(A[1]&B[1])^abcd,  Q[0] = ~(A[0]&B[0])^abcd
  function automatic [1:0] gf22_muls(input [1:0] A, input logic ab, input [1:0] B, input logic cd);
    logic abcd, p, q;
    abcd = ~(ab & cd);
    p    = (~(A[1] & B[1])) ^ abcd;
    q    = (~(A[0] & B[0])) ^ abcd;
    return {p, q};
  endfunction

  // GF(2^2) NB multiply-and-scale by nu — Canright GF_MULS_SCL_2:
  //   t = ~(A[0]&B[0]),  p = ~(ab&cd)^t,  q = ~(A[1]&B[1])^t
  function automatic [1:0] gf22_muls_scl(input [1:0] A, input logic ab, input [1:0] B, input logic cd);
    logic t, p, q;
    t = ~(A[0] & B[0]);
    p = (~(ab & cd)) ^ t;
    q = (~(A[1] & B[1])) ^ t;
    return {p, q};
  endfunction

  // GF(2^4) multiply — Canright GF_MULS_4:
  //   ph = GF_MULS_2(ah,bh), pl = GF_MULS_2(al,bl), pm = GF_MULS_SCL_2(ah^al, bh^bl)
  //   Q = {ph^pm, pl^pm}
  function automatic [3:0] gf4_muls(input [3:0] x, input [3:0] y);
    logic [1:0] xh, xl, yh, yl, a_sum, b_sum, ph, pl, pm;
    logic Xh, Xl, Xx, Yh, Yl, Yx;
    xh = x[3:2]; xl = x[1:0];
    yh = y[3:2]; yl = y[1:0];
    a_sum = xh ^ xl;
    b_sum = yh ^ yl;
    Xh = xh[1] ^ xh[0]; Xl = xl[1] ^ xl[0]; Xx = a_sum[1] ^ a_sum[0];
    Yh = yh[1] ^ yh[0]; Yl = yl[1] ^ yl[0]; Yx = b_sum[1] ^ b_sum[0];
    ph = gf22_muls(xh, Xh, yh, Yh);
    pl = gf22_muls(xl, Xl, yl, Yl);
    pm = gf22_muls_scl(a_sum, Xx, b_sum, Yx);
    return {ph ^ pm, pl ^ pm};
  endfunction

  integer ai, bi, errors;
  logic [3:0] expected;

  initial begin
    errors = 0;
    for (ai = 0; ai < 16; ai++) begin
      for (bi = 0; bi < 16; bi++) begin
        a = ai[3:0];
        b = bi[3:0];
        #1;
        expected = gf4_muls(a, b);
        if (p !== expected) begin
          $display("FAIL: gf4_mul(0x%01x, 0x%01x): got 0x%01x, expected 0x%01x",
                   a, b, p, expected);
          errors = errors + 1;
        end
      end
    end
    if (errors == 0)
      $display("PASS: aes_gf4_mul — all 256 input combinations correct");
    else
      $display("FAIL: aes_gf4_mul — %0d errors", errors);
    $finish;
  end

endmodule
