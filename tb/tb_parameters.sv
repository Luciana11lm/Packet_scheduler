// ============================================================================
// File: tb_parameters.sv
// Description: Global parameters and constants for testbench
// ============================================================================

// ============================================================================
// Clock and Reset Parameters
// ============================================================================

parameter CLK_PERIOD     = 10ns;             // 100 MHz
parameter RESET_DURATION = CLK_PERIOD * 1;   // 1 clock cycle

// ============================================================================
// APB Protocol Parameters
// ============================================================================

parameter APB_ADDR_WIDTH  = 2;       // APB address width
parameter APB_DATA_WIDTH  = 8;       // APB data width

// ============================================================================
// DUT-specific Parameters
// ============================================================================

parameter FIFO_DEPTH     = 8;       // FIFO depth
parameter FIFO_WIDTH     = 8;       // FIFO data width
