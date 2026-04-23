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

  // ============================================================================
  // Components
  // ============================================================================

  // APB Agent
  apb_agent apb_agt;
  // Scoreboard
  circuit_scoreboard sb;
  // Configuration
  apb_config_object apb_cfg;

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

    // Create APB agent
    apb_agt = apb_agent::type_id::create("apb_agt", this);

    // Create scoreboard
    sb = circuit_scoreboard::type_id::create("sb", this);

  endfunction : build_phase

  // ============================================================================
  // Connect Phase
  // ============================================================================

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    // Connect APB monitor analysis port to scoreboard
    apb_agt.apb_mon.apb_ap.connect(sb.apb_mst_port);

    `uvm_info("CONNECT", "Environment connections established", UVM_MEDIUM)
  endfunction : connect_phase

  // ============================================================================
  // Start of Simulation Phase
  // ============================================================================

  function void start_of_simulation_phase(uvm_phase phase);
    super.start_of_simulation_phase(phase);

    `uvm_info("ENV_SIM", "Packet Scheduler Verification Environment Started", UVM_LOW)
  endfunction : start_of_simulation_phase

  // ============================================================================
  // Report Phase
  // ============================================================================

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);

    `uvm_info("ENV_REPORT", "Environment report phase completed", UVM_LOW)
  endfunction : report_phase

endclass : environment
