/*==================================================================================
  Project     : Packet Scheduler Verification
  File name   : environment.sv
  Description : Top-level verification environment class
                - Instantiates and configures the APB agent
                - Instantiates the scoreboard
                - Connects analysis ports between monitor and scoreboard
===================================================================================*/

class environment extends uvm_env;

  `uvm_component_utils(environment)

  import req_ack_pkg::*;

  // ============================================================================
  // Components
  // ============================================================================

  // APB Agent
  apb_agent apb_agt;
  // REQ/ACK Agents (one per client)
  req_ack_agent req_ack_agt[REQ_ACK_NUM_CLIENTS];
  // Scoreboard
  scoreboard sb;
  // Configuration
  apb_config_object apb_cfg;
  req_ack_config_object req_ack_cfg[REQ_ACK_NUM_CLIENTS];

  // ============================================================================
  // Constructor
  // ============================================================================

  function new(string name = "environment", uvm_component parent);
    super.new(name, parent);
  endfunction : new

  // ============================================================================
  // Build Phase
  // ============================================================================

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Create and configure APB config object
    apb_cfg = apb_config_object::type_id::create("apb_cfg");

    // Configure APB
    apb_cfg.apb_role = MASTER;
    apb_cfg.is_active = UVM_ACTIVE;

    // Store config in database for agent to retrieve
    uvm_config_db#(apb_config_object)::set(this, "apb_agt", "apb_cfg_obj", apb_cfg);

    for(int i = 0; i < REQ_ACK_NUM_CLIENTS; i++) begin
      req_ack_cfg[i] = req_ack_config_object::type_id::create($sformatf("req_ack_cfg_%0d", i));
      req_ack_cfg[i].is_active = UVM_ACTIVE;
      uvm_config_db#(req_ack_config_object)::set(this, $sformatf("req_ack_agt_%0d", i), "req_ack_cfg_obj", req_ack_cfg[i]);
    end

    // Set virtual interfaces for each agent
    uvm_config_db#(virtual req_ack_interface)::set(this, "req_ack_agt_0", "req_ack_vif", $root.top.req_ack_if_0);
    uvm_config_db#(virtual req_ack_interface)::set(this, "req_ack_agt_1", "req_ack_vif", $root.top.req_ack_if_1);
    uvm_config_db#(virtual req_ack_interface)::set(this, "req_ack_agt_2", "req_ack_vif", $root.top.req_ack_if_2);
    uvm_config_db#(virtual req_ack_interface)::set(this, "req_ack_agt_3", "req_ack_vif", $root.top.req_ack_if_3);

    // Create APB agent
    apb_agt = apb_agent::type_id::create("apb_agt", this);

    // Create 4 REQ/ACK agents
    for(int i = 0; i < REQ_ACK_NUM_CLIENTS; i++) begin
      req_ack_agt[i] = req_ack_agent::type_id::create($sformatf("req_ack_agt_%0d", i), this);
    end

    // Create scoreboard
    sb = scoreboard::type_id::create("sb", this);

  endfunction : build_phase

  // ============================================================================
  // Connect Phase
  // ============================================================================

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    // Connect APB monitor analysis port to scoreboard
    apb_agt.apb_mon.apb_ap.connect(sb.apb_mst_port);
    
    // Connect 4 REQ/ACK monitor analysis ports to scoreboard
    for(int i = 0; i < REQ_ACK_NUM_CLIENTS; i++) begin
      req_ack_agt[i].req_ack_mon.req_ack_ap.connect(sb.req_ack_port);
    end

    `uvm_info("CONNECT", "Environment connections established", UVM_MEDIUM)
  endfunction : connect_phase

endclass : environment
