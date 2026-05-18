// GF(2^8) multiplicative inverse via GF((2^4)^2) tower decomposition.
// Implements GF_INV_8 from Canright 2005 "A Very Compact S-Box for AES".
//
// Input a[7:0] is already in GF((2^4)^2) normal basis (after input basis change).
// Output a_inv[7:0] is in GF((2^4)^2) normal basis (before output basis change).
//
// Pipeline:
//   a = A[7:4], b = A[3:0]  (high/low GF(2^4) halves)
//   ab   = GF_MULS_4(a, b)          // a*b in GF(2^4)
//   ab2  = GF_SQ_SCL_4(a ^ b)       // nu*(a^b)^2
//   d    = GF_INV_4(ab ^ ab2)        // GF(2^4) inverse of norm
//   p    = GF_MULS_4(d, b)           // d*b = inverse high half
//   q    = GF_MULS_4(d, a)           // d*a = inverse low half
//   Q    = {p, q}
//
// Reference: Canright 2005, sbox.verilog GF_INV_8

module aes_gf8_inv (
  input  logic [7:0] a,
  output logic [7:0] a_inv
);
  timeunit 1ns;
  timeprecision 1ps;

  wire [3:0] ah = a[7:4], al = a[3:0];

  // GF_SQ_SCL_4(ah ^ al): GF(2^4) square-then-scale
  wire [3:0] sq_scl_out;
  aes_gf4_sq_scl sq_scl_inst (.a(ah ^ al), .p(sq_scl_out));

  // GF_MULS_4(ah, al): a*b product in GF(2^4)
  wire [3:0] mul_out;
  aes_gf4_mul    mul0 (.a(ah), .b(al), .p(mul_out));

  // GF(2^4) norm: ab ^ ab2  (the delta in tower-field inversion)
  wire [3:0] norm = mul_out ^ sq_scl_out;

  // GF_INV_4(norm): invert norm in GF(2^4)
  wire [3:0] norm_inv;
  aes_gf4_inv    inv0 (.a(norm), .a_inv(norm_inv));

  // Recover inverse halves
  wire [3:0] p_out, q_out;
  aes_gf4_mul    mul1 (.a(norm_inv), .b(al), .p(p_out));  // d*b
  aes_gf4_mul    mul2 (.a(norm_inv), .b(ah), .p(q_out));  // d*a

  assign a_inv = {p_out, q_out};

endmodule
