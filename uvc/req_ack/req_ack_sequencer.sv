/*==================================================================================
  Project     : Packet Scheduler Verification
  File name   : req_ack_sequencer.sv
  Author      : Acatrinei Sergiu
  Description : Sequencer for request-acknowledge transactions
===================================================================================*/

class req_ack_sequencer extends uvm_sequencer #(req_ack_seq_item);

  `uvm_component_utils(req_ack_sequencer)

  // CONSTRUCTOR
  //==================================================================================
  function new(string name = "req_ack_sequencer", uvm_component parent);
    super.new(name, parent);
  endfunction : new
  //==================================================================================

endclass : req_ack_sequencer
