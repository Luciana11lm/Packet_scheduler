`timescale 1ns/1ps

module pachet_scheduler_tb;

  localparam DATA_WIDTH = 8;
  localparam ADDR_WIDTH = 2;
  localparam CK_SEMIPERIOD = 5;

  // Clock / reset
  logic clk_i;
  logic rstn_i;

  // APB signals
  logic                  psel_i;
  logic                  penable_i;
  logic                  pwrite_i;
  logic [ADDR_WIDTH-1:0] paddr_i;
  logic [DATA_WIDTH-1:0] pwdata_i;
  logic [DATA_WIDTH-1:0] prdata_o;
  logic                  pready_o;
  logic                  pslverr_o;

  // Client interfaces
  logic                  req0, req1, req2, req3;
  logic                  ack0, ack1, ack2, ack3;
  logic [DATA_WIDTH-1:0] data0, data1, data2, data3;

  // DUT instance
  pachet_scheduler #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
  ) dut (
    .clk_i     (clk_i),
    .rstn_i    (rstn_i),

    .psel_i    (psel_i),
    .penable_i (penable_i),
    .pwrite_i  (pwrite_i),
    .paddr_i   (paddr_i),
    .pwdata_i  (pwdata_i),
    .prdata_o  (prdata_o),
    .pready_o  (pready_o),
    .pslverr_o (pslverr_o),

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

  // Clock generation
  initial begin
    clk_i = 1'b0;
    forever #CK_SEMIPERIOD clk_i = ~clk_i;
  end

  // Reset and default values
  initial begin
    rstn_i    = 1'b0;

    psel_i    = 1'b0;
    penable_i = 1'b0;
    pwrite_i  = 1'b0;
    paddr_i   = '0;
    pwdata_i  = '0;

    req0      = 1'b0;
    req1      = 1'b0;
    req2      = 1'b0;
    req3      = 1'b0;
    data0     = '0;
    data1     = '0;
    data2     = '0;
    data3     = '0;

    repeat (4) @(posedge clk_i);
    rstn_i = 1'b1;
    repeat (2) @(posedge clk_i);
  end

  // APB write transfer: setup phase + access phase, no wait-states
  task automatic apb_write(input [ADDR_WIDTH-1:0] addr,
                           input [DATA_WIDTH-1:0] data);
    begin
      @(posedge clk_i);
      psel_i    <= 1'b1;
      penable_i <= 1'b0;
      pwrite_i  <= 1'b1;
      paddr_i   <= addr;
      pwdata_i  <= data;

      @(posedge clk_i);
      penable_i <= 1'b1;

      @(posedge clk_i);
      #1;
      $display("[%0t] APB WRITE addr=%0d data=0x%02h pready=%0b pslverr=%0b",
               $time, addr, data, pready_o, pslverr_o);
      psel_i    <= 1'b0;
      penable_i <= 1'b0;
      pwrite_i  <= 1'b0;
      paddr_i   <= '0;
      pwdata_i  <= '0;
    end
  endtask

  // APB read transfer: setup phase + access phase, no wait-states
  task automatic apb_read(input  [ADDR_WIDTH-1:0] addr,
                          output [DATA_WIDTH-1:0] data);
    begin
      @(posedge clk_i);
      psel_i    <= 1'b1;
      penable_i <= 1'b0;
      pwrite_i  <= 1'b0;
      paddr_i   <= addr;
      pwdata_i  <= '0;

      @(posedge clk_i);
      penable_i <= 1'b1;

      @(posedge clk_i);
      #1;
      data = prdata_o;
      $display("[%0t] APB READ  addr=%0d data=0x%02h pready=%0b pslverr=%0b",
               $time, addr, data, pready_o, pslverr_o);
      psel_i    <= 1'b0;
      penable_i <= 1'b0;
      paddr_i   <= '0;
    end
  endtask

  // One complete req/ack transfer from client 0
  task automatic client0_send(input [DATA_WIDTH-1:0] data);
    begin
      @(posedge clk_i);
      data0 <= data;
      req0  <= 1'b1;

      @(posedge clk_i);
      #1;
      $display("[%0t] CLIENT0 SEND data=0x%02h ack0=%0b", $time, data, ack0);

      req0  <= 1'b0;
      data0 <= '0;
    end
  endtask

  // Stimulus
  initial begin : test_sequence
    logic [DATA_WIDTH-1:0] rdata;

    @(posedge rstn_i);
    repeat (2) @(posedge clk_i);

    // Simple APB transaction: read status after reset.
    // Expected: output queue empty => status bit 2 should be 1.
    apb_read(2'd1, rdata);

    // Simple APB write: keep default config, SP + all clients enabled.
    apb_write(2'd2, 8'b0000_1111);

    // One complete client transaction.
    client0_send(8'hA5);

    // Wait until scheduler moves data from Q0 to output queue.
    repeat (4) @(posedge clk_i);

    // APB reads the scheduled data from output queue.
    apb_read(2'd0, rdata);

    if (rdata == 8'hA5)
      $display("[%0t] TEST PASSED: output queue returned expected data 0x%02h", $time, rdata);
    else
      $display("[%0t] TEST FAILED: expected 0xA5, got 0x%02h", $time, rdata);

    repeat (5) @(posedge clk_i);
    $finish;
  end

  // Optional waveform dump
  initial begin
    $dumpfile("pachet_scheduler_tb.vcd");
    $dumpvars(0, pachet_scheduler_tb);
  end

endmodule
