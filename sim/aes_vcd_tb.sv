// VCD stimulus testbench: Active→Idle×N burst pattern for switching-activity annotation.
// Drives AES FSM (aes_state) or pipeline (aes) depending on enable_pipeline parameter.
// Pattern per burst: key-expand → encrypt → IDLE_CYCLES idle → decrypt → IDLE_CYCLES idle
// Three full bursts are run to give Vivado a representative activity window.

import aes_const::*;
import aes_wire::*;

module aes_vcd_tb(
  input logic rst,
  input logic clk
);

  timeunit 1ns;
  timeprecision 1ps;

  // ---- parameters -------------------------------------------------------
  parameter enable_pipeline = 0;

  // Number of idle cycles inserted between active operations.
  // 20 cycles is long enough that CE-gated FFs are clearly idle in the VCD.
  parameter IDLE_CYCLES = 20;

  // Number of burst repetitions (Active→Idle×3 = 3 repetitions).
  parameter NUM_BURSTS = 3;

  // Keep inputs changing during idle while aes_in.enable remains low. This
  // stresses CE-gated registers without changing active AES transactions.
  parameter IDLE_INPUT_NOISE = 1;

  // ---- DUT I/O -----------------------------------------------------------
  aes_in_type  aes_in;
  aes_out_type aes_out;

  // ---- internal state ----------------------------------------------------
  logic [(32*Nb-1):0] result;
  logic [0:0] enable_r;

  integer state;      // 0=kexp, 1=enc, 2=dec, 3=idle_post_enc, 4=idle_post_dec
  integer idle_cnt;
  integer burst_cnt;

  logic [(32*Nb-1):0] idle_noise_data;
  logic [(32*Nk-1):0] idle_noise_key;

  // Hard-coded NIST test vector (AES-128)
  // Key:       dffe1e8f4824951ba6d3bf8b46e53c4d
  // Plaintext: bab8d38cebb576d489d7606e10784ddc
  // Ciphertext:09036baae31b28e2b6878d016358b083
  logic [(32*Nk-1):0] TEST_KEY;
  logic [(32*Nb-1):0] TEST_DATA;

  initial begin
    TEST_KEY  = 128'hdffe1e8f4824951ba6d3bf8b46e53c4d;
    TEST_DATA = 128'hbab8d38cebb576d489d7606e10784ddc;
  end

  // ---- stimulus FSM ------------------------------------------------------
  always_ff @(posedge clk) begin
    if (rst == 0) begin
      aes_in.key    <= '0;
      aes_in.data   <= '0;
      aes_in.func   <= '0;
      aes_in.enable <= '0;
      enable_r      <= 1;
      state         <= 0;
      idle_cnt      <= 0;
      burst_cnt     <= 0;
      result        <= '0;
      idle_noise_data <= 128'h1;
      idle_noise_key  <= 128'hd6e8feb86659fd93c7f3d3ab1f5a7c2d;
    end else begin
      idle_noise_data <= {
        idle_noise_data[(32*Nb-2):0],
        idle_noise_data[(32*Nb-1)] ^ idle_noise_data[6] ^
        idle_noise_data[1] ^ idle_noise_data[0]
      };
      idle_noise_key <= {
        idle_noise_key[(32*Nk-2):0],
        idle_noise_key[(32*Nk-1)] ^ idle_noise_key[7] ^
        idle_noise_key[2] ^ idle_noise_key[0]
      };

      case (state)

        // ---- state 0: key expansion ------------------------------------
        0: begin
          aes_in.key    <= TEST_KEY;
          aes_in.data   <= '0;
          aes_in.func   <= 1;
          aes_in.enable <= enable_r;
          enable_r      <= 0;
          if (aes_out.ready == 1) begin
            enable_r <= 1;
            state    <= 1;
          end
        end

        // ---- state 1: encrypt -----------------------------------------
        1: begin
          aes_in.key    <= '0;
          aes_in.data   <= TEST_DATA;
          aes_in.func   <= 2;
          aes_in.enable <= enable_r;
          enable_r      <= 0;
          if (aes_out.ready == 1) begin
            result   <= aes_out.result;
            enable_r <= 0;
            state    <= 2;
            idle_cnt <= 0;
          end
        end

        // ---- state 2: idle after encrypt (CE-gating visible here) -----
        2: begin
          aes_in.enable <= 0;
          aes_in.func   <= 0;
          if (IDLE_INPUT_NOISE) begin
            aes_in.data <= idle_noise_data;
            aes_in.key  <= idle_noise_key;
          end
          idle_cnt      <= idle_cnt + 1;
          if (idle_cnt == (IDLE_CYCLES - 1)) begin
            enable_r <= 1;
            state    <= 3;
          end
        end

        // ---- state 3: decrypt -----------------------------------------
        3: begin
          aes_in.key    <= '0;
          aes_in.data   <= result;
          aes_in.func   <= 3;
          aes_in.enable <= enable_r;
          enable_r      <= 0;
          if (aes_out.ready == 1) begin
            enable_r <= 0;
            state    <= 4;
            idle_cnt <= 0;
          end
        end

        // ---- state 4: idle after decrypt ------------------------------
        4: begin
          aes_in.enable <= 0;
          aes_in.func   <= 0;
          if (IDLE_INPUT_NOISE) begin
            aes_in.data <= ~idle_noise_data;
            aes_in.key  <= {
              idle_noise_key[(16*Nk-1):0],
              idle_noise_key[(32*Nk-1):(16*Nk)]
            };
          end
          idle_cnt      <= idle_cnt + 1;
          if (idle_cnt == (IDLE_CYCLES - 1)) begin
            burst_cnt <= burst_cnt + 1;
            if (burst_cnt == (NUM_BURSTS - 1)) begin
              $finish;
            end else begin
              // next burst: re-issue key expansion
              enable_r <= 1;
              state    <= 0;
            end
          end
        end

        default: state <= 0;
      endcase

    end
  end

  // ---- DUT instantiation -------------------------------------------------
  generate
    if (enable_pipeline) begin : gen_pipeline
      aes aes_dut (
        .rst    (rst),
        .clk    (clk),
        .aes_in (aes_in),
        .aes_out(aes_out)
      );
    end else begin : gen_fsm
      aes_state aes_state_dut (
        .rst    (rst),
        .clk    (clk),
        .aes_in (aes_in),
        .aes_out(aes_out)
      );
    end
  endgenerate

endmodule
