// ============================================================================
// File: top.sv
// Description: Top-level testbench for Packet Scheduler verification
// ============================================================================

`include "tb_includes.sv"

module top;
  import uvm_pkg::*;
  import apb_pkg::*;
  import req_ack_pkg::*;

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

  // REQ/ACK interfaces (4 client lanes)
  req_ack_interface #(
    .DATA_WIDTH(APB_DATA_WIDTH)
  ) req_ack_if_0 (
    .clock(clk),
    .reset(rst_apb)
  );

  req_ack_interface #(
    .DATA_WIDTH(APB_DATA_WIDTH)
  ) req_ack_if_1 (
    .clock(clk),
    .reset(rst_apb)
  );

  req_ack_interface #(
    .DATA_WIDTH(APB_DATA_WIDTH)
  ) req_ack_if_2 (
    .clock(clk),
    .reset(rst_apb)
  );

  req_ack_interface #(
    .DATA_WIDTH(APB_DATA_WIDTH)
  ) req_ack_if_3 (
    .clock(clk),
    .reset(rst_apb)
  );

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

    uvm_config_db#(virtual req_ack_interface)::set(
      .cntxt(uvm_root::get()),
      .inst_name("*"),
      .field_name("req_ack_vif_0"),
      .value(req_ack_if_0)
    );

    uvm_config_db#(virtual req_ack_interface)::set(
      .cntxt(uvm_root::get()),
      .inst_name("*"),
      .field_name("req_ack_vif_1"),
      .value(req_ack_if_1)
    );

    uvm_config_db#(virtual req_ack_interface)::set(
      .cntxt(uvm_root::get()),
      .inst_name("*"),
      .field_name("req_ack_vif_2"),
      .value(req_ack_if_2)
    );

    uvm_config_db#(virtual req_ack_interface)::set(
      .cntxt(uvm_root::get()),
      .inst_name("*"),
      .field_name("req_ack_vif_3"),
      .value(req_ack_if_3)
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
    .req0      (req_ack_if_0.req),
    .ack0      (req_ack_if_0.ack),
    .data0     (req_ack_if_0.data),
    .req1      (req_ack_if_1.req),
    .ack1      (req_ack_if_1.ack),
    .data1     (req_ack_if_1.data),
    .req2      (req_ack_if_2.req),
    .ack2      (req_ack_if_2.ack),
    .data2     (req_ack_if_2.data),
    .req3      (req_ack_if_3.req),
    .ack3      (req_ack_if_3.ack),
    .data3     (req_ack_if_3.data)
  );

endmodule : top
