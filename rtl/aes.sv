import aes_const::*;
import aes_wire::*;

module aes
(
  input logic rst,
  input logic clk,
  input aes_in_type aes_in,
  output aes_out_type aes_out
);
  timeunit 1ns;
  timeprecision 1ps;

  logic [31:0] kexp [0:(Nb*(Nr+1)-1)];

  logic [7:0] key_array[0:(4*Nk-1)];
  logic [7:0] data_array[0:(4*Nb-1)];
  logic [7:0] cipher_array[0:(4*Nb-1)];
  logic [7:0] icipher_array[0:(4*Nb-1)];

  logic [(32*Nb-1):0] cipher_data;
  logic [(32*Nb-1):0] icipher_data;

  logic [0 : 0] kexp_enable;
  logic [0 : 0] cipher_enable;
  logic [0 : 0] icipher_enable;

  logic [0 : 0] kexp_ready;
  logic [0 : 0] cipher_ready;
  logic [0 : 0] icipher_ready;

  logic [0 : 0] kexp_pending;
  logic [0 : 0] cipher_pending;
  logic [0 : 0] icipher_pending;

  aes_xkey aes_xkey_comp
  (
    .key_in (aes_in.key),
    .key_out (key_array)
  );

  aes_xdata aes_xdata_comp
  (
    .data_in (aes_in.data),
    .data_out (data_array)
  );

  aes_kexp aes_kexp_comp
  (
    .rst (rst),
    .clk (clk),
    .Key (key_array),
    .Enable (kexp_enable),
    .KExp (kexp),
    .Ready_out (kexp_ready)
  );

  aes_cipher aes_cipher_comp
  (
    .rst (rst),
    .clk (clk),
    .KExp (kexp),
    .Data_in (data_array),
    .Enable (cipher_enable),
    .Data_out (cipher_array),
    .Ready_out (cipher_ready)
  );

  aes_icipher aes_icipher_comp
  (
    .rst (rst),
    .clk (clk),
    .KExp (kexp),
    .Data_in (data_array),
    .Enable (icipher_enable),
    .Data_out (icipher_array),
    .Ready_out (icipher_ready)
  );

  aes_cdata aes_cdata_cipher_comp
  (
    .data_in (cipher_array),
    .data_out (cipher_data)
  );

  aes_cdata aes_cdata_icipher_comp
  (
    .data_in (icipher_array),
    .data_out (icipher_data)
  );

  // Track which subsystem has an in-flight operation.
  // Set when enable fires for that subsystem; cleared when its ready fires.
  always_ff @(posedge clk) begin
    if (rst == 0) begin
      kexp_pending    <= '0;
      cipher_pending  <= '0;
      icipher_pending <= '0;
    end else begin
      if (kexp_enable)         kexp_pending    <= 1;
      else if (kexp_ready)     kexp_pending    <= 0;
      if (cipher_enable)       cipher_pending  <= 1;
      else if (cipher_ready)   cipher_pending  <= 0;
      if (icipher_enable)      icipher_pending <= 1;
      else if (icipher_ready)  icipher_pending <= 0;
    end
  end

  always_comb begin

    kexp_enable = 0;
    cipher_enable = 0;
    icipher_enable = 0;

    if (aes_in.enable == 1) begin
      if (aes_in.func == 1) begin
        kexp_enable = 1;
      end else if (aes_in.func == 2) begin
        cipher_enable = 1;
      end else if (aes_in.func == 3) begin
        icipher_enable = 1;
      end
    end

  end

  always_comb begin

    if (kexp_ready == 1 && kexp_pending == 1) begin
      aes_out.result = 0;
      aes_out.ready = 1;
    end else if (cipher_ready == 1 && cipher_pending == 1) begin
      aes_out.result = cipher_data;
      aes_out.ready = 1;
    end else if (icipher_ready == 1 && icipher_pending == 1) begin
      aes_out.result = icipher_data;
      aes_out.ready = 1;
    end else begin
      aes_out.result = 0;
      aes_out.ready = 0;
    end

  end

endmodule
