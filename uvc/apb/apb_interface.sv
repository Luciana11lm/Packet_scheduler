/*==================================================================================
  Project     : UVM_APB_agent
  File name   : apb_interface.sv 
  Author      : Mitu Mariana-Luciana
  Description : APB protoclo signals interface:
                - clocking blocks for signal synchronization:
                  -> rcv : used for monitoring the signals
                  -> drv : used for driving the signals
                - modports for deciding signal direction (async modports used for 
                reseting the signals asynchronous on system reset)
===================================================================================*/

interface apb_interface #(int DATA_WIDTH = 8, int ADDR_WIDTH = 8) (
  input clock,
  input reset
);

  // SIGNALS DECLARATION
  //==================================================================================
  logic                      psel    ;
  logic                      penable ;
  logic                      pwrite  ;
  logic                      pready  ;
  logic                      pslverr ;
  logic [ADDR_WIDTH - 1 : 0] paddr   ;
  logic [DATA_WIDTH - 1 : 0] pwdata  ;
  logic [DATA_WIDTH - 1 : 0] prdata  ;
  //==================================================================================

  // CLOCKING BLOCKS
  //==================================================================================
  clocking drv_cb_mst @(posedge clock);
    output psel    ;
    output penable ;
    output pwrite  ;
    input  pready  ;
    input  pslverr ;
    output paddr   ;
    output pwdata  ;
    input  prdata  ;
  endclocking

  clocking drv_cb_slv @(posedge clock);
    input  psel    ;
    input  penable ;
    input  pwrite  ;
    output pready  ;
    output pslverr ;
    input  paddr   ;
    input  pwdata  ;
    output prdata  ;
  endclocking

  clocking rcv_cb @(posedge clock);
    input  psel    ;
    input  penable ;
    input  pwrite  ;
    input  pready  ;
    input  pslverr ;
    input  paddr   ;
    input  pwdata  ;
    input  prdata  ;
  endclocking
  //==================================================================================

  // MODPORTS
  //==================================================================================
  modport drv_mst_mp      (input clock, input reset, clocking drv_cb_mst);
  modport drv_slv_mp      (input clock, input reset, clocking drv_cb_slv);
  modport drv_async_mst_mp(input clock, input reset, output psel, output penable, output pwrite, input pready, input pslverr, output paddr, output pwdata, input prdata);
  modport drv_async_slv_mp(input clock, input reset, input psel, input penable, input pwrite, output pready, output pslverr, input paddr, input pwdata, output prdata);
  modport rcv_mp          (input clock, input reset, clocking rcv_cb);
  //==================================================================================

  `include "apb_assertions.sv"

endinterface