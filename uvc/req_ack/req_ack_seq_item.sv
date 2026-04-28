/*==================================================================================
  Project     : Packet Scheduler Verification
  File name   : req_ack_seq_item.sv
  Author      : Acatrinei Sergiu
  Description : Sequence item for request-acknowledge transactions
===================================================================================*/

class req_ack_seq_item extends uvm_sequence_item;

  rand int unsigned               req_delay      ; // Cycles before request assertion
  rand bit [REQ_ACK_DATA_WIDTH - 1 : 0] data     ; // Data associated with the request
  rand int unsigned               ack_timeout    ; // Maximum cycles to wait for ACK
       bit                        ack_seen       ; // ACK observed by the monitor
       bit                        request_seen   ; // REQ observed by the monitor
       int unsigned               wait_cycles    ; // Cycles between REQ and ACK

  `uvm_object_utils_begin(req_ack_seq_item)
    `uvm_field_int (req_delay              , UVM_ALL_ON             )
    `uvm_field_int (data                   , UVM_ALL_ON | UVM_HEX   )
    `uvm_field_int (ack_timeout            , UVM_ALL_ON             )
    `uvm_field_int (ack_seen               , UVM_ALL_ON             )
    `uvm_field_int (request_seen           , UVM_ALL_ON             )
    `uvm_field_int (wait_cycles            , UVM_ALL_ON             )
  `uvm_object_utils_end

  // CONSTRUCTOR
  //==================================================================================
  function new(string name = "req_ack_seq_item");
    super.new(name);
  endfunction : new
  //==================================================================================

  function string convert2string();
    return $sformatf("req_delay=%0d data=0x%0h ack_timeout=%0d ack_seen=%0b request_seen=%0b wait_cycles=%0d",
      req_delay, data, ack_timeout, ack_seen, request_seen, wait_cycles);
  endfunction : convert2string

endclass : req_ack_seq_item
