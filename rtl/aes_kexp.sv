import aes_const::*;
import aes_wire::*;

module aes_kexp
(
  input logic rst,
  input logic clk,
  input logic [7:0] Key [0:(4*Nk-1)],
  input logic [0:0] Enable,
  output logic [31:0] KExp [0:(Nb*(Nr+1)-1)],
  output logic [0 : 0] Ready_out
);
  timeunit 1ns;
  timeprecision 1ps;

  localparam logic [7:0] rcon [0:15] = '{
    8'h00,8'h01,8'h02,8'h04,8'h08,8'h10,8'h20,8'h40,
    8'h80,8'h1b,8'h36,8'h6c,8'hd8,8'hab,8'h4d,8'h9a
  };

  localparam Nx = ((Nb*(Nr+1))+Nk-1)/Nk;

  logic [31 : 0] KExp_R [0:(Nb*(Nr+1)-1)];

  logic [31 : 0] KExp_P [0:(Nx-1)][0:(Nk-1)];
  logic [31 : 0] KExp_N [0:(Nx-1)][0:(Nk-1)];

  logic [0 : 0] Ready_P [0:(Nx-1)];
  logic [0 : 0] Ready_N [0:(Nx-1)];

  function [31:0] RotWord;
    input [31:0] Word;
    begin
      RotWord = {Word[23:0],Word[31:24]};
    end
  endfunction

  function [31:0] Min;
    input [31:0] A;
    input [31:0] B;
    begin
      if (A>B) begin
        Min = B;
      end else begin
        Min = A;
      end
    end
  endfunction

  initial begin
    KExp_P = '{default:'{default:'0}};
    KExp_N = '{default:'{default:'0}};
  end

  genvar i,j;

  generate
    for (i = 0; i < Nk; i = i + 1) begin
      always_comb begin
        if (Enable == 1) begin
          KExp_P[0][i] = {Key[4*i],Key[4*i+1],Key[4*i+2],Key[4*i+3]};
        end
      end
    end
  endgenerate
  always_comb begin
    KExp_R[0:(Nk-1)] = KExp_P[0];
    Ready_P[0] = Enable;
  end
  always_ff @(posedge clk) begin
    if (rst == 0) begin
      KExp_N[0] <= '{default:'{default:'0}};
      Ready_N[0] <= '0;
    end else if (Enable || Ready_N[0]) begin
      KExp_N[0] <= KExp_P[0];
      Ready_N[0] <= Ready_P[0];
    end
  end

  generate
    for (i = 1; i < Nx; i = i + 1) begin
      // CFA S-Box instances for RotWord path (j==0)
      wire [31:0] sw_in_i;
      wire [31:0] sw_out_i;
      aes_cfa_sbox sw_i0(.a_in(sw_in_i[31:24]), .s_out(sw_out_i[31:24]));
      aes_cfa_sbox sw_i1(.a_in(sw_in_i[23:16]), .s_out(sw_out_i[23:16]));
      aes_cfa_sbox sw_i2(.a_in(sw_in_i[15: 8]), .s_out(sw_out_i[15: 8]));
      aes_cfa_sbox sw_i3(.a_in(sw_in_i[ 7: 0]), .s_out(sw_out_i[ 7: 0]));
      assign sw_in_i = RotWord(KExp_P[i-1][Nk-1]);

      // CFA S-Box instances for AES-256 j==4 path
      wire [31:0] sw_in_i2;
      wire [31:0] sw_out_i2;
      aes_cfa_sbox sw_i4(.a_in(sw_in_i2[31:24]), .s_out(sw_out_i2[31:24]));
      aes_cfa_sbox sw_i5(.a_in(sw_in_i2[23:16]), .s_out(sw_out_i2[23:16]));
      aes_cfa_sbox sw_i6(.a_in(sw_in_i2[15: 8]), .s_out(sw_out_i2[15: 8]));
      aes_cfa_sbox sw_i7(.a_in(sw_in_i2[ 7: 0]), .s_out(sw_out_i2[ 7: 0]));

      for (j = 0; j < Nk; j = j + 1) begin
        if (j % Nk == 0) begin
          assign KExp_P[i][j] = KExp_N[i-1][j] ^ sw_out_i ^ {rcon[i],24'h0};
        end else if (Nk > 6 && j % Nk == 4) begin
          assign sw_in_i2 = KExp_P[i][j-1];
          assign KExp_P[i][j] = KExp_N[i-1][j] ^ sw_out_i2;
        end else begin
          assign KExp_P[i][j] = KExp_N[i-1][j] ^ KExp_P[i][j-1];
        end
      end
      always_comb begin
        KExp_R[Nk*i:(Min(Nk*(i+1),Nb*(Nr+1))-1)] = KExp_P[i][0:(Min(Nk*(i+1),Nb*(Nr+1))-Nk*i-1)];
        Ready_P[i] = Ready_N[i-1];
      end
      always_ff @(posedge clk) begin
        if (rst == 0) begin
          KExp_N[i] <= '{default:'{default:'0}};
          Ready_N[i] <= '0;
        end else if (Ready_N[i-1]) begin
          KExp_N[i] <= KExp_P[i];
          Ready_N[i] <= Ready_P[i];
        end
      end
    end
  endgenerate

  always_comb begin
    KExp = KExp_R;
    Ready_out = Ready_N[Nx-1];
  end

endmodule
