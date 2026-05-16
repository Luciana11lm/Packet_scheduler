/*==================================================================================
  Project     : UVM_APB_agent
  File name   : apb_coverage_collector.sv 
  Author      : Mitu Mariana-Luciana
  Description : Collects packet coverage for the APB UVC.
===================================================================================*/

class apb_coverage_collector extends uvm_subscriber #(apb_seq_item);

  `uvm_component_utils(apb_coverage_collector)

  apb_seq_item cov_item;

  // COVERGROUP
  //==================================================================================
  covergroup apb_cg;
    option.per_instance = 1;

    operation_cp : coverpoint cov_item.operation {
      bins read  = {READ };
      bins write = {WRITE};
    }

    address_cp : coverpoint cov_item.address {
      bins low_addr  = {[0                 :   2**ADDR_WIDTH/4 - 1]};
      bins mid_addr  = {[2**ADDR_WIDTH/4   : 3*2**ADDR_WIDTH/4 - 1]};
      bins high_addr = {[3*2**ADDR_WIDTH/4 :   2**ADDR_WIDTH   - 1]};
    }

    data_cp : coverpoint cov_item.data {
      bins zero     = {DATA_WIDTH{1'b0}};
      bins all_ones = {DATA_WIDTH{1'b1}};
      bins others   = default;
    }

    tr_delay_cp : coverpoint cov_item.tr_delay {
      bins no_delay    = {0};
      bins small_delay = {[1 :5  ]};
      bins med_delay   = {[6 :20 ]};
      bins high_delay  = {[21:100]};
    }

    rdy_delay_cp : coverpoint cov_item.rdy_delay {
      bins no_wait    = {0};
      bins small_wait = {[1 : 5 ]};
      bins med_wait   = {[6 : 20]};
      bins high_wait  = {[21:100]};
    }

    error_cp : coverpoint cov_item.error {
      bins no_error = {0};
      bins error    = {1};
    }

    operation_x_error : cross operation_cp, error_cp;
    operation_x_addr  : cross operation_cp, address_cp;
    operation_x_delay : cross operation_cp, tr_delay_cp;
    operation_x_wait  : cross operation_cp, rdy_delay_cp;

  endgroup
  //==================================================================================

  // CONSTRUCTOR
  //==================================================================================
  function new(string name = "apb_coverage_collector", uvm_component parent);
    super.new(name, parent);
    apb_cg = new();
  endfunction : new
  //==================================================================================

  // WRITE
  //==================================================================================
  virtual function void write(apb_seq_item t);
    cov_item = apb_seq_item::type_id::create("cov_item");
    cov_item.copy(t);
    apb_cg.sample();

    `uvm_info(get_full_name(),
              $sformatf("Sampled APB coverage for transaction:\n%s",
              cov_item.sprint()),
              UVM_HIGH)

  endfunction : write
  //==================================================================================

  // REPORT PHASE
  //==================================================================================
  function void report_phase(uvm_phase phase);
    super.report_phase(phase);

    `uvm_info(get_full_name(),
              $sformatf("APB functional coverage: %0.2f%%",
              apb_cg.get_coverage()),
              UVM_LOW)

  endfunction : report_phase
  //==================================================================================

endclass : apb_coverage_collector