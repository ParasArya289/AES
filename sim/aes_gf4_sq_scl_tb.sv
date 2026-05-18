// Exhaustive testbench for aes_gf4_sq_scl.sv — all 16 inputs.
// Reference: GF_SQ_SCL_4 from Canright 2005:
//   ab2   = GF_SQ_2(a^b)      = swap bits of (a[3:2]^a[1:0])
//   b2N2  = GF_SCLW_2(GF_SQ_2(b)) = GF_SCLW_2(swap(b))
//   Q     = {ab2, b2N2}

module aes_gf4_sq_scl_tb;
  timeunit 1ns;
  timeprecision 1ps;

  logic [3:0] a, p;

  aes_gf4_sq_scl dut (.a(a), .p(p));

  // GF_SQ_2: squaring in GF(2^2) NB = swap bits
  function automatic [1:0] gf22_sq(input [1:0] x);
    return {x[0], x[1]};
  endfunction

  // GF_SCLW_2: scale by Omega in GF(2^2) NB: Q = {A[1]^A[0], A[1]}
  function automatic [1:0] gf22_sclw(input [1:0] x);
    return {x[1] ^ x[0], x[1]};
  endfunction

  // GF_SQ_SCL_4 reference:
  //   ab2  = GF_SQ_2(a[3:2] ^ a[1:0])
  //   b2N2 = GF_SCLW_2(GF_SQ_2(a[1:0]))
  //   Q    = {ab2, b2N2}
  function automatic [3:0] sq_scl_ref(input [3:0] x);
    logic [1:0] xh, xl, ab2, b2N2;
    xh   = x[3:2];
    xl   = x[1:0];
    ab2  = gf22_sq(xh ^ xl);
    b2N2 = gf22_sclw(gf22_sq(xl));
    return {ab2, b2N2};
  endfunction

  integer ai, errors;
  logic [3:0] expected;

  initial begin
    errors = 0;
    for (ai = 0; ai < 16; ai++) begin
      a = ai[3:0];
      #1;
      expected = sq_scl_ref(a);
      if (p !== expected) begin
        $display("FAIL: sq_scl(0x%01x): got 0x%01x, expected 0x%01x", a, p, expected);
        errors++;
      end
    end
    if (errors == 0)
      $display("PASS: aes_gf4_sq_scl — all 16 inputs correct (0 errors)");
    else
      $display("FAIL: aes_gf4_sq_scl — %0d errors", errors);
    $finish;
  end

endmodule
