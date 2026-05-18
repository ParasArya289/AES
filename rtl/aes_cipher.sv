import aes_const::*;
import aes_wire::*;

module aes_cipher(
  input logic rst,
  input logic clk,
  input logic [31:0] KExp [0:(Nb*(Nr+1)-1)],
  input logic [7 : 0] Data_in [0:(4*Nb-1)],
  input logic [0 : 0] Enable,
  output logic [7 : 0] Data_out [0:(4*Nb-1)],
  output logic [0 : 0] Ready_out
);
  timeunit 1ns;
  timeprecision 1ps;

  genvar i;

  logic [7 : 0] State [0:Nr-1][0:(4*Nb-1)];
  logic [7 : 0] State_Reg [0:Nr-1][0:(4*Nb-1)];

  logic [0 : 0] Ready [0:Nr-1];
  logic [0 : 0] Ready_Reg [0:Nr-1];

  logic [7 : 0] sbyte_in_muxed [0:Nr-1][0:(4*Nb-1)];

  aes_arkey aes_arkey_comp
  (
    .State_in (Data_in),
    .KExp (KExp),
    .Index (4'h0),
    .State_out (State[0])
  );
  always_comb begin
    Ready[0] = Enable;
  end

  // Stage 0: CE = Enable to seed; OR Ready_Reg[0] allows self-flush
  always_ff @(posedge clk) begin
    if (rst == 0) begin
      Ready_Reg[0] <= '0;
    end else if (Enable || Ready_Reg[0]) begin
      State_Reg[0] <= State[0];
      Ready_Reg[0] <= Ready[0];
    end
  end

  generate
    for (i=2; i<Nr; i=i+1) begin
      always_ff @(posedge clk) begin
        if (rst == 0) begin
          Ready_Reg[i-1] <= '0;
        end else if (Ready_Reg[i-2] || Ready_Reg[i-1]) begin
          State_Reg[i-1] <= State[i-1];
          Ready_Reg[i-1] <= Ready[i-1];
        end
      end
      assign sbyte_in_muxed[i-1] = Ready_Reg[i-1] ? State_Reg[i-1] : '{default:'0};
      aes_round aes_round_comp
      (
        .State_in (sbyte_in_muxed[i-1]),
        .Index (i[3:0]),
        .KExp (KExp),
        .State_out (State[i])
      );
      always_comb begin
        Ready[i] = Ready_Reg[i-1];
      end
    end
  endgenerate;

  // Round 1 instantiation (outside loop since loop starts at i=2)
  assign sbyte_in_muxed[0] = Ready_Reg[0] ? State_Reg[0] : '{default:'0};
  aes_round aes_round1_comp
  (
    .State_in (sbyte_in_muxed[0]),
    .Index (4'h1),
    .KExp (KExp),
    .State_out (State[1])
  );
  always_comb begin
    Ready[1] = Ready_Reg[0];
  end

  always_ff @(posedge clk) begin
    if (rst == 0) begin
      Ready_Reg[Nr-1] <= '0;
    end else if (Ready_Reg[Nr-2] || Ready_Reg[Nr-1]) begin
      State_Reg[Nr-1] <= State[Nr-1];
      Ready_Reg[Nr-1] <= Ready[Nr-1];
    end
  end
  assign sbyte_in_muxed[Nr-1] = Ready_Reg[Nr-1] ? State_Reg[Nr-1] : '{default:'0};
  aes_fround aes_fround_comp
  (
    .State_in (sbyte_in_muxed[Nr-1]),
    .Index (Nr[3:0]),
    .KExp (KExp),
    .State_out (Data_out)
  );
  always_comb begin
    Ready_out = Ready_Reg[Nr-1];
  end

endmodule
