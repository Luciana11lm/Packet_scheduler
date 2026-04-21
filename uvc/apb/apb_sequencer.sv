/*==================================================================================
  Project     : UVM_APB_agent
  File name   : apb_seqencer.sv 
  Author      : Mitu Mariana-Luciana
  Description : Arbitrates and forwards APB sequence item from sequences to the APB
                driver. Supports read/write transfers on the APB bus.
===================================================================================*/

class apb_sequencer extends uvm_sequencer #(apb_seq_item)ș

  `uvm_component_utils(apb_sequencer)

  // CONSTRUCTOR
  //==================================================================================
  function new(string name = "apb_sequencer", uvm_component parent);
    super.new(name, parent);
  endfunction : new
  //==================================================================================

  // START OF SIMULATION PHASE
  //==================================================================================
  function void start_of_simulation_phase(uvm_phase phase);
    super.start_of_simulation_phase(phase);
    `uvm_info(get_full_name(), "Start the simulation", UVM_HIGH)
  endfunction : start_of_simulation_phase
  //==================================================================================

endclass : apb_sequencer