/*==================================================================================
  Project     : UVM_APB_agent
  File name   : apb_driver.sv 
  Author      : Mitu Mariana-Luciana
  Description : Drives APB transactions onto the bus interface, supporting both 
                master and slave modes based on the configuration object. Uses 
                synchronous modports for driving signals and asynchronous
                modports for reset handling.
===================================================================================*/

class apb_driver extends uvm_driver #(apb_seq_item);

  `uvm_component_utils(apb_driver)

  virtual apb_interface                  apb_vif           ;    // APB virtual interface for driving
  virtual apb_interface.drv_mst_mp       apb_mst_sync_mp   ;    // APB master synchronous modport
  virtual apb_interface.drv_async_mst_mp apb_mst_async_mp  ;    // APB master asynchronous modport
  virtual apb_interface.drv_slv_mp       apb_slv_sync_mp   ;    // APB slave synchronous modport
  virtual apb_interface.drv_async_slv_mp apb_slv_async_mp  ;    // APB slave asynchronous modport
  apb_config_object                      apb_cfg_obj       ;    // APB configuration object 
  apb_seq_item                           apb_pkt           ;    // APB sequence item received from sequencer
  int unsigned                           no_items_sent     ;    // Number of items sent

  // CONSTRUCTOR
  //==================================================================================
  function new(string name = "apb_driver", uvm_component parent);
    super.new(name, parent);
    no_items_sent = 0;
  endfunction : new
  //==================================================================================

  // BUILD PHASE
  //==================================================================================
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    apb_pkt     = apb_seq_item     ::type_id::create("apb_pkt"    );
    apb_cfg_obj = apb_config_object::type_id::create("apb_cfg_obj");

    if(!uvm_config_db#(virtual apb_interface)::get(this, "", "apb_vif", apb_vif))
      `uvm_fatal(get_full_name(), "APB virtual interface not found in config db for APB driver!")

    if(!uvm_config_db#(apb_config_object)::get(this, "", "apb_cfg_obj", apb_cfg_obj))
      `uvm_fatal(get_full_name(), "APB configuration object interface not found in config db for APB driver!")
    
    if(apb_cfg_obj.apb_role == MASTER) begin
      apb_mst_sync_mp  = apb_vif.drv_mst_mp;
      apb_mst_async_mp = apb_vif.drv_async_mst_mp;
    end
    else begin
      apb_slv_sync_mp  = apb_vif.drv_slv_mp;
      apb_slv_async_mp = apb_vif.drv_async_slv_mp;
    end
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
            begin : drive_seq_item
              seq_item_port.get_next_item(apb_pkt);                                            // Get APB sequence item from sequencer
              if(apb_cfg_obj.apb_role == MASTER)                         
                drive_apb_item_mst(apb_pkt);                                                   // Drive APB sequence item as master
              else                         
                drive_apb_item_slv(apb_pkt);                                                   // Drive APB sequence item as slave
              no_items_sent++;                                                                 // Increment the number of items sent
              seq_item_port.item_done();                                                       // Item done sent to sequencer
            end                         
            begin : system_reset                         
              system_reset_detected();                                                         // Detect system reset and reset all signals
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
    `uvm_info(get_full_name(), $sformatf("Report: APB driver sent %0d packets", no_items_sent), UVM_LOW)
  endfunction : report_phase
  //==================================================================================

  //  DRIVE APB SEQUENCE ITEM AS MASTER
  //==================================================================================
  task drive_apb_item_mst(apb_seq_item apb_item);
    wait(apb_vif.reset == 1'b0);
    `uvm_info(get_full_name(), $sformatf("Sending APB packet %0d: \ns", no_items_sent, apb_item.sprint()), UVM_LOW)
    repeat(apb_item.tr_delay) @(posedge apb_vif.clock);                                        // Wait tr_dealy clock cycles before transaction start
    apb_mst_sync_mp.drv_cb_mst.psel    = 1'b1;                                                 // Set PSEL
    apb_mst_sync_mp.drv_cb_mst.pwrite  = bit'(apb_item.operation);                             // Assign the operation type to PWRITE
    apb_mst_sync_mp.drv_cb_mst.paddr   = apb_item.address;                                     // Assign the address to PADDR
    apb_mst_sync_mp.drv_cb_mst.pwdata  = (apb_item.operation == WRITE) ? apb_item.data : 'd0;  // Assign the data to PWDATA only for write operation
    @(posedge apb_vif.clock);                                                                  // After one clock cycle set PENABLE
    apb_mst_sync_mp.drv_cb_mst.penable = 1'b1; 
    @(posedge apb_mst_sync_mp.drv_cb_mst.pready);                                              // After PREADY assertion, reset signals
    apb_mst_sync_mp.drv_cb_mst.psel    = 1'b0;
    apb_mst_sync_mp.drv_cb_mst.penable = 1'b0;
    apb_mst_sync_mp.drv_cb_mst.pwrite  = 1'b0;
    apb_mst_sync_mp.drv_cb_mst.paddr   = 'd0;
    apb_mst_sync_mp.drv_cb_mst.pwdata  = 'd0;
  endtask : drive_apb_item_mst
  //==================================================================================

  //  DRIVE APB SEQUENCE ITEM AS SLAVE 
  //==================================================================================
  task drive_apb_item_slv(apb_seq_item apb_item);
    wait(apb_vif.reset == 1'b0);
    `uvm_info(get_full_name(), $sformatf("Sending APB packet %0d: \ns", no_items_sent, apb_item.sprint()), UVM_LOW)
    wait(apb_slv_sync_mp.drv_cb_slv.psel == 1'b1);
    @(posedge apb_slv_sync_mp.drv_cb_slv.penable);
    repeat(apb_item.rdy_delay) @(posedge apb_vif.clock);                                         // Wait rdy_delay before asserting PREADY
    apb_slv_sync_mp.drv_cb_slv.pready  = 1'b1;
    apb_slv_sync_mp.drv_cb_slv.pslverr = apb_item.error;                                      
    apb_slv_sync_mp.drv_cb_slv.prdata  = (apb_item.operation == READ) ? apb_item.data : 'd0;
    @(posedge apb_vif.clock);                                                                    // Reset signals after one clock cycle
    apb_slv_sync_mp.drv_cb_slv.pready  = 1'b0;
    apb_slv_sync_mp.drv_cb_slv.pslverr = 1'b0;
    apb_slv_sync_mp.drv_cb_slv.prdata  = 'd0;
  endtask : drive_apb_item_slv
  //==================================================================================

  //  SYSTEM RESET DETECTED : reset all protocol signals when system reset is aserted
  //==================================================================================
  task system_reset_detected();
    wait(apb_vif.reset == 1'b1);
    apb_mst_async_mp.psel    = 1'b0;
    apb_mst_async_mp.penable = 1'b0; 
    apb_mst_async_mp.pwrite  = 1'b0;
    apb_mst_async_mp.paddr   = 'd0;
    apb_mst_async_mp.pwdata  = 'd0;
    @(negedge apb_vif.reset);
  endtask : system_reset_detected
  //==================================================================================

endclass : apb_driver