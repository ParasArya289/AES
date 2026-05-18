// GF(2^4) square-then-scale-by-nu in Canright 2005 normal-basis representation.
//
// Implements GF_SQ_SCL_4 from Canright "A Very Compact S-Box for AES":
//   a = A[3:2]  (high GF(2^2) element)
//   b = A[1:0]  (low  GF(2^2) element)
//   ab2  = GF_SQ_2(a ^ b)  = swap bits of (a^b) = {(a^b)[0], (a^b)[1]}
//   b2   = GF_SQ_2(b)      = swap bits of b      = {b[0], b[1]}
//   b2N2 = GF_SCLW_2(b2)   = {b2[1]^b2[0], b2[1]}
//   Q    = {ab2, b2N2}
//
// Expanding with a=a[3:2], b=a[1:0]:
//   ab2[1] = (a[2]^a[0])          -- (a^b)[0]
//   ab2[0] = (a[3]^a[1])          -- (a^b)[1]
//   b2     = {a[0], a[1]}         -- GF_SQ_2(b)
//   b2N2[1] = a[1]^a[0]           -- b2[1]^b2[0] = a[0]^a[1]
//   b2N2[0] = a[1]                -- b2[1] = a[1]
//   Q = {ab2[1], ab2[0], b2N2[1], b2N2[0]}
//
// Reference: Canright 2005, sbox.verilog GF_SQ_SCL_4

module aes_gf4_sq_scl (
  input  logic [3:0] a,
  output logic [3:0] p
);
  timeunit 1ns;
  timeprecision 1ps;

  assign p[3] = a[2] ^ a[0];   // ab2[1] = (ah^al)[0] = a[2]^a[0]
  assign p[2] = a[3] ^ a[1];   // ab2[0] = (ah^al)[1] = a[3]^a[1]
  assign p[1] = a[0] ^ a[1];   // b2N2[1] = b2[1]^b2[0] = a[0]^a[1]
  assign p[0] = a[0];           // b2N2[0] = b2[1] = a[0]  (GF_SQ_2 swaps: b2[1]=al[0])

endmodule
