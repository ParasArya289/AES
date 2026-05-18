import aes_const::*;
import aes_wire::*;

module aes_state
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
  logic [7:0] unified_array[0:(4*Nb-1)];

  logic [(32*Nb-1):0] unified_data;

  logic [0 : 0] kexp_enable;
  logic [0 : 0] unified_enable;
  logic [0 : 0] unified_direction;

  logic [0 : 0] kexp_ready;
  logic [0 : 0] unified_ready;

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

  aes_kexp_state aes_kexp_state_comp
  (
    .rst (rst),
    .clk (clk),
    .Key (key_array),
    .Enable (kexp_enable),
    .KExp (kexp),
    .Ready_out (kexp_ready)
  );

  aes_unified_state aes_unified_state_comp
  (
    .rst          (rst),
    .clk          (clk),
    .KExp         (kexp),
    .Data_in      (data_array),
    .Direction_in (unified_direction),
    .Enable       (unified_enable),
    .Data_out     (unified_array),
    .Ready_out    (unified_ready)
  );

  aes_cdata aes_cdata_unified_comp
  (
    .data_in  (unified_array),
    .data_out (unified_data)
  );

  always_comb begin

    kexp_enable      = 0;
    unified_enable    = 0;
    unified_direction = 0;

    if (aes_in.enable == 1) begin
      if (aes_in.func == 1) begin
        kexp_enable = 1;
      end else if (aes_in.func == 2) begin
        unified_enable    = 1;
        unified_direction = 0;
      end else if (aes_in.func == 3) begin
        unified_enable    = 1;
        unified_direction = 1;
      end
    end

  end

  always_comb begin

    if (kexp_ready == 1) begin
      aes_out.result = 0;
      aes_out.ready  = kexp_ready;
    end else if (unified_ready == 1) begin
      aes_out.result = unified_data;
      aes_out.ready  = unified_ready;
    end else begin
      aes_out.result = 0;
      aes_out.ready  = 0;
    end

  end

endmodule
