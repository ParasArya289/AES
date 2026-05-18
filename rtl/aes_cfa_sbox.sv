// CFA Forward S-Box: AES SubBytes via Canright 2005 composite-field inversion.
//
// Pipeline (encrypt=1 path of bSbox):
//   Step 1: Input basis change — GF(2^8) polynomial -> GF((2^4)^2) normal basis (B matrix)
//   Step 2: SELECT_NOT_8 inverts B  -> Z = ~B  (inverting MUX, encrypt side)
//   Step 3: GF_INV_8(Z) in tower field -> C
//   Step 4: Output basis change + AES affine (D equations) -> D
//   Step 5: SELECT_NOT_8 inverts D  -> s_out = ~D  (inverting MUX, encrypt side)
//
// Reference: Canright 2005 sbox.verilog (bSbox module, encrypt=1 path)

module aes_cfa_sbox (
  input  logic [7:0] a_in,
  output logic [7:0] s_out
);
  timeunit 1ns;
  timeprecision 1ps;

  // ----------------------------------------------------------------
  // Step 1: Input basis change R1..R9, B[7:0]
  // ----------------------------------------------------------------
  wire R1 = a_in[7] ^ a_in[5];
  wire R2 = ~(a_in[7] ^ a_in[4]);   // XNOR
  wire R3 = a_in[6] ^ a_in[0];
  wire R4 = ~(a_in[5] ^ R3);        // XNOR
  wire R5 = a_in[4] ^ R4;
  wire R6 = a_in[3] ^ a_in[0];
  wire R7 = a_in[2] ^ R1;
  wire R8 = a_in[1] ^ R3;
  wire R9 = a_in[3] ^ R8;

  wire [7:0] B;
  assign B[7] = ~(R7 ^ R8);         // XNOR
  assign B[6] = R5;
  assign B[5] = a_in[1] ^ R4;
  assign B[4] = ~(R1 ^ R3);         // XNOR
  assign B[3] = a_in[1] ^ R2 ^ R6;
  assign B[2] = ~a_in[0];           // NOT
  assign B[1] = R4;
  assign B[0] = ~(a_in[2] ^ R9);    // XNOR

  // ----------------------------------------------------------------
  // Step 2: SELECT_NOT_8 (encrypt=1): Z = ~B
  // ----------------------------------------------------------------
  wire [7:0] Z = ~B;

  // ----------------------------------------------------------------
  // Step 3: GF_INV_8 in tower field
  // ----------------------------------------------------------------
  wire [7:0] C;
  aes_gf8_inv inv (.a(Z), .a_inv(C));

  // ----------------------------------------------------------------
  // Step 4: Output basis change + AES affine (D equations)
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

  wire [7:0] D;
  assign D[7] = T4;
  assign D[6] = T1;
  assign D[5] = T3;
  assign D[4] = T5;
  assign D[3] = T2 ^ T5;
  assign D[2] = T3 ^ T8;
  assign D[1] = T7;
  assign D[0] = T9;

  // ----------------------------------------------------------------
  // Step 5: SELECT_NOT_8 (encrypt=1): s_out = ~D
  // ----------------------------------------------------------------
  assign s_out = ~D;

endmodule
