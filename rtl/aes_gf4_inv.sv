// GF(2^4) multiplicative inverse in Canright 2005 normal-basis representation.
//
// Implements GF_INV_4 from Canright "A Very Compact S-Box for AES":
//
// Step 1: Compute c = ab ^ ab2N (2-bit GF(2^2) element = GF(2^4) norm)
//   a = A[3:2], b = A[1:0], sa=a[1]^a[0], sb=b[1]^b[0]
//   c[1] = ~(a[1]|b[1]) ^ ~(sa&sb)     (NOR ^ NAND)
//   c[0] = ~(sa|sb)     ^ ~(a[0]&b[0]) (NOR ^ NAND)
//
// Step 2: Invert c in GF(2^2) using squaring (inverse = square in NB):
//   d = GF_SQ_2(c) = {c[0], c[1]}
//
// Step 3: Reconstruct 4-bit inverse:
//   p = GF_MULS_2(d, sd, b, sb)
//   q = GF_MULS_2(d, sd, a, sa)
//   Q = {p, q}
//
// Reference: Canright 2005, sbox.verilog GF_INV_4

module aes_gf4_inv (
  input  logic [3:0] a,
  output logic [3:0] a_inv
);
  timeunit 1ns;
  timeprecision 1ps;

  wire [1:0] ah = a[3:2], al = a[1:0];
  wire sa = ah[1] ^ ah[0];
  wire sb = al[1] ^ al[0];

  // Step 1: compute 2-bit norm c = ab ^ GF_SCLW2_2(GF_SQ_2(a^b)) [optimized]
  wire c1 = (~(ah[1] | al[1])) ^ (~(sa & sb));
  wire c0 = (~(sa   | sb))     ^ (~(ah[0] & al[0]));

  // Step 2: GF_SQ_2(c) = swap bits = GF(2^2) inverse
  wire [1:0] d = {c0, c1};   // {c[0], c[1]}
  wire sd = d[1] ^ d[0];

  // Step 3: GF_MULS_2(d, sd, al, sb) -> p_hi
  wire abcd_p = ~(sd & sb);
  wire [1:0] p_out = {(~(d[1] & al[1])) ^ abcd_p,
                      (~(d[0] & al[0])) ^ abcd_p};

  // Step 3: GF_MULS_2(d, sd, ah, sa) -> p_lo
  wire abcd_q = ~(sd & sa);
  wire [1:0] q_out = {(~(d[1] & ah[1])) ^ abcd_q,
                      (~(d[0] & ah[0])) ^ abcd_q};

  assign a_inv = {p_out, q_out};

endmodule
