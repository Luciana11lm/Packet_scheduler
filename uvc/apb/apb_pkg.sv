/*==================================================================================
  Project     : UVM_APB_agent
  File name   : apb_pkg.sv 
  Author      : Mitu Mariana-Luciana
  Description : File used to import in top (or where it is necessary) 
                all files related to the verification environment.
===================================================================================*/

package apb_pkg;
   import uvm_pkg::*;

   `include "uvm_macros.svh"

   `include "spi_types_params.sv"
   `include "apb_seq_item.sv"
   `include "apb_config_object.sv"
   `include "apb_sequence_lib.sv"
   `include "apb_sequencer.sv"
   `include "apb_driver.sv"
   `include "apb_monitor.sv"
   `include "apb_agent.sv"
endpackage