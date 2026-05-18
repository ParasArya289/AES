import aes_const::*;
import aes_wire::*;

module aes_icipher(
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

  logic [7 : 0] isbyte_in_muxed [0:Nr-1][0:(4*Nb-1)];

  aes_arkey aes_arkey_comp
  (
    .State_in (Data_in),
    .KExp (KExp),
    .Index (Nr[3:0]),
    .State_out (State[Nr-1])
  );
  always_comb begin
    Ready[Nr-1] = Enable;
  end

  // Stage Nr-1: CE = Enable to seed; OR Ready_Reg[Nr-1] allows self-flush
  always_ff @(posedge clk) begin
    if (rst == 0) begin
      Ready_Reg[Nr-1] <= '0;
    end else if (Enable || Ready_Reg[Nr-1]) begin
      State_Reg[Nr-1] <= State[Nr-1];
      Ready_Reg[Nr-1] <= Ready[Nr-1];
    end
  end

  // Round Nr-1 instantiation (outside loop since loop starts at i=Nr-2)
  assign isbyte_in_muxed[Nr-1] = Ready_Reg[Nr-1] ? State_Reg[Nr-1] : '{default:'0};
  aes_iround aes_iround_top_comp
  (
    .State_in (isbyte_in_muxed[Nr-1]),
    .Index (4'(Nr-1)),
    .KExp (KExp),
    .State_out (State[Nr-2])
  );
  always_comb begin
    Ready[Nr-2] = Ready_Reg[Nr-1];
  end

  generate
    for (i=Nr-2; i>0; i=i-1) begin
      always_ff @(posedge clk) begin
        if (rst == 0) begin
          Ready_Reg[i] <= '0;
        end else if (Ready_Reg[i+1] || Ready_Reg[i]) begin
          State_Reg[i] <= State[i];
          Ready_Reg[i] <= Ready[i];
        end
      end
      assign isbyte_in_muxed[i] = Ready_Reg[i] ? State_Reg[i] : '{default:'0};
      aes_iround aes_iround_comp
      (
        .State_in (isbyte_in_muxed[i]),
        .Index (i[3:0]),
        .KExp (KExp),
        .State_out (State[i-1])
      );
      always_comb begin
        Ready[i-1] = Ready_Reg[i];
      end
    end
  endgenerate;

  always_ff @(posedge clk) begin
    if (rst == 0) begin
      Ready_Reg[0] <= '0;
    end else if (Ready_Reg[1] || Ready_Reg[0]) begin
      State_Reg[0] <= State[0];
      Ready_Reg[0] <= Ready[0];
    end
  end
  assign isbyte_in_muxed[0] = Ready_Reg[0] ? State_Reg[0] : '{default:'0};
  aes_ifround aes_ifround_comp
  (
    .State_in (isbyte_in_muxed[0]),
    .Index (4'h0),
    .KExp (KExp),
    .State_out (Data_out)
  );
  always_comb begin
    Ready_out = Ready_Reg[0];
  end

endmodule
