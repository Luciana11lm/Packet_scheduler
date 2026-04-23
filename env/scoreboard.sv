/*==================================================================================
  Project     : Packet Scheduler Verification
  File name   : scoreboard.sv
  Description : Scoreboard component for packet scheduler verification
                - Collects APB transactions from monitor
                - Compares expected vs actual responses
                - Tracks queue status and scheduling behavior
===================================================================================*/

class scoreboard extends uvm_scoreboard;

  `uvm_component_utils(scoreboard)

  // ============================================================================
  // TLM Ports
  // ============================================================================
  uvm_analysis_imp_decl(_apb_slv);
  uvm_analysis_imp_decl(_req_ack);

  // APB master analysis port - receives APB transactions
  uvm_analysis_imp_apb_slv #(apb_seq_item) apb_mst_port;

  // Request-Acknowledge analysis port - receives req/ack transactions
  uvm_analysis_imp_req_ack #(apb_seq_item) req_ack_port; // TODO Sergiu: define req_ack_seq_item and corresponding analysis port

  // ============================================================================
  // Properties
  // ============================================================================

  // Transaction queues for comparison
  apb_seq_item apb_exp_queue[$];
  apb_seq_item apb_act_queue[$];

  // Status tracking
  int unsigned apb_transactions;
  int unsigned mismatches;
  bit [7:0] queue_status;

  // ============================================================================
  // Register model (simple mirrored variables + prediction)
  // ============================================================================
  localparam bit [1:0] DATA_OUT_ADDR = 2'd0;
  localparam bit [1:0] STATUS_ADDR   = 2'd1;
  localparam bit [1:0] CFG_ADDR      = 2'd2;
  localparam bit [1:0] WEIGHT_ADDR   = 2'd3;

  localparam bit [7:0] DATA_OUT_RST  = 8'h00;
  localparam bit [7:0] STATUS_RST    = 8'h04;
  localparam bit [7:0] CFG_RST       = 8'h0F;
  localparam bit [7:0] WEIGHT_RST    = 8'hE4;

  // Mirrored register values (expected model)
  bit [7:0] data_out_reg;
  bit [7:0] status_reg;
  bit [7:0] cfg_reg;
  bit [7:0] weight_reg;

  // Report counters
  int unsigned ro_write_attempts;
  int unsigned bad_addr_accesses;

  // Configuration
  apb_config_object cfg;

  // ============================================================================
  // Methods
  // ============================================================================

  function new(string name, uvm_component parent);
    super.new(name, parent);

    apb_mst_port = new("apb_mst_port", this);
    req_ack_port = new("req_ack_port", this);

    apb_transactions = 0;
    mismatches = 0;
    queue_status = STATUS_RST;

    reset_reg_model();

    ro_write_attempts = 0;
    bad_addr_accesses = 0;
  endfunction : new

  //=================================================================================
  // UVM Phases
  //=================================================================================

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Get configuration object
    if (!uvm_config_db#(apb_config_object)::get(this, "", "apb_cfg", cfg)) begin
      `uvm_warning("CONFIG_MISSING", "APB configuration object not found")
    end
  endfunction : build_phase

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    // Analysis ports are connected from environment
  endfunction : connect_phase

  //=================================================================================
  // Write Functions for TLM Analysis Ports
  //=================================================================================

  function void write_apb_slv(apb_seq_item item);
    `uvm_info("SB_APB", $sformatf("APB Transaction received: %s", item.convert2string()), UVM_MEDIUM)
    apb_act_queue.push_back(item);
    apb_transactions++;
    predict_and_check_apb(item);
    compare_transactions();
  endfunction : write_apb_slv

  function void write_req_ack(apb_seq_item item);
    `uvm_info("SB_REQ_ACK", $sformatf("REQ-ACK Transaction received: %s", item.convert2string()), UVM_MEDIUM)
    // Process request-acknowledge transactions here
  endfunction : write_req_ack

  //=================================================================================
  // Comparison Methods
  //=================================================================================

  function void check_queue_status(bit [7:0] status);
    // q0_full, q1_full, q2_full, q3_full, qo_full, qo_empty, etc.
    queue_status = status;
    status_reg   = status;
  endfunction : check_queue_status

  function void reset_reg_model();
    data_out_reg = DATA_OUT_RST;
    status_reg   = STATUS_RST;
    cfg_reg      = CFG_RST;
    weight_reg   = WEIGHT_RST;
  endfunction : reset_reg_model

  function bit [7:0] get_exp_read_data(bit [1:0] addr, output bit valid_addr);
    valid_addr = 1'b1;
    case (addr)
      DATA_OUT_ADDR: get_exp_read_data = data_out_reg;
      STATUS_ADDR  : get_exp_read_data = status_reg;
      CFG_ADDR     : get_exp_read_data = cfg_reg;
      WEIGHT_ADDR  : get_exp_read_data = weight_reg;
      default: begin
        valid_addr        = 1'b0;
        get_exp_read_data = 8'h00;
      end
    endcase
  endfunction : get_exp_read_data

  function void predict_and_check_apb(apb_seq_item item);
    bit       valid_addr;
    bit       illegal_write;
    bit [7:0] exp_rdata;
    bit [1:0] addr_lsb;

    addr_lsb = item.address[1:0];

    if (item.operation == WRITE) begin
      predict_write(addr_lsb, item.data[7:0], valid_addr, illegal_write);

      if (illegal_write) begin
        `uvm_warning("SB_RO_WRITE", $sformatf("Write attempted on RO register addr=%0d data=0x%02h", addr_lsb, item.data[7:0]))
      end

      if (!valid_addr) begin
        `uvm_warning("SB_BAD_ADDR", $sformatf("Write on invalid register addr=%0d data=0x%02h", addr_lsb, item.data[7:0]))
      end
    end
    else begin
      exp_rdata = get_exp_read_data(addr_lsb, valid_addr);

      if (!valid_addr) begin
        bad_addr_accesses++;
        `uvm_warning("SB_BAD_ADDR", $sformatf("Read on invalid register addr=%0d (rdata=0x%02h)", addr_lsb, item.data[7:0]))
      end
      else if (item.data[7:0] !== exp_rdata) begin
        mismatches++;
        `uvm_error("SB_RDATA_MISMATCH",
          $sformatf("Read mismatch addr=%0d exp=0x%02h got=0x%02h", addr_lsb, exp_rdata, item.data[7:0]))
      end
    end
  endfunction : predict_and_check_apb

  //=================================================================================
  // Prediction Methods
  //=================================================================================

  function void predict_status();
    // TODO: Implement status prediction based on req/ack transactions and internal model
  endfunction : predict_status

  function void predict_output();
    // TODO: Implement output prediction based on scheduling algorithm and internal model
  endfunction : predict_output

  function void predict_write(bit [1:0] addr, bit [7:0] wdata, output bit valid_addr, output bit illegal_write);
    valid_addr     = 1'b1;
    illegal_write  = 1'b0;

    case (addr)
      CFG_ADDR   : cfg_reg    = wdata;
      WEIGHT_ADDR: weight_reg = wdata;
      DATA_OUT_ADDR, STATUS_ADDR: begin // Read-Only registers
        illegal_write = 1'b1;
        ro_write_attempts++;
      end
      default: begin
        valid_addr = 1'b0;
        bad_addr_accesses++;
      end
    endcase
  endfunction : predict_write

  //=================================================================================
  // Reporting
  //=================================================================================

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);

    `uvm_info("SB_REPORT", $sformatf("Total APB Transactions: %0d", apb_transactions), UVM_LOW)
    `uvm_info("SB_REPORT", $sformatf("Mismatches: %0d", mismatches), UVM_LOW)
    `uvm_info("SB_REPORT", $sformatf("RO write attempts: %0d", ro_write_attempts), UVM_LOW)
    `uvm_info("SB_REPORT", $sformatf("Invalid address accesses: %0d", bad_addr_accesses), UVM_LOW)
    `uvm_info("SB_REPORT", $sformatf("Mirrors DATA_OUT=0x%02h STATUS=0x%02h CFG=0x%02h WEIGHT=0x%02h",
          data_out_reg, status_reg, cfg_reg, weight_reg), UVM_LOW)

    if (mismatches > 0) begin
      `uvm_error("SB_REPORT", $sformatf("Scoreboard found %0d mismatches!", mismatches))
    end else begin
      `uvm_info("SB_REPORT", "Scoreboard: All transactions matched successfully!", UVM_LOW)
    end
  endfunction : report_phase

endclass : scoreboard