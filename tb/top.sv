// ============================================================================
// File: top.sv
// Description: Top-level testbench for Packet Scheduler verification
// ============================================================================

`include "tb_includes.sv"

module top;
  import uvm_pkg::*;
  import apb_pkg::*;

  // ========================================================================
  // Signals and Interfaces
  // ========================================================================

  // Clock
  logic clk;
  // APB reset is active high
  logic rst_apb;
  // DUT reset is active low (inverted from APB reset)
  logic rst_n_dut;

  // APB interface (active-high reset)
  apb_interface #(
    .DATA_WIDTH(APB_DATA_WIDTH),
    .ADDR_WIDTH(APB_ADDR_WIDTH)
  ) apb_if_inst (
    .clock(clk),
    .reset(rst_apb)
  );

  // REQ/ACK (temporary direct signals)
  // TODO: replace with a dedicated req/ack interface once it is available.
  logic req0, req1, req2, req3;
  logic ack0, ack1, ack2, ack3;
  logic [APB_DATA_WIDTH-1:0] data0, data1, data2, data3;

  // Clock generation
  initial clk = 1'b0;
  always #(CLK_PERIOD/2) clk = ~clk;

  // Reset generation
  initial begin
    rst_apb = 1'b1;
    #(RESET_DURATION);
    rst_apb = 1'b0;
  end

  assign rst_n_dut = ~rst_apb;

  initial begin
    uvm_config_db#(virtual apb_interface)::set(
      .cntxt(uvm_root::get()),
      .inst_name("*"),
      .field_name("apb_vif"),
      .value(apb_if_inst)
    );
  end

  // DUT
  pachet_scheduler #(
    .DATA_WIDTH(APB_DATA_WIDTH),
    .ADDR_WIDTH(APB_ADDR_WIDTH)
  ) u_dut (
    .clk_i     (clk),
    .rst_i     (rst_n_dut),
    .psel_i    (apb_if_inst.psel),
    .penable_i (apb_if_inst.penable),
    .pwrite_i  (apb_if_inst.pwrite),
    .paddr_i   (apb_if_inst.paddr),
    .pwdata_i  (apb_if_inst.pwdata),
    .prdata_o  (apb_if_inst.prdata),
    .pready_o  (apb_if_inst.pready),
    .pslverr_o (apb_if_inst.pslverr),
    .req0      (req0),
    .ack0      (ack0),
    .data0     (data0),
    .req1      (req1),
    .ack1      (ack1),
    .data1     (data1),
    .req2      (req2),
    .ack2      (ack2),
    .data2     (data2),
    .req3      (req3),
    .ack3      (ack3),
    .data3     (data3)
  );

endmodule : top
