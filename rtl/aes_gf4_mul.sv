// GF(2^4) multiplication in Canright 2005 normal-basis representation.
//
// Implements GF_MULS_4 from Canright "A Very Compact S-Box for AES":
//   ph = GF_MULS_2(ah, Ah, bh, Bh)           // high GF(2^2) product
//   pl = GF_MULS_2(al, Al, bl, Bl)           // low  GF(2^2) product
//   p  = GF_MULS_SCL_2(ah^al, aa, bh^bl, bb) // middle, scaled by nu
//   Q  = {ph^p, pl^p}
//
// GF_MULS_2(A, ab, B, cd):
//   abcd = ~(ab & cd);  p = ~(A[1]&B[1])^abcd;  q = ~(A[0]&B[0])^abcd
//
// GF_MULS_SCL_2(A, ab, B, cd):
//   t = ~(A[0]&B[0]);  p = ~(ab&cd)^t;  q = ~(A[1]&B[1])^t
//
// Port: a[3:2]=ah, a[1:0]=al, b[3:2]=bh, b[1:0]=bl
// Reference: Canright 2005, sbox.verilog GF_MULS_2/GF_MULS_SCL_2/GF_MULS_4

module aes_gf4_mul (
  input  logic [3:0] a,
  input  logic [3:0] b,
  output logic [3:0] p
);
  timeunit 1ns;
  timeprecision 1ps;

  wire [1:0] ah = a[3:2], al = a[1:0];
  wire [1:0] bh = b[3:2], bl = b[1:0];
  wire [1:0] a_sum = ah ^ al;   // ah^al for Karatsuba middle
  wire [1:0] b_sum = bh ^ bl;

  // Shared XOR factors for GF_MULS_2 / GF_MULS_SCL_2
  wire Ah = ah[1] ^ ah[0];
  wire Al = al[1] ^ al[0];
  wire aa = a_sum[1] ^ a_sum[0];
  wire Bh = bh[1] ^ bh[0];
  wire Bl = bl[1] ^ bl[0];
  wire bb = b_sum[1] ^ b_sum[0];

  // GF_MULS_2(ah, Ah, bh, Bh) -> ph
  wire abcd_h = ~(Ah & Bh);
  wire [1:0] ph = {(~(ah[1] & bh[1])) ^ abcd_h,
                   (~(ah[0] & bh[0])) ^ abcd_h};

  // GF_MULS_2(al, Al, bl, Bl) -> pl
  wire abcd_l = ~(Al & Bl);
  wire [1:0] pl = {(~(al[1] & bl[1])) ^ abcd_l,
                   (~(al[0] & bl[0])) ^ abcd_l};

  // GF_MULS_SCL_2(a_sum, aa, b_sum, bb) -> pm
  wire t_m = ~(a_sum[0] & b_sum[0]);
  wire [1:0] pm = {(~(aa & bb)) ^ t_m,
                   (~(a_sum[1] & b_sum[1])) ^ t_m};

  assign p = {ph ^ pm, pl ^ pm};

endmodule
