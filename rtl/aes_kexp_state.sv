import aes_const::*;
import aes_wire::*;

module aes_kexp_state
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

  logic [31 : 0] KExp_R [0:(Nb*(Nr+1)-1)];
  logic [31 : 0] KExp_P [0:(Nk-1)];
  logic [31 : 0] KExp_N [0:(Nk-1)];

  localparam LENGTH = (Nb*(Nr+1));
  localparam WIDTH = $clog2(LENGTH);

  typedef struct packed{
    logic [3:0] state;
    logic [(WIDTH-1):0] index;
    logic [0:0] enable;
    logic [0:0] ready;
  } reg_type;

  reg_type init_reg = '{
    state : 0,
    index : 0,
    enable : 0,
    ready : 0
  };

  reg_type r,rin;
  reg_type v;

  function [31:0] RotWord;
    input [31:0] Word;
    begin
      RotWord = {Word[23:0],Word[31:24]};
    end
  endfunction

  // CFA S-Box for RotWord(KExp_N[Nk-1]) — j==0 path
  // Driven combinationally from registered KExp_N so sw_out_rot is valid when always_comb reads it
  logic [31:0] sw_in_rot;
  logic [31:0] sw_out_rot;
  assign sw_in_rot = RotWord(KExp_N[Nk-1]);
  aes_cfa_sbox sw0(.a_in(sw_in_rot[31:24]), .s_out(sw_out_rot[31:24]));
  aes_cfa_sbox sw1(.a_in(sw_in_rot[23:16]), .s_out(sw_out_rot[23:16]));
  aes_cfa_sbox sw2(.a_in(sw_in_rot[15: 8]), .s_out(sw_out_rot[15: 8]));
  aes_cfa_sbox sw3(.a_in(sw_in_rot[ 7: 0]), .s_out(sw_out_rot[ 7: 0]));

  // CFA S-Box for AES-256 j==4 path: input is KExp_P[3] (combinational)
  logic [31:0] sw_out_256;
  aes_cfa_sbox sw4(.a_in(KExp_P[3][31:24]), .s_out(sw_out_256[31:24]));
  aes_cfa_sbox sw5(.a_in(KExp_P[3][23:16]), .s_out(sw_out_256[23:16]));
  aes_cfa_sbox sw6(.a_in(KExp_P[3][15: 8]), .s_out(sw_out_256[15: 8]));
  aes_cfa_sbox sw7(.a_in(KExp_P[3][ 7: 0]), .s_out(sw_out_256[ 7: 0]));

  initial begin
    KExp_P = '{default:'0};
    KExp_N = '{default:'0};
  end

  always_comb begin

    v = r;

    case (r.state)
      0 : begin
        v.index = 0;
        v.enable = 0;
        v.ready = 0;
        if (Enable == 1) begin
          v.state = 1;
          v.enable = 1;
          for (int i=0; i<Nk; i=i+1) begin
            KExp_P[i] = {Key[4*i],Key[4*i+1],Key[4*i+2],Key[4*i+3]};
          end
        end
      end
      default : begin
        for (int i=0; i<Nk; i=i+1) begin
          if (i == 0) begin
            KExp_P[i] = KExp_N[i] ^ sw_out_rot ^ {rcon[v.state],24'h0};
          end else if (Nk > 6 && i == 4) begin
            KExp_P[i] = KExp_N[i] ^ sw_out_256;
          end else begin
            KExp_P[i] = KExp_N[i] ^ KExp_P[i-1];
          end
        end
        if (v.index > (Nb*(Nr+1)-Nk)) begin
          v.state = 0;
          v.ready = 1;
        end else begin
          v.state = v.state + 1;
          v.ready = 0;
        end
      end
    endcase

    for (int i=0; i<Nk; i=i+1) begin
      if (((v.index+i[(WIDTH-1):0]) < Nb*(Nr+1)) && (v.enable == 1)) begin
        KExp_R[v.index+i[(WIDTH-1):0]] = KExp_P[i];
      end
    end

    v.index = v.index + Nk;

    rin = v;

    KExp = KExp_R;
    Ready_out = r.ready;

  end

  always_ff @(posedge clk) begin
    if (r.state != 0 || Enable == 1) begin
      KExp_N <= KExp_P;
    end
  end

  always_ff @(posedge clk) begin
    if (rst == 0) begin
      r <= init_reg;
    end else if (r.state != 0 || r.ready == 1 || Enable == 1) begin
      r <= rin;
    end
  end

endmodule
