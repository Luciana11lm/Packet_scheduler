/*==================================================================================
  Project     : UVM_APB_agent
  File name   : apb_sequence_lib.sv 
  Author      : Mitu Mariana-Luciana
  Description : APB sequence library containing a generic base sequence and specialized
                master read/write sequences. The library provides reusable sequences for
                generating configurable APB transactions with programmable delay, address,
                data and operation type.
===================================================================================*/

//================================================================================= 
// Class      : apb_base_sequence
// Description: Generic APB base sequence used to generate configurable APB 
//              transactions. The sequence creates and randomizes an APB sequence 
//              item using user-defined parameters such as transaction delay, address, 
//              data and operation type. This class serves as a base for specialized 
//              APB read/write sequences.
//================================================================================= 
class apb_base_sequence extends uvm_sequence #(apb_seq_item);

  `uvm_object_utils(apb_base_sequence)

  rand int unsigned           pkt_delay    ;
  rand bit [ADDR_WIDTH-1:0]   pkt_address  ;
  rand bit [DATA_WIDTH-1:0]   pkt_data     ;
  rand operation_t            pkt_operation;

  constraint min_max_delay_c {pkt_delay inside {[0:100]};}

  // CONSTRUCTOR
  //================================================================================= 
  function new(string name = "apb_base_sequence");
    super.new(name);
  endfunction
  //=================================================================================

  // BODY
  //=================================================================================
  virtual task body();

    apb_seq_item req;
    req = apb_seq_item::type_id::create("req");

    start_item(req);
    if (!req.randomize() with {
      tr_delay  == local::pkt_delay    ;
      address   == local::pkt_address  ;
      data      == local::pkt_data     ;
      operation == local::pkt_operation;
    }) begin
      `uvm_error(get_type_name(), "Randomization failed for APB sequence item")
    end

    finish_item(req);

  endtask
  //=================================================================================

endclass : apb_base_sequence
  


//================================================================================= 
// Class      : apb_mst_wr_seq
// Description: APB master write sequence derived from apb_base_sequence.
//              Constrains the transaction type to WRITE and generates APB write
//              transactions toward the DUT.
//================================================================================= 
class apb_mst_wr_seq extends apb_base_sequence;
  `uvm_object_utils(apb_mst_wr_seq)

  constraint operation_wr_c { pkt_operation == WRITE;}

  // CONSTRUCTOR
  //================================================================================= 
  function new(string name = "apb_mst_wr_seq");
    super.new(name);
  endfunction
  //=================================================================================

endclass



//================================================================================= 
// Class      : apb_mst_rd_seq
// Description: APB master read sequence derived from apb_base_sequence.
//              Constrains the transaction type to READ and generates APB read
//              transactions toward the DUT.
//=================================================================================
class apb_mst_rd_seq extends apb_base_sequence;
  `uvm_object_utils(apb_mst_rd_seq)

  constraint operation_rd_c { pkt_operation == READ;}

  // CONSTRUCTOR
  //================================================================================= 
  function new(string name = "apb_mst_rd_seq");
    super.new(name);
  endfunction
  //=================================================================================

endclass