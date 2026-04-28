/*==================================================================================
  Project     : Packet Scheduler Verification
  File name   : req_ack_interface.sv
  Author      : Acatrinei Sergiu
  Description : Request-acknowledge protocol interface for the four Packet
                Scheduler client channels.
===================================================================================*/

interface req_ack_interface #(int DATA_WIDTH = 8) (
  input clock,
  input reset
);

  // SIGNALS DECLARATION
  //==================================================================================
  logic                      req  ;
  logic                      ack  ;
  logic [DATA_WIDTH - 1 : 0] data ;
  //==================================================================================

  // CLOCKING BLOCKS
  //==================================================================================
  clocking drv_cb @(posedge clock);
    output req;
    output data;
    input  ack;
  endclocking

  clocking rcv_cb @(posedge clock);
    input req;
    input ack;
    input data;
  endclocking
  //==================================================================================

  // MODPORTS
  //==================================================================================
  modport drv_mp (input clock, input reset, clocking drv_cb);
  modport rcv_mp (input clock, input reset, clocking rcv_cb);
  //==================================================================================

  `include "req_ack_assertions.sv"

endinterface
