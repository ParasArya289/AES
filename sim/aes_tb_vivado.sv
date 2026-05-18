import aes_const::*;
import aes_wire::*;

// Self-contained testbench for Vivado behavioral simulation.
// Drives its own clock/reset and uses inline test vectors instead of $readmemh,
// which avoids the Z-state clock/reset issue seen when aes_tb.sv is used as the
// simulation top (its rst/clk ports have no driver in Vivado).
//
// Test vector: NIST AES-128 example
//   Key:     dffe1e8f4824951ba6d3bf8b46e53c4d
//   Plain:   bab8d38cebb576d489d7606e10784ddc
//   Cipher:  09036baae31b28e2b6878d016358b083

`timescale 1ns/1ps

module aes_tb_vivado;

  // -----------------------------------------------------------------------
  // Clock / reset
  // -----------------------------------------------------------------------
  logic clk = 0;
  logic rst = 0;

  always #5 clk = ~clk;   // 100 MHz

  initial begin
    rst = 0;
    repeat(4) @(posedge clk);
    rst = 1;
  end

  // -----------------------------------------------------------------------
  // DUT signals
  // -----------------------------------------------------------------------
  aes_in_type  aes_in;
  aes_out_type aes_out;

  aes_state dut (
    .rst    (rst),
    .clk    (clk),
    .aes_in (aes_in),
    .aes_out(aes_out)
  );

  // -----------------------------------------------------------------------
  // Inline test vectors (Nw=1 block)
  // -----------------------------------------------------------------------
  localparam logic [127:0] KEY     = 128'hdffe1e8f4824951ba6d3bf8b46e53c4d;
  localparam logic [127:0] PLAIN   = 128'hbab8d38cebb576d489d7606e10784ddc;
  localparam logic [127:0] CIPHER  = 128'h09036baae31b28e2b6878d016358b083;

  // -----------------------------------------------------------------------
  // State machine  (mirrors the always_ff in aes_tb.sv)
  // -----------------------------------------------------------------------
  integer  state  = 0;
  logic    enable = 1;
  logic [127:0] result;
  integer  tests_run    = 0;
  integer  tests_passed = 0;

  always_ff @(posedge clk) begin
    if (!rst) begin
      aes_in.key    <= 0;
      aes_in.data   <= 0;
      aes_in.func   <= 0;
      aes_in.enable <= 0;
      enable  <= 1;
      state   <= 0;
      result  <= 0;
    end else begin

      // ---- state 0: key expansion ----------------------------------------
      if (state == 0) begin
        aes_in.key    <= KEY;
        aes_in.data   <= 0;
        aes_in.func   <= 2'b01;   // func=1 → kexp
        aes_in.enable <= enable;
        enable <= 0;

        if (aes_out.ready) begin
          enable <= 1;
          state  <= 1;
          $display("[TB] KEY:  %032x", KEY);
          $display("[TB] DATA: %032x", PLAIN);
        end
      end

      // ---- state 1: encrypt -----------------------------------------------
      else if (state == 1) begin
        aes_in.key    <= 0;
        aes_in.data   <= PLAIN;
        aes_in.func   <= 2'b10;   // func=2 → encrypt
        aes_in.enable <= enable;
        enable <= 0;

        if (aes_out.ready) begin
          enable <= 1;
          state  <= 2;
          result <= aes_out.result;
          tests_run <= tests_run + 1;

          $display("[TB] ENCRYPT:  %032x", aes_out.result);
          $display("[TB] EXPECTED: %032x", CIPHER);

          if (aes_out.result == CIPHER) begin
            $display("[TB] ENCRYPT TEST PASSED");
            tests_passed <= tests_passed + 1;
          end else begin
            $display("[TB] ENCRYPT TEST FAILED");
          end
        end
      end

      // ---- state 2: decrypt -----------------------------------------------
      else if (state == 2) begin
        aes_in.key    <= 0;
        aes_in.data   <= result;
        aes_in.func   <= 2'b11;   // func=3 → decrypt
        aes_in.enable <= enable;
        enable <= 0;

        if (aes_out.ready) begin
          enable <= 1;
          state  <= 3;
          tests_run <= tests_run + 1;

          $display("[TB] DECRYPT:  %032x", aes_out.result);
          $display("[TB] EXPECTED: %032x", PLAIN);

          if (aes_out.result == PLAIN) begin
            $display("[TB] DECRYPT TEST PASSED");
            tests_passed <= tests_passed + 1;
          end else begin
            $display("[TB] DECRYPT TEST FAILED");
          end
        end
      end

      // ---- state 3: done --------------------------------------------------
      else begin
        $display("[TB] ---- RESULTS: %0d/%0d tests passed ----", tests_passed, tests_run);
        $finish;
      end

    end
  end

  // -----------------------------------------------------------------------
  // Timeout guard (10 000 cycles)
  // -----------------------------------------------------------------------
  initial begin
    repeat(10000) @(posedge clk);
    $display("[TB] TIMEOUT — simulation did not finish");
    $finish;
  end

endmodule
