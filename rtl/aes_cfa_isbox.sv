// CFA Inverse S-Box: AES InvSubBytes via Canright 2005 composite-field inversion.
//
// Pipeline (encrypt=0 path of bSbox):
//   Step 1: Input basis change — GF(2^8) polynomial -> GF((2^4)^2) normal basis (Y matrix)
//   Step 2: SELECT_NOT_8 inverts Y  -> Z = ~Y  (inverting MUX, decrypt side)
//   Step 3: GF_INV_8(Z) in tower field -> C
//   Step 4: Output basis change + inverse AES affine (X equations) -> X
//   Step 5: SELECT_NOT_8 inverts X  -> a_out = ~X  (inverting MUX, decrypt side)
//
// Reference: Canright 2005 sbox.verilog (bSbox module, encrypt=0 path)

module aes_cfa_isbox (
  input  logic [7:0] s_in,
  output logic [7:0] a_out
);
  timeunit 1ns;
  timeprecision 1ps;

  // ----------------------------------------------------------------
  // Step 1: Input basis change R1..R9, Y[7:0]  (decrypt input matrix)
  // ----------------------------------------------------------------
  wire R1 = s_in[7] ^ s_in[5];
  wire R2 = ~(s_in[7] ^ s_in[4]);   // XNOR
  wire R3 = s_in[6] ^ s_in[0];
  wire R4 = ~(s_in[5] ^ R3);        // XNOR
  wire R5 = s_in[4] ^ R4;
  wire R6 = s_in[3] ^ s_in[0];
  wire R7 = s_in[2] ^ R1;
  wire R8 = s_in[1] ^ R3;
  wire R9 = s_in[3] ^ R8;

  wire [7:0] Y;
  assign Y[7] = R2;
  assign Y[6] = s_in[4] ^ R8;
  assign Y[5] = s_in[6] ^ s_in[4];
  assign Y[4] = R9;
  assign Y[3] = ~(s_in[6] ^ R2);    // XNOR
  assign Y[2] = R7;
  assign Y[1] = s_in[4] ^ R6;
  assign Y[0] = s_in[1] ^ R5;

  // ----------------------------------------------------------------
  // Step 2: SELECT_NOT_8 (encrypt=0): Z = ~Y
  // ----------------------------------------------------------------
  wire [7:0] Z = ~Y;

  // ----------------------------------------------------------------
  // Step 3: GF_INV_8 in tower field
  // ----------------------------------------------------------------
  wire [7:0] C;
  aes_gf8_inv inv (.a(Z), .a_inv(C));

  // ----------------------------------------------------------------
  // Step 4: Output basis change + inverse AES affine (X equations)
  // ----------------------------------------------------------------
  wire T1  = C[7] ^ C[3];
  wire T2  = C[6] ^ C[4];
  wire T3  = C[6] ^ C[0];
  wire T4  = ~(C[5] ^ C[3]);        // XNOR
  wire T5  = ~(C[5] ^ T1);          // XNOR
  wire T6  = ~(C[5] ^ C[1]);        // XNOR
  wire T7  = ~(C[4] ^ T6);          // XNOR
  wire T8  = C[2] ^ T4;
  wire T9  = C[1] ^ T2;
  wire T10 = T3 ^ T5;

  wire [7:0] X;
  assign X[7] = ~(C[4] ^ C[1]);     // XNOR
  assign X[6] = C[1] ^ T10;
  assign X[5] = C[2] ^ T10;
  assign X[4] = ~(C[6] ^ C[1]);     // XNOR
  assign X[3] = T8 ^ T9;
  assign X[2] = ~(C[7] ^ T7);       // XNOR
  assign X[1] = T6;
  assign X[0] = ~C[2];              // NOT

  // ----------------------------------------------------------------
  // Step 5: SELECT_NOT_8 (encrypt=0): a_out = ~X
  // ----------------------------------------------------------------
  assign a_out = ~X;

endmodule
