/*==================================================================================
  Project     : UVM_APB_agent
  File name   : apb_seq_item.sv 
  Author      : Mitu Mariana-Luciana
  Description : 
===================================================================================*/

class apb_seq_item extends uvm_sequence_item;

  rand int unsigned             tr_delay  ;   // Clock cycles before transaction start
  rand int unsigned             rdy_delay ;   // Clock cycles for wait states
  rand bit [ADDR_WIDTH - 1 : 0] address   ;   // APB PADDR
  rand bit [DATA_WIDTH - 1 : 0] data      ;   // APB PWDATA for pwrite = 1 / PRDATA for pwrite = 0
  rand operation_t              operation ;   // APB PWRITE = 1 => WRITE / PWRITE = 0 => READ
  rand bit                      error     ;   // APB PSLVERR 

  `uvm_object_utils_begin(apb_seq_item)
    `uvm_field_int (tr_delay              , UVM_ALL_ON             )
    `uvm_field_int (rdy_delay             , UVM_ALL_ON             )
    `uvm_field_int (address               , UVM_ALL_ON | UVM_HEX   )
    `uvm_field_int (data                  , UVM_ALL_ON | UVM_HEX   )
    `uvm_field_enum(operation_t, operation, UVM_AL_ON  | UVM_STRING)
    `uvm_field_int (error                 , UVM_ALL_ON             )
  `uvm_object_utils_end

  // CONSTRUCTOR
  //=================================================================================
  function new(strin name = "apb_seq_item");
    super.new(name);
  endfunction : new
  //=================================================================================

endclass : apb_seq_item