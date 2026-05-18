import aes_const::*;
import aes_wire::*;

module aes_imcol
(
  input logic [7:0] State_in [0:(4*Nb-1)],
  output logic [7:0] State_out [0:(4*Nb-1)]
);
  timeunit 1ns;
  timeprecision 1ps;

  // Chained xtime: x2, x4=x2^2, x8=x4^2 in GF(2^8), reduction polynomial 0x1B
  logic [7:0] xt2 [0:(4*Nb-1)];
  logic [7:0] xt4 [0:(4*Nb-1)];
  logic [7:0] xt8 [0:(4*Nb-1)];

  assign xt2[0]  = {State_in[0][6:0],  1'b0} ^ (State_in[0][7]  ? 8'h1b : 8'h00);
  assign xt2[1]  = {State_in[1][6:0],  1'b0} ^ (State_in[1][7]  ? 8'h1b : 8'h00);
  assign xt2[2]  = {State_in[2][6:0],  1'b0} ^ (State_in[2][7]  ? 8'h1b : 8'h00);
  assign xt2[3]  = {State_in[3][6:0],  1'b0} ^ (State_in[3][7]  ? 8'h1b : 8'h00);
  assign xt2[4]  = {State_in[4][6:0],  1'b0} ^ (State_in[4][7]  ? 8'h1b : 8'h00);
  assign xt2[5]  = {State_in[5][6:0],  1'b0} ^ (State_in[5][7]  ? 8'h1b : 8'h00);
  assign xt2[6]  = {State_in[6][6:0],  1'b0} ^ (State_in[6][7]  ? 8'h1b : 8'h00);
  assign xt2[7]  = {State_in[7][6:0],  1'b0} ^ (State_in[7][7]  ? 8'h1b : 8'h00);
  assign xt2[8]  = {State_in[8][6:0],  1'b0} ^ (State_in[8][7]  ? 8'h1b : 8'h00);
  assign xt2[9]  = {State_in[9][6:0],  1'b0} ^ (State_in[9][7]  ? 8'h1b : 8'h00);
  assign xt2[10] = {State_in[10][6:0], 1'b0} ^ (State_in[10][7] ? 8'h1b : 8'h00);
  assign xt2[11] = {State_in[11][6:0], 1'b0} ^ (State_in[11][7] ? 8'h1b : 8'h00);
  assign xt2[12] = {State_in[12][6:0], 1'b0} ^ (State_in[12][7] ? 8'h1b : 8'h00);
  assign xt2[13] = {State_in[13][6:0], 1'b0} ^ (State_in[13][7] ? 8'h1b : 8'h00);
  assign xt2[14] = {State_in[14][6:0], 1'b0} ^ (State_in[14][7] ? 8'h1b : 8'h00);
  assign xt2[15] = {State_in[15][6:0], 1'b0} ^ (State_in[15][7] ? 8'h1b : 8'h00);

  assign xt4[0]  = {xt2[0][6:0],  1'b0} ^ (xt2[0][7]  ? 8'h1b : 8'h00);
  assign xt4[1]  = {xt2[1][6:0],  1'b0} ^ (xt2[1][7]  ? 8'h1b : 8'h00);
  assign xt4[2]  = {xt2[2][6:0],  1'b0} ^ (xt2[2][7]  ? 8'h1b : 8'h00);
  assign xt4[3]  = {xt2[3][6:0],  1'b0} ^ (xt2[3][7]  ? 8'h1b : 8'h00);
  assign xt4[4]  = {xt2[4][6:0],  1'b0} ^ (xt2[4][7]  ? 8'h1b : 8'h00);
  assign xt4[5]  = {xt2[5][6:0],  1'b0} ^ (xt2[5][7]  ? 8'h1b : 8'h00);
  assign xt4[6]  = {xt2[6][6:0],  1'b0} ^ (xt2[6][7]  ? 8'h1b : 8'h00);
  assign xt4[7]  = {xt2[7][6:0],  1'b0} ^ (xt2[7][7]  ? 8'h1b : 8'h00);
  assign xt4[8]  = {xt2[8][6:0],  1'b0} ^ (xt2[8][7]  ? 8'h1b : 8'h00);
  assign xt4[9]  = {xt2[9][6:0],  1'b0} ^ (xt2[9][7]  ? 8'h1b : 8'h00);
  assign xt4[10] = {xt2[10][6:0], 1'b0} ^ (xt2[10][7] ? 8'h1b : 8'h00);
  assign xt4[11] = {xt2[11][6:0], 1'b0} ^ (xt2[11][7] ? 8'h1b : 8'h00);
  assign xt4[12] = {xt2[12][6:0], 1'b0} ^ (xt2[12][7] ? 8'h1b : 8'h00);
  assign xt4[13] = {xt2[13][6:0], 1'b0} ^ (xt2[13][7] ? 8'h1b : 8'h00);
  assign xt4[14] = {xt2[14][6:0], 1'b0} ^ (xt2[14][7] ? 8'h1b : 8'h00);
  assign xt4[15] = {xt2[15][6:0], 1'b0} ^ (xt2[15][7] ? 8'h1b : 8'h00);

  assign xt8[0]  = {xt4[0][6:0],  1'b0} ^ (xt4[0][7]  ? 8'h1b : 8'h00);
  assign xt8[1]  = {xt4[1][6:0],  1'b0} ^ (xt4[1][7]  ? 8'h1b : 8'h00);
  assign xt8[2]  = {xt4[2][6:0],  1'b0} ^ (xt4[2][7]  ? 8'h1b : 8'h00);
  assign xt8[3]  = {xt4[3][6:0],  1'b0} ^ (xt4[3][7]  ? 8'h1b : 8'h00);
  assign xt8[4]  = {xt4[4][6:0],  1'b0} ^ (xt4[4][7]  ? 8'h1b : 8'h00);
  assign xt8[5]  = {xt4[5][6:0],  1'b0} ^ (xt4[5][7]  ? 8'h1b : 8'h00);
  assign xt8[6]  = {xt4[6][6:0],  1'b0} ^ (xt4[6][7]  ? 8'h1b : 8'h00);
  assign xt8[7]  = {xt4[7][6:0],  1'b0} ^ (xt4[7][7]  ? 8'h1b : 8'h00);
  assign xt8[8]  = {xt4[8][6:0],  1'b0} ^ (xt4[8][7]  ? 8'h1b : 8'h00);
  assign xt8[9]  = {xt4[9][6:0],  1'b0} ^ (xt4[9][7]  ? 8'h1b : 8'h00);
  assign xt8[10] = {xt4[10][6:0], 1'b0} ^ (xt4[10][7] ? 8'h1b : 8'h00);
  assign xt8[11] = {xt4[11][6:0], 1'b0} ^ (xt4[11][7] ? 8'h1b : 8'h00);
  assign xt8[12] = {xt4[12][6:0], 1'b0} ^ (xt4[12][7] ? 8'h1b : 8'h00);
  assign xt8[13] = {xt4[13][6:0], 1'b0} ^ (xt4[13][7] ? 8'h1b : 8'h00);
  assign xt8[14] = {xt4[14][6:0], 1'b0} ^ (xt4[14][7] ? 8'h1b : 8'h00);
  assign xt8[15] = {xt4[15][6:0], 1'b0} ^ (xt4[15][7] ? 8'h1b : 8'h00);

  always_comb begin
    for (int i=0; i<Nb; i = i + 1) begin
      // InvMixColumns matrix: [14,11,13,9; 9,14,11,13; 13,9,14,11; 11,13,9,14]
      // x9(s)  = xt8[idx] ^ State_in[idx]
      // x11(s) = xt8[idx] ^ xt2[idx] ^ State_in[idx]
      // x13(s) = xt8[idx] ^ xt4[idx] ^ State_in[idx]
      // x14(s) = xt8[idx] ^ xt4[idx] ^ xt2[idx]
      State_out[4*i]   = (xt8[4*i]   ^ xt4[4*i]   ^ xt2[4*i])
                       ^ (xt8[4*i+1] ^ xt2[4*i+1] ^ State_in[4*i+1])
                       ^ (xt8[4*i+2] ^ xt4[4*i+2] ^ State_in[4*i+2])
                       ^ (xt8[4*i+3] ^ State_in[4*i+3]);
      State_out[4*i+1] = (xt8[4*i]   ^ State_in[4*i])
                       ^ (xt8[4*i+1] ^ xt4[4*i+1] ^ xt2[4*i+1])
                       ^ (xt8[4*i+2] ^ xt2[4*i+2] ^ State_in[4*i+2])
                       ^ (xt8[4*i+3] ^ xt4[4*i+3] ^ State_in[4*i+3]);
      State_out[4*i+2] = (xt8[4*i]   ^ xt4[4*i]   ^ State_in[4*i])
                       ^ (xt8[4*i+1] ^ State_in[4*i+1])
                       ^ (xt8[4*i+2] ^ xt4[4*i+2] ^ xt2[4*i+2])
                       ^ (xt8[4*i+3] ^ xt2[4*i+3] ^ State_in[4*i+3]);
      State_out[4*i+3] = (xt8[4*i]   ^ xt2[4*i]   ^ State_in[4*i])
                       ^ (xt8[4*i+1] ^ xt4[4*i+1] ^ State_in[4*i+1])
                       ^ (xt8[4*i+2] ^ State_in[4*i+2])
                       ^ (xt8[4*i+3] ^ xt4[4*i+3] ^ xt2[4*i+3]);
    end
  end


endmodule
