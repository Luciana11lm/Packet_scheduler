/*==================================================================================
  Project     : UVM_APB_agent
  File name   : apb_agent.sv 
  Author      : Mitu Mariana-Luciana
  Description : Encapsulates the APB sequencer, driver and monitor components into
                a reusable agent. Supports both active and passive modes based on 
                the configuration object.
===================================================================================*/

class apb_agent extends uvm_agent;

  `uvm_component_utils(apb_agent)

  apb_seqencer          apb_seqr    ; // APB sequencer
  apb_driver            apb_drv     ; // APB driver
  apb_monitor           apb_mon     ; // APB monitor
  virtual apb_interface apb_vif     ; // APB virtual interface
  apb_config_object     apb_cfg_obj ; // APB configuration object

  // CONSTRUCTOR
  //==================================================================================
  function new(string name = "apb_agent", uvm_component parent);
    super.new(name, parent);
  endfunction : new
  //==================================================================================

  // BUILD PHASE
  //==================================================================================
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if(!uvm_config_db(virtual apb_interface)::get(this, "", "apb_vif", apb_vif))
      `uvm_fatal(get_full_name(), "APB virtual interface not found in config db for APB agent!")

    apb_cfg_obj = apb_config_object::type_id::create("apb_cfg_obj");
    if(!uvm_config_db#(apb_config_object)::get(this, "", "apb_cfg_obj", apb_cfg_obj))
      `uvm_fatal(get_full_name(), "APB configuration object interface not found in config db for APB agent!")

    apb_mon = apb_monitor::type_id::create("apb_mon", this);
    uvm_config_db#(virtual apb_interface)::set(this, "apb_mon", "apb_vif", apb_vif);
    
    if(apb_cfg_obj.is_active == UVM_ACTIVE) begin
      apb_seqr = apb_seqencer::type_id::create("apb_seqr", this);
      apb_drv  = apb_driver  ::type_id::create("apb_drv" , this);
      uvm_config_db#(virtual apb_interface)::set(this, "apb_drv", "apb_vif"    , apb_vif    );
      uvm_config_db#(apb_config_object)    ::set(this, "apb_drv", "apb_cfg_obj", apb_cfg_obj);
    end
  endfunction : build_phase
  //==================================================================================

  // CONNECT PHASE
  //==================================================================================
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if(apb_cfg_obj.is_active == UVM_ACTIVE) 
      apb_drv.seq_item_port.connect(apb_seqr.seq_item_export); 
  endfunction : connect_phase
  //==================================================================================

endclass : apb_agent