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

typedef struct pkt_sch_register {
  bit [APB_ADDR_WIDTH-1:0] address;
  bit [APB_DATA_WIDTH-1:0] reset_value;
  bit writeable;
};

// ============================================================================
// Register Definitions
// ============================================================================

static const pkt_sch_register DATA_OUT_REG = '{
  address:     2'h0,
  reset_value: 8'h00,
  writeable:   1'b0
};

static const pkt_sch_register STATUS_REG = '{
  address:     2'h1,
  reset_value: 8'h04,
  writeable:   1'b0
};

static const pkt_sch_register CFG_REG = '{
  address:     2'h2,
  reset_value: 8'h0F,
  writeable:   1'b1
};

static const pkt_sch_register WEIGHTS_REG = '{
  address:     2'h3,
  reset_value: 8'hE4,
  writeable:   1'b1
};

