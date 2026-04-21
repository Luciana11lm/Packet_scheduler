/*==================================================================================
  Project     : UVM_APB_agent
  File name   : apb_config_object.sv 
  Author      : Mitu Mariana-Luciana
  Description : Encapsulates all configuration parameters for the APB agent,
                including operational mode and APB role selection.
===================================================================================*/

class apb_config_object extends uvm_object;

  uvm_active_passive_enum is_active = UVM_ACTIVE;         // {UVM_ACTIVE, UVM_PASIVE} 
  role_t                  apb_role  = MASTER    ;         // APB agent role {SLAVE, MASTER}

  `uvm_object_utils_begin(apb_config_object)
    `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_ALL_ON | UVM_STRING)
    `uvm_field_enum(role_t                 , apb_role , UVM_ALL_ON | UVM_STRING)
  `uvm_object_utils_end

  // CONSTRUCTOR
  //==================================================================================
  function new(string name = "apb_config_object");
    super.new(name);
  endfunction : new
  //==================================================================================

endclass : apb_config_object