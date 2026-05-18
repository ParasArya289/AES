import aes_const::*;
import aes_wire::*;

module aes_mcol
(
  input logic [7:0] State_in [0:(4*Nb-1)],
  output logic [7:0] State_out [0:(4*Nb-1)]
);
  timeunit 1ns;
  timeprecision 1ps;

  // xtime: multiply each byte by 2 in GF(2^8), reduction polynomial 0x1B
  logic [7:0] xt2 [0:(4*Nb-1)];

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

  always_comb begin
    for (int i=0; i<Nb; i = i + 1) begin
      // MixColumns matrix: [2,3,1,1; 1,2,3,1; 1,1,2,3; 3,1,1,2]
      // x2(s) = xt2[idx], x3(s) = xt2[idx] ^ State_in[idx]
      State_out[4*i]   = xt2[4*i]                           ^ (xt2[4*i+1] ^ State_in[4*i+1]) ^ State_in[4*i+2]                      ^ State_in[4*i+3];
      State_out[4*i+1] = State_in[4*i]                      ^ xt2[4*i+1]                      ^ (xt2[4*i+2] ^ State_in[4*i+2])       ^ State_in[4*i+3];
      State_out[4*i+2] = State_in[4*i]                      ^ State_in[4*i+1]                 ^ xt2[4*i+2]                           ^ (xt2[4*i+3] ^ State_in[4*i+3]);
      State_out[4*i+3] = (xt2[4*i] ^ State_in[4*i])        ^ State_in[4*i+1]                 ^ State_in[4*i+2]                      ^ xt2[4*i+3];
    end
  end


endmodule
