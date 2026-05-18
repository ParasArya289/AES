// Exhaustive testbench for aes_gf8_inv.sv — all 256 inputs.
//
// aes_gf8_inv operates in GF((2^4)^2) normal basis, not polynomial basis.
// The full sbox pipeline is: basis_B(x) -> ~B -> gf8_inv -> C -> ~output_D(C)
// To test gf8_inv in isolation we drive it with ~basis_B(x) and verify
// that ~output_D(gf8_inv_out) == sbox[x].
//
// Oracle: AES S-Box reference table (FIPS-197).

module aes_gf8_inv_tb;
  timeunit 1ns;
  timeprecision 1ps;

  logic [7:0] a, a_inv;

  aes_gf8_inv dut (.a(a), .a_inv(a_inv));

  // Input basis change: GF(2^8) polynomial -> GF((2^4)^2) normal basis (B matrix)
  function automatic [7:0] basis_B(input [7:0] x);
    logic R1,R2,R3,R4,R5,R6,R7,R8,R9;
    R1=x[7]^x[5]; R2=~(x[7]^x[4]); R3=x[6]^x[0];
    R4=~(x[5]^R3); R5=x[4]^R4; R6=x[3]^x[0];
    R7=x[2]^R1; R8=x[1]^R3; R9=x[3]^R8;
    return {~(R7^R8), R5, x[1]^R4, ~(R1^R3),
             x[1]^R2^R6, ~x[0], R4, ~(x[2]^R9)};
  endfunction

  // Output D transform (combined output basis + affine, D path)
  function automatic [7:0] output_D(input [7:0] C);
    logic T1,T2,T3,T4,T5,T6,T7,T8,T9;
    T1=C[7]^C[3]; T2=C[6]^C[4]; T3=C[6]^C[0];
    T4=~(C[5]^C[3]); T5=~(C[5]^T1); T6=~(C[5]^C[1]);
    T7=~(C[4]^T6); T8=C[2]^T4; T9=C[1]^T2;
    return {T4, T1, T3, T5, T2^T5, T3^T8, T7, T9};
  endfunction

  // AES S-Box reference (FIPS-197)
  logic [7:0] sbox_ref [0:255];
  integer i, errors;

  initial begin
    sbox_ref = '{
      8'h63,8'h7c,8'h77,8'h7b,8'hf2,8'h6b,8'h6f,8'hc5,8'h30,8'h01,8'h67,8'h2b,8'hfe,8'hd7,8'hab,8'h76,
      8'hca,8'h82,8'hc9,8'h7d,8'hfa,8'h59,8'h47,8'hf0,8'had,8'hd4,8'ha2,8'haf,8'h9c,8'ha4,8'h72,8'hc0,
      8'hb7,8'hfd,8'h93,8'h26,8'h36,8'h3f,8'hf7,8'hcc,8'h34,8'ha5,8'he5,8'hf1,8'h71,8'hd8,8'h31,8'h15,
      8'h04,8'hc7,8'h23,8'hc3,8'h18,8'h96,8'h05,8'h9a,8'h07,8'h12,8'h80,8'he2,8'heb,8'h27,8'hb2,8'h75,
      8'h09,8'h83,8'h2c,8'h1a,8'h1b,8'h6e,8'h5a,8'ha0,8'h52,8'h3b,8'hd6,8'hb3,8'h29,8'he3,8'h2f,8'h84,
      8'h53,8'hd1,8'h00,8'hed,8'h20,8'hfc,8'hb1,8'h5b,8'h6a,8'hcb,8'hbe,8'h39,8'h4a,8'h4c,8'h58,8'hcf,
      8'hd0,8'hef,8'haa,8'hfb,8'h43,8'h4d,8'h33,8'h85,8'h45,8'hf9,8'h02,8'h7f,8'h50,8'h3c,8'h9f,8'ha8,
      8'h51,8'ha3,8'h40,8'h8f,8'h92,8'h9d,8'h38,8'hf5,8'hbc,8'hb6,8'hda,8'h21,8'h10,8'hff,8'hf3,8'hd2,
      8'hcd,8'h0c,8'h13,8'hec,8'h5f,8'h97,8'h44,8'h17,8'hc4,8'ha7,8'h7e,8'h3d,8'h64,8'h5d,8'h19,8'h73,
      8'h60,8'h81,8'h4f,8'hdc,8'h22,8'h2a,8'h90,8'h88,8'h46,8'hee,8'hb8,8'h14,8'hde,8'h5e,8'h0b,8'hdb,
      8'he0,8'h32,8'h3a,8'h0a,8'h49,8'h06,8'h24,8'h5c,8'hc2,8'hd3,8'hac,8'h62,8'h91,8'h95,8'he4,8'h79,
      8'he7,8'hc8,8'h37,8'h6d,8'h8d,8'hd5,8'h4e,8'ha9,8'h6c,8'h56,8'hf4,8'hea,8'h65,8'h7a,8'hae,8'h08,
      8'hba,8'h78,8'h25,8'h2e,8'h1c,8'ha6,8'hb4,8'hc6,8'he8,8'hdd,8'h74,8'h1f,8'h4b,8'hbd,8'h8b,8'h8a,
      8'h70,8'h3e,8'hb5,8'h66,8'h48,8'h03,8'hf6,8'h0e,8'h61,8'h35,8'h57,8'hb9,8'h86,8'hc1,8'h1d,8'h9e,
      8'he1,8'hf8,8'h98,8'h11,8'h69,8'hd9,8'h8e,8'h94,8'h9b,8'h1e,8'h87,8'he9,8'hce,8'h55,8'h28,8'hdf,
      8'h8c,8'ha1,8'h89,8'h0d,8'hbf,8'he6,8'h42,8'h68,8'h41,8'h99,8'h2d,8'h0f,8'hb0,8'h54,8'hbb,8'h16
    };

    errors = 0;

    // Drive with ~basis_B(x), verify ~output_D(result) == sbox[x]
    for (i = 0; i < 256; i++) begin
      a = ~basis_B(i[7:0]); #1;
      if (~output_D(a_inv) !== sbox_ref[i]) begin
        $display("FAIL: sbox pipeline check for x=0x%02x: got 0x%02x, expected 0x%02x",
                 i, ~output_D(a_inv), sbox_ref[i]);
        errors++;
      end
    end

    if (errors == 0)
      $display("PASS: aes_gf8_inv — all 256 inputs correct (0 errors)");
    else
      $display("FAIL: aes_gf8_inv — %0d errors", errors);
    $finish;
  end

endmodule
