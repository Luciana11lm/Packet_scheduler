/*==================================================================================
  Project     : UVM_APB_agent
  File name   : apb_monitor.sv 
  Author      : Mitu Mariana-Luciana
  Description : Observes and capture APB tranactions from the bus interface, then 
                send them to scoreboard using analysis port.
===================================================================================*/

class apb_monitor extends uvm_monitor;

  `uvm_component_utils(apb_monitor)

  uvm_analysis_port#(apb_seq_item)       apb_ap            ;    // Analysis port for sending the item monitored
  virtual apb_interface                  apb_vif           ;    // APB virtual interface for monitoring
  virtual apb_interface.rcv_mp           apb_rcv_mp        ;    // APB receiving modport
  apb_seq_item                           apb_pkt           ;    // APB sequence item monitored
  int unsigned                           tr_delay          ;    // Transaction delay
  int unsigned                           rdy_delay         ;    // Wait states between PENABLE and PREADY assertion
  int unsigned                           no_items_rcv      ;    // Number of items received

  // CONSTRUCTOR
  //==================================================================================
  function new(string name = "apb_monitor", uvm_component parent);
    super.new(name, parent);
    no_items_rcv = 0;
    tr_delay     = 0;
    rdy_delay    = 0;
  endfunction : new
  //==================================================================================

  // BUILD PHASE
  //==================================================================================
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    apb_pkt = apb_seq_item::type_id::create("apb_pkt");

    if(!uvm_config_db#(virtual apb_interface)::get(this, "", "apb_vif", apb_vif))
      `uvm_fatal(get_full_name(), "APB virtual interface not found in config db for APB monitor!")
    apb_rcv_mp = apb_vif.rcv_mp;
  endfunction : build_phase
  //==================================================================================

  // RUN PHASE
  //==================================================================================
  task run_phase(uvm_phase phase);
    super.run_phase(phase);

    forever begin
      fork
        begin : guard_fork
          fork
            begin : monitor_seq_item
              monitor_apb_item();
            end                         
            begin : system_reset                         
              system_reset_detected();                                                         // Detect system reset 
            end
          join_any
          disable fork;
        end
      join
    end

  endtask : run_phase
  //==================================================================================

  //REPORT PHASE
  //==================================================================================
  function void report_phase(uvm_phase phase);
    `uvm_info(get_full_name(), $sformatf("Report: APB monitor received %0d packets", no_items_rcv), UVM_LOW)
  endfunction : report_phase
  //==================================================================================

  // OBSERVE SEQUENCE ITEM RECEIVED
  //==================================================================================
  task monitor_apb_item();
    wait(apb_vif.reset == 1'b0);
    while(apb_rcv_mp.psel == 1'b0) begin
      tr_delay++;
      @(posedge apb_vif.clock);
    end
    apb_pkt.tr_dealy = tr_dealy;
    @(posedge apb_rcv_mp.penable);
    while(apb_rcv_mp.pready == 1'b0) begin
      rdy_delay++;
      @(posedge apb_vif.clock);
    end
    if(apb_rcv_mp.psel & apb_rcv_mp.penable & apb_rcv_mp.pready) begin
      apb_pkt.address   = apb_rcv_mp.paddr;
      apb_pkt.operation = operation_t'(apb_rcv_mp.pwrite);
      apb_pkt.data      = (apb_pkt.operation == WRITE) ? apb_rcv_mp.pwdata : apb_rcv_mp.prdata;
      apb_pkt.error     = apb_rcv_mp.pslverr;
      `uvm_info(get_full_name(), $sformatf("Packet monitored %0d: \ns", no_items_rcv, apb_pkt.sprint()), UVM_LOW)
      no_items_rcv++;
      apb_ap.write(apb_pkt);
    end
    else
      `uvm_info(get_full_name(), "Packet dropped due to protocol violation!", UVM_LOW)
  endtask : monitor_apb_item
  //==================================================================================

  //  SYSTEM RESET DETECTED 
  //==================================================================================
  task system_reset_detected();
    wait(apb_vif.reset == 1'b1);
    @(negedge apb_vif.reset);
  endtask : system_reset_detected
  //==================================================================================

endclass : apb_monitor