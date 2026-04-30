/*==================================================================================
  Project     : Packet Scheduler Verification
  File name   : req_ack_config_object.sv
  Author      : Acatrinei Sergiu
  Description : Configuration object for the request-acknowledge UVC
===================================================================================*/

class req_ack_config_object extends uvm_object;

  uvm_active_passive_enum is_active = UVM_ACTIVE;

  `uvm_object_utils_begin(req_ack_config_object)
    `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_ALL_ON | UVM_STRING)
  `uvm_object_utils_end

  // CONSTRUCTOR
  //==================================================================================
  function new(string name = "req_ack_config_object");
    super.new(name);
  endfunction : new
  //==================================================================================

endclass : req_ack_config_object
