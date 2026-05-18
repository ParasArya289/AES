import aes_const::*;
import aes_wire::*;

module aes_unified_state(
  input  logic rst,
  input  logic clk,
  input  logic [31:0] KExp [0:(Nb*(Nr+1)-1)],
  input  logic [7 : 0] Data_in  [0:(4*Nb-1)],
  input  logic [0 : 0] Direction_in,
  input  logic [0 : 0] Enable,
  output logic [7 : 0] Data_out [0:(4*Nb-1)],
  output logic [0 : 0] Ready_out
);
  timeunit 1ns;
  timeprecision 1ps;

  typedef struct packed{
    logic [3:0] state;
    logic [0:0] ready;
  } reg_type;

  reg_type init_reg = '{
    state : 4'hF,
    ready : 0
  };

  reg_type r, rin;
  reg_type v;

  logic direction_r;   // D-02: separate register, NOT in reg_type

  // Enc sub-module signals
  logic [7 : 0] State_B_in  [0:(4*Nb-1)];  // sbyte input
  logic [7 : 0] State_R_in  [0:(4*Nb-1)];  // srow input
  logic [7 : 0] State_M_in  [0:(4*Nb-1)];  // mcol input
  logic [7 : 0] State_B_out [0:(4*Nb-1)];
  logic [7 : 0] State_R_out [0:(4*Nb-1)];
  logic [7 : 0] State_M_out [0:(4*Nb-1)];

  // Dec sub-module signals (I-prefix, distinct from enc)
  logic [7 : 0] State_IB_in  [0:(4*Nb-1)];  // isbyte input
  logic [7 : 0] State_IR_in  [0:(4*Nb-1)];  // isrow input
  logic [7 : 0] State_IM_in  [0:(4*Nb-1)];  // imcol input
  logic [7 : 0] State_IB_out [0:(4*Nb-1)];
  logic [7 : 0] State_IR_out [0:(4*Nb-1)];
  logic [7 : 0] State_IM_out [0:(4*Nb-1)];

  // Shared arkey signals
  logic [7 : 0] State_A_in  [0:(4*Nb-1)];
  logic [7 : 0] State_A_out [0:(4*Nb-1)];

  // Shared state register signals
  logic [7 : 0] State_P [0:(4*Nb-1)];
  logic [7 : 0] State_N [0:(4*Nb-1)];

  logic [3 : 0] Index;

  initial begin
    State_P = '{default:'0};
    State_N = '{default:'0};
  end

  always_comb begin

    v = r;

    // Default: operand isolation (CG-04 pattern)
    State_B_in  = '{default:'0};
    State_R_in  = '{default:'0};
    State_M_in  = '{default:'0};
    State_IB_in = '{default:'0};
    State_IR_in = '{default:'0};
    State_IM_in = '{default:'0};
    State_A_in  = '{default:'0};
    State_P     = '{default:'0};
    Index       = 4'h0;

    case (r.state)

      4'hF : begin                   // IDLE
        v.ready = 0;
        if (Enable == 1) begin
          // Use Direction_in directly (direction_r lags one cycle behind Enable)
          v.state = Direction_in ? (Nr - 1) : 1;
        end
        // Initial AddRoundKey: enc uses Index=0, dec uses Index=Nr
        // Use Direction_in directly here too — direction_r is stale on first Enable cycle
        State_A_in = Data_in;
        State_P    = State_A_out;
        Index      = Direction_in ? Nr[3:0] : 4'h0;
      end

      Nr : begin                     // Enc terminal: SubBytes+ShiftRows+AddRoundKey, no MixColumns
        v.state    = 4'hF;
        v.ready    = 1;
        State_B_in = State_N;
        State_R_in = State_B_out;
        State_M_in = '{default:'0};
        State_A_in = State_R_out;
        State_P    = State_A_out;
        Index      = Nr[3:0];
      end

      0 : begin                      // Dec terminal: InvShiftRows+InvSubBytes+AddRoundKey, no InvMixColumns
        v.state     = 4'hF;
        v.ready     = 1;
        State_IR_in = State_N;
        State_IB_in = State_IR_out;
        State_A_in  = State_IB_out;
        State_IM_in = '{default:'0};
        State_P     = State_A_out;
        Index       = 4'h0;
      end

      default: begin                 // Active rounds: enc 1..Nr-1, dec Nr-1..1
        v.ready = 0;
        if (!direction_r) begin      // enc: count up, B->R->M->A
          v.state    = v.state + 1;
          State_B_in = State_N;
          State_R_in = State_B_out;
          State_M_in = State_R_out;
          State_A_in = State_M_out;
          State_P    = State_A_out;
          Index      = r.state;
        end else begin               // dec: count down, IR->IB->A->IM
          v.state     = v.state - 1;
          State_IR_in = State_N;
          State_IB_in = State_IR_out;
          State_A_in  = State_IB_out;
          State_IM_in = State_A_out;
          State_P     = State_IM_out;
          Index       = r.state;  // dec key index: state descends Nr-1..1, matching key schedule
        end
      end

    endcase

    rin = v;

    Data_out  = State_N;
    Ready_out = r.ready;

  end

  always_ff @(posedge clk) begin
    if (rst == 0) begin
      State_N <= '{default:'0};
    end else if (r.state != 4'hF || r.ready == 1 || Enable == 1) begin
      State_N <= State_P;
    end
  end

  // Enc sub-modules
  aes_sbyte  aes_sbyte_comp  (.State_in(State_B_in),   .State_out(State_B_out));
  aes_srow   aes_srow_comp   (.State_in(State_R_in),   .State_out(State_R_out));
  aes_mcol   aes_mcol_comp   (.State_in(State_M_in),   .State_out(State_M_out));

  // Dec sub-modules
  aes_isbyte aes_isbyte_comp (.State_in(State_IB_in),  .State_out(State_IB_out));
  aes_isrow  aes_isrow_comp  (.State_in(State_IR_in),  .State_out(State_IR_out));
  aes_imcol  aes_imcol_comp  (.State_in(State_IM_in),  .State_out(State_IM_out));

  // Shared arkey (single instance per D-05)
  aes_arkey  aes_arkey_comp  (
    .State_in (State_A_in),
    .KExp     (KExp),
    .Index    (Index),
    .State_out(State_A_out)
  );

  // direction_r register (D-02): separate always_ff, updates on Enable only
  always_ff @(posedge clk) begin
    if (Enable == 1) direction_r <= Direction_in;
  end

  // r register CE guard (D-07): 4'hF substituted for 0/Nr
  always_ff @(posedge clk) begin
    if (rst == 0) begin
      r <= init_reg;
    end else if (r.state != 4'hF || r.ready == 1 || Enable == 1) begin
      r <= rin;
    end
  end

endmodule
