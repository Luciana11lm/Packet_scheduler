/*==================================================================================
  Project     : Packet Scheduler Verification
  File name   : req_ack_monitor.sv
  Author      : Acatrinei Sergiu
  Description : Observes request-acknowledge handshakes and forwards them
                to the scoreboard through an analysis port.
===================================================================================*/

class req_ack_monitor extends uvm_monitor;

  `uvm_component_utils(req_ack_monitor)

  uvm_analysis_port#(req_ack_seq_item) req_ack_ap        ;
  virtual req_ack_interface            req_ack_vif       ;
  virtual req_ack_interface.rcv_mp     req_ack_rcv_mp    ;
  req_ack_seq_item                     req_ack_pkt       ;
  int unsigned                         cycle_count       ;
  int unsigned                         no_items_rcv      ;

  // CONSTRUCTOR
  //==================================================================================
  function new(string name = "req_ack_monitor", uvm_component parent);
    super.new(name, parent);
    no_items_rcv    = 0;
    cycle_count     = 0;
  endfunction : new
  //==================================================================================

  // BUILD PHASE
  //==================================================================================
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    req_ack_pkt = req_ack_seq_item::type_id::create("req_ack_pkt");
    req_ack_ap  = new("req_ack_ap", this);

    if(!uvm_config_db#(virtual req_ack_interface)::get(this, "", "req_ack_vif", req_ack_vif))
      `uvm_fatal(get_full_name(), "REQ/ACK virtual interface not found in config db for req_ack monitor!")

    req_ack_rcv_mp = req_ack_vif.rcv_mp;
  endfunction : build_phase
  //==================================================================================

  // RUN PHASE
  //==================================================================================
  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    fork
      monitor_req_ack();
    join_none
  endtask : run_phase
  //==================================================================================

  task monitor_req_ack();
    forever begin
      @(posedge req_ack_vif.clock);
      cycle_count++;
      if(req_ack_vif.reset == 1'b0) begin
        cycle_count = 0;
      end else if(req_ack_rcv_mp.rcv_cb.req) begin
        int unsigned req_start_cycle = cycle_count;
        while(req_ack_vif.reset != 1'b0 && !req_ack_rcv_mp.rcv_cb.ack) begin
          @(posedge req_ack_vif.clock);
          cycle_count++;
        end
        if(req_ack_vif.reset == 1'b0) begin
          cycle_count = 0;
        end else begin
          req_ack_pkt = req_ack_seq_item::type_id::create($sformatf("req_ack_pkt_%0d", no_items_rcv));
          req_ack_pkt.ack_seen    = 1'b1;
          req_ack_pkt.wait_cycles = cycle_count - req_start_cycle;
          req_ack_pkt.data        = req_ack_rcv_mp.rcv_cb.data;

          `uvm_info(get_full_name(), $sformatf("Packet monitored %0d: %s", no_items_rcv, req_ack_pkt.convert2string()), UVM_LOW)
          no_items_rcv++;
          req_ack_ap.write(req_ack_pkt);
        end
      end
    end
  endtask : monitor_req_ack

  // REPORT PHASE
  //==================================================================================
  function void report_phase(uvm_phase phase);
    `uvm_info(get_full_name(), $sformatf("Report: REQ/ACK monitor received %0d packets", no_items_rcv), UVM_LOW)
  endfunction : report_phase
  //==================================================================================

  //==================================================================================

endclass : req_ack_monitor
