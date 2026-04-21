// INTERFACE ASSERTIONS
//==================================================================================
  // 1. PSEL must be deasserted during reset
  property psel_rst;
    @(posedge reset)
      reset |-> !psel
  endproperty : psel_rst
  assert property(psel_rst)
  else $error("PSEL is not 0 during reset!");

  // 2. PENABLE must be deasserted during reset
  property penable_rst;
    @(posedge reset)
      reset |-> !penable
  endproperty : penable_rst
  assert property(penable_rst)
  else $error("PENABLE is not 0 during reset!");

  // 3. PWRITE must be deasserted during reset
  property pwrite_rst;
    @(posedge reset)
      reset |-> !pwrite
  endproperty : pwrite_rst
  assert property(pwrite_rst)
  else $error("PWRITE is not 0 during reset!");

  // 4. PREADY must be deasserted during reset
  property pready_rst;
    @(posedge reset)
      reset |-> !pready
  endproperty : pready_rst
  assert property(pready_rst)
  else $error("PREADY is not 0 during reset!");

  // 5. PSLVERR must be deasserted during reset
  property pslverr_rst;
    @(posedge reset)
      reset |-> !pslverr
  endproperty : pslverr_rst
  assert property(pslverr_rst)
  else $error("PSLVERR is not 0 during reset!");

  // 6. PADDR must be deasserted during reset
  property paddr_rst;
    @(posedge reset)
      reset |-> !paddr
  endproperty : paddr_rst
  assert property(paddr_rst)
  else $error("PADDR is not 0 during reset!");

  // 7. PWDATA must be deasserted during reset
  property pwdata_rst;
    @(posedge reset)
      reset |-> !pwdata
  endproperty : pwdata_rst
  assert property(pwdata_rst)
  else $error("PWDATA is not 0 during reset!");

  // 8. PRDATA must be deasserted during reset
  property prdata_rst;
    @(posedge reset)
      reset |-> !prdata
  endproperty : prdata_rst
  assert property(prdata_rst)
  else $error("PRDATA is not 0 during reset!");

  // 9. PENABLE must not be asserted without PSEL in SETUP phase
  property penable_ast_with_psel;
    @(posedge clock) disable iff reset
      penable |-> psel
  endproperty : penable_ast_with_psel
  assert property(penable_ast_with_psel)
  else $error("PENABLE must not be asserted without PSEL in SETUP phase!");

  // 10. PSEL must be stable at least one cycle before PENABLE
  property psel_stable_before_penable;
    @(posedge clock) disable iff reset
      $rose(penable) |-> $past(psel, 1)
  endproperty : psel_stable_before_penable
  assert property(penable_ast_with_psel)
  else $error("PSEL must be stable at least one cycle before PENABLE!");

  // 11. PENABLE must be asserted exactly one cycle after PSEL
  property penable_one_cycle_after_psle;
    @(posedge clock) disable iff reset
      $rose(psel) |=> $rose(penable)
  endproperty : penable_one_cycle_after_psle
  assert property(penable_one_cycle_after_psle)
  else $error("PENABLE must be asserted exactly one cycle after PSEL!");

  // 12. PADDR must remain stable during setup phase
  property address_stable_on_setup;
    @(posedge clock) disable iff reset
      (psel & penable) |-> $stable(paddr)
  endproperty : address_stable_on_setup
  assert property(address_stable_on_setup)
  else $error("PADDR must remain stable during setup phase!");

  // 13. PWRITE must remain stable during setup phase
  property pwrite_stable_on_setup;
    @(posedge clock) disable iff reset
      (psel & penable) |-> $stable(pwrite)
  endproperty : pwrite_stable_on_setup
  assert property(pwrite_stable_on_setup)
  else $error("PWRITE must remain stable during setup phase!");

  // 14. PWDATA must remain stable during setup phase
  property pwdata_stable_on_setup;
    @(posedge clock) disable iff reset
      (psel & penable) |-> $stable(pwdata)
  endproperty : pwdata_stable_on_setup
  assert property(pwdata_stable_on_setup)
  else $error("PWDATA must remain stable during setup phase!");

  // 15. PSEL must remain stable during setup phase
  property psel_stable_on_setup;
    @(posedge clock) disable iff reset
      (psel & penable) |-> $stable(psel)
  endproperty : psel_stable_on_setup
  assert property(psel_stable_on_setup)
  else $error("PSEL must remain stable during setup phase!");

  // 16. PREADY must not be asserted without PSEL and PENABLE
  property pready_ast_when_psel_and_penable;
    @(posedge clock) disable iff reset
      pready |-> (psel & penable)
  endproperty : pready_ast_when_psel_and_penable
  assert property(pready_ast_when_psel_and_penable)
  else $error("PSEL must remain stable during setup phase!");

  // 17. Transfer must complete when PREADY asserted
  property transfer_complete;
    @(posedge clock) disable iff reset
      (psel & penable & pready) |-> !penable
  endproperty : transfer_complete
  assert property(transfer_complete)
  else $error("Transfer must complete when PREADY asserted!");

  // 18. PWDATA must be valid when PSEL and PWRITE are asserted
  property pwdata_valid_setup;
    @(posedge clock) disable iff reset
      (psel & pwrite) |-> !$isunknown(pwdata)
  endproperty : pwdata_valid_setup
  assert property(pwdata_valid_setup)
  else $error("PWDATA must be valid when PSEL and PWRITE are asserted!");

  // 19. PRDATA must be valid when PREADY asserted
  property prdata_valid_access;
    @(posedge clock) disable iff reset
      (psel & penable & pready & !pwrite) |-> !$isunknown(prdata)
  endproperty : prdata_valid_access
  assert property(prdata_valid_access)
  else $error("PRDATA must be valid when PREADY asserted!");

  // 20. PSLVERR must only be asserted during access phase 
  property pslverr_ast_access;
    @(posedge clock) disable iff reset
      pslverr |-> (psel & penable & pready)
  endproperty : pslverr_ast_access
  assert property(pslverr_ast_access)
  else $error("PSLVERR must only be asserted during access phase!");

  // 21. PSLVERR must be deasserted after transaction complete
  property pslverr_deast;
    @(posedge clock) disable iff reset
      (pslverr & pready) |=> !pslverr
  endproperty : pslverr_deast
  assert property(pslverr_deast)
  else $error("PSLVERR must be deasserted after transaction complete!");
//==================================================================================