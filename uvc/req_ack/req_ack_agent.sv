/*==================================================================================
  Project     : Packet Scheduler Verification
  File name   : req_ack_agent.sv
  Author      : Acatrinei Sergiu
  Description : Encapsulates the request-acknowledge sequencer, driver and monitor
                into a reusable agent.
===================================================================================*/

class req_ack_agent extends uvm_agent;

  `uvm_component_utils(req_ack_agent)

  req_ack_sequencer          req_ack_seqr    ;
  req_ack_driver             req_ack_drv     ;
  req_ack_monitor            req_ack_mon     ;
  virtual req_ack_interface  req_ack_vif     ;
  req_ack_config_object      req_ack_cfg_obj ;

  // CONSTRUCTOR
  //==================================================================================
  function new(string name = "req_ack_agent", uvm_component parent);
    super.new(name, parent);
  endfunction : new
  //==================================================================================

  // BUILD PHASE
  //==================================================================================
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if(!uvm_config_db#(virtual req_ack_interface)::get(this, "", "req_ack_vif", req_ack_vif))
      `uvm_fatal(get_full_name(), "REQ/ACK virtual interface not found in config db for req_ack agent!")

    req_ack_cfg_obj = req_ack_config_object::type_id::create("req_ack_cfg_obj");
    if(!uvm_config_db#(req_ack_config_object)::get(this, "", "req_ack_cfg_obj", req_ack_cfg_obj))
      `uvm_fatal(get_full_name(), "REQ/ACK configuration object not found in config db for req_ack agent!")

    req_ack_mon = req_ack_monitor::type_id::create("req_ack_mon", this);
    uvm_config_db#(virtual req_ack_interface)::set(this, "req_ack_mon", "req_ack_vif", req_ack_vif);

    if(req_ack_cfg_obj.is_active == UVM_ACTIVE) begin
      req_ack_seqr = req_ack_sequencer::type_id::create("req_ack_seqr", this);
      req_ack_drv  = req_ack_driver   ::type_id::create("req_ack_drv" , this);
      uvm_config_db#(virtual req_ack_interface)::set(this, "req_ack_drv", "req_ack_vif", req_ack_vif);
      uvm_config_db#(req_ack_config_object)    ::set(this, "req_ack_drv", "req_ack_cfg_obj", req_ack_cfg_obj);
    end
  endfunction : build_phase
  //==================================================================================

  // CONNECT PHASE
  //==================================================================================
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    if(req_ack_cfg_obj.is_active == UVM_ACTIVE)
      req_ack_drv.seq_item_port.connect(req_ack_seqr.seq_item_export);
  endfunction : connect_phase
  //==================================================================================

endclass : req_ack_agent
