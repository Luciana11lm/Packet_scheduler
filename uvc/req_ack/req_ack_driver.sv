/*==================================================================================
  Project     : Packet Scheduler Verification
  File name   : req_ack_driver.sv
  Author      : Acatrinei Sergiu
  Description : Drives request-acknowledge transactions for the Packet Scheduler
===================================================================================*/

class req_ack_driver extends uvm_driver #(req_ack_seq_item);

  `uvm_component_utils(req_ack_driver)

  virtual req_ack_interface        req_ack_vif      ;
  virtual req_ack_interface.drv_mp req_ack_sync_mp  ;
  req_ack_config_object            req_ack_cfg_obj  ;
  req_ack_seq_item                 req_ack_pkt      ;
  int unsigned                     no_items_sent    ;

  // CONSTRUCTOR
  //==================================================================================
  function new(string name = "req_ack_driver", uvm_component parent);
    super.new(name, parent);
    no_items_sent = 0;
  endfunction : new
  //==================================================================================

  // BUILD PHASE
  //==================================================================================
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    req_ack_pkt     = req_ack_seq_item     ::type_id::create("req_ack_pkt");
    req_ack_cfg_obj = req_ack_config_object::type_id::create("req_ack_cfg_obj");

    if(!uvm_config_db#(virtual req_ack_interface)::get(this, "", "req_ack_vif", req_ack_vif))
      `uvm_fatal(get_full_name(), "REQ/ACK virtual interface not found in config db for req_ack driver!")

    if(!uvm_config_db#(req_ack_config_object)::get(this, "", "req_ack_cfg_obj", req_ack_cfg_obj))
      `uvm_fatal(get_full_name(), "REQ/ACK configuration object not found in config db for req_ack driver!")

    req_ack_sync_mp = req_ack_vif.drv_mp;
  endfunction : build_phase
  //==================================================================================

  // RUN PHASE
  //==================================================================================
  task run_phase(uvm_phase phase);
    super.run_phase(phase);

    forever begin
      seq_item_port.get_next_item(req_ack_pkt);
      drive_req_ack_item(req_ack_pkt);
      no_items_sent++;
      seq_item_port.item_done();
    end
  endtask : run_phase
  //==================================================================================

  // DRIVE REQUEST-ACKNOWLEDGE ITEM
  //==================================================================================
  task drive_req_ack_item(req_ack_seq_item req_ack_item);
    wait(req_ack_vif.reset == 1'b0);

    `uvm_info(get_full_name(), $sformatf("Sending REQ/ACK packet %0d: %s", no_items_sent, req_ack_item.convert2string()), UVM_LOW)

    repeat(req_ack_item.req_delay) @(posedge req_ack_vif.clock);

    req_ack_sync_mp.drv_cb.req  = 1'b1;
    req_ack_sync_mp.drv_cb.data = req_ack_item.data;

    wait(req_ack_sync_mp.drv_cb.ack == 1'b1);
    @(posedge req_ack_vif.clock);

    req_ack_sync_mp.drv_cb.req  = 1'b0;
    req_ack_sync_mp.drv_cb.data = 'd0;
  endtask : drive_req_ack_item
  //==================================================================================

endclass : req_ack_driver
