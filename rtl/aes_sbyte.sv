import aes_const::*;
import aes_wire::*;

module aes_sbyte
(
  input  logic [7:0] State_in  [0:(4*Nb-1)],
  output logic [7:0] State_out [0:(4*Nb-1)]
);
  timeunit 1ns;
  timeprecision 1ps;

  genvar i;

  generate
    for (i = 0; i < 4*Nb; i = i + 1) begin : gen_cfa_sbox
      aes_cfa_sbox cell_i (
        .a_in  (State_in[i]),
        .s_out (State_out[i])
      );
    end
  endgenerate

endmodule
