/*==================================================================================
  Project     : Packet Scheduler Verification
  File name   : req_ack_sequence_lib.sv
  Author      : Acatrinei Sergiu
  Description : Basic reusable sequences for request-acknowledge stimulus
===================================================================================*/

class req_ack_single_request_seq extends uvm_sequence #(req_ack_seq_item);

  `uvm_object_utils(req_ack_single_request_seq)

  req_ack_seq_item req_ack_item;

  function new(string name = "req_ack_single_request_seq");
    super.new(name);
  endfunction : new

  task body();
    req_ack_item = req_ack_seq_item::type_id::create("req_ack_item");

    start_item(req_ack_item);
    assert(req_ack_item.randomize() with {
      req_delay   inside {[0:5]};
      ack_timeout inside {[1:20]};
    }) else begin
      `uvm_error("REQ_ACK_SEQ", "Failed to randomize request-acknowledge item")
    end
    finish_item(req_ack_item);
  endtask : body

endclass : req_ack_single_request_seq
