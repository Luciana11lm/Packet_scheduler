// ---------------------------------------------------------------------------------------------------------------------
// Module name : pachet_scheduler
// HDL         : SystemVerilog
// Author      : Boziesan Stefan
// Description : Packet scheduler with APB register interface and 4 req/ack client inputs.
//               Data direction: clients -> input FIFOs -> scheduler -> output FIFO -> APB read.
// ---------------------------------------------------------------------------------------------------------------------

module pachet_scheduler #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 2
)(
    input  logic                  clk_i,
    input  logic                  rstn_i,

    // APB interface
    input  logic                  psel_i,
    input  logic                  penable_i,
    input  logic                  pwrite_i,
    input  logic [ADDR_WIDTH-1:0] paddr_i,
    input  logic [DATA_WIDTH-1:0] pwdata_i,
    output logic [DATA_WIDTH-1:0] prdata_o,
    output logic                  pready_o,
    output logic                  pslverr_o,

    // Client 0 interface
    input  logic                  req0,
    output logic                  ack0,
    input  logic [DATA_WIDTH-1:0] data0,

    // Client 1 interface
    input  logic                  req1,
    output logic                  ack1,
    input  logic [DATA_WIDTH-1:0] data1,

    // Client 2 interface
    input  logic                  req2,
    output logic                  ack2,
    input  logic [DATA_WIDTH-1:0] data2,

    // Client 3 interface
    input  logic                  req3,
    output logic                  ack3,
    input  logic [DATA_WIDTH-1:0] data3
);

// ---------------------------------------------------------------------------------------------------------------------
// Local parameters / register map
// ---------------------------------------------------------------------------------------------------------------------
localparam logic [1:0] ADDR_OUT_Q   = 2'd0;
localparam logic [1:0] ADDR_STATUS  = 2'd1;
localparam logic [1:0] ADDR_CFG     = 2'd2;
localparam logic [1:0] ADDR_WEIGHTS = 2'd3;

localparam logic [1:0] ALG_SP       = 2'b00;
localparam logic [1:0] ALG_RR       = 2'b01;
localparam logic [1:0] ALG_INVALID  = 2'b10;
localparam logic [1:0] ALG_WRR      = 2'b11;

// ---------------------------------------------------------------------------------------------------------------------
// APB transaction decode
// ---------------------------------------------------------------------------------------------------------------------
logic apb_access;
logic apb_wr;
logic apb_rd;
logic invalid_addr;

assign apb_access = psel_i & penable_i;
assign apb_wr     = apb_access &  pwrite_i;
assign apb_rd     = apb_access & ~pwrite_i;

// If ADDR_WIDTH is exactly 2, invalid_addr is always 0. The comparison is kept for parameterized variants.
assign invalid_addr = (paddr_i > ADDR_WEIGHTS);

// No wait-states: APB transfer completes in the access phase.
assign pready_o = apb_access;

// ---------------------------------------------------------------------------------------------------------------------
// Control registers
// ---------------------------------------------------------------------------------------------------------------------
logic [DATA_WIDTH-1:0] cfg_reg;
logic [DATA_WIDTH-1:0] weights_reg;

wire [1:0] alg_sel = cfg_reg[5:4];
wire [3:0] client_en = cfg_reg[3:0];

wire [1:0] w0 = weights_reg[1:0];
wire [1:0] w1 = weights_reg[3:2];
wire [1:0] w2 = weights_reg[5:4];
wire [1:0] w3 = weights_reg[7:6];

function automatic logic weights_unique(input logic [DATA_WIDTH-1:0] w);
    logic [1:0] fw0, fw1, fw2, fw3;
    begin
        fw0 = w[1:0];
        fw1 = w[3:2];
        fw2 = w[5:4];
        fw3 = w[7:6];
        weights_unique = (fw0 != fw1) && (fw0 != fw2) && (fw0 != fw3) &&
                         (fw1 != fw2) && (fw1 != fw3) &&
                         (fw2 != fw3);
    end
endfunction

// ---------------------------------------------------------------------------------------------------------------------
// FIFO status signals
// ---------------------------------------------------------------------------------------------------------------------
logic q0_full, q1_full, q2_full, q3_full;
logic q0_empty, q1_empty, q2_empty, q3_empty;
logic out_q_full, out_q_empty;

logic [DATA_WIDTH-1:0] q0_dout, q1_dout, q2_dout, q3_dout;
logic [DATA_WIDTH-1:0] out_q_dout;

wire input_q_full_any = q0_full | q1_full | q2_full | q3_full;

wire [DATA_WIDTH-1:0] status_reg = {
    q0_full,       // bit 7 - Q0F
    q1_full,       // bit 6 - Q1F
    q2_full,       // bit 5 - Q2F
    q3_full,       // bit 4 - Q3F
    out_q_full,    // bit 3 - QoF
    out_q_empty,   // bit 2 - QoE
    2'b00          // bit 1:0 - reserved
};

// ---------------------------------------------------------------------------------------------------------------------
// APB error generation
// ---------------------------------------------------------------------------------------------------------------------
logic cfg_write_invalid;
logic weights_write_invalid;
logic apb_error_comb;

always_comb begin
    cfg_write_invalid = 1'b0;
    if (apb_wr && !invalid_addr && (paddr_i[1:0] == ADDR_CFG)) begin
        // alg_sel = 2'b10 is not a legal algorithm.
        if (pwdata_i[5:4] == ALG_INVALID)
            cfg_write_invalid = 1'b1;
        // WRR may be selected only if the current weights are unique.
        else if ((pwdata_i[5:4] == ALG_WRR) && !weights_unique(weights_reg))
            cfg_write_invalid = 1'b1;
    end
end

always_comb begin
    weights_write_invalid = 1'b0;
    if (apb_wr && !invalid_addr && (paddr_i[1:0] == ADDR_WEIGHTS)) begin
        // If WRR is already active, the new weights must remain unique.
        if ((alg_sel == ALG_WRR) && !weights_unique(pwdata_i))
            weights_write_invalid = 1'b1;
    end
end

always_comb begin
    apb_error_comb = 1'b0;

    if (apb_access) begin
        // Invalid address, relevant only when ADDR_WIDTH allows values above 3.
        if (invalid_addr)
            apb_error_comb = 1'b1;

        // Any full input queue blocks normal APB accesses. Status read remains allowed,
        // so the APB host can observe which input queue caused the problem.
        if (input_q_full_any && !(apb_rd && (paddr_i[1:0] == ADDR_STATUS)))
            apb_error_comb = 1'b1;

        if (apb_wr) begin
            unique case (paddr_i[1:0])
                ADDR_OUT_Q   : apb_error_comb = 1'b1;                 // APB cannot write output queue
                ADDR_STATUS  : apb_error_comb = 1'b1;                 // status_reg is read-only
                ADDR_CFG     : if (cfg_write_invalid) apb_error_comb = 1'b1;
                ADDR_WEIGHTS : if (weights_write_invalid) apb_error_comb = 1'b1;
                default      : apb_error_comb = 1'b1;
            endcase
        end
        else begin
            unique case (paddr_i[1:0])
                ADDR_OUT_Q   : if (out_q_empty) apb_error_comb = 1'b1; // cannot read empty output queue
                ADDR_STATUS  : apb_error_comb = apb_error_comb;
                ADDR_CFG     : apb_error_comb = apb_error_comb;
                ADDR_WEIGHTS : apb_error_comb = apb_error_comb;
                default      : apb_error_comb = 1'b1;
            endcase
        end
    end
end

// Registered PSLVERR, valid in the APB access phase.
always_ff @(posedge clk_i or negedge rstn_i) begin
    if (!rstn_i)
        pslverr_o <= 1'b0;
    else
        pslverr_o <= apb_error_comb;
end

// ---------------------------------------------------------------------------------------------------------------------
// APB register writes
// Writes take effect only when the access is valid and does not produce PSLVERR.
// ---------------------------------------------------------------------------------------------------------------------
always_ff @(posedge clk_i or negedge rstn_i) begin
    if (!rstn_i) begin
        cfg_reg     <= 8'b0000_1111; // alg_sel = 00/SP, all clients enabled
        weights_reg <= 8'b11_10_01_00;
    end
    else begin
        if (apb_wr && !apb_error_comb) begin
            unique case (paddr_i[1:0])
                ADDR_CFG: begin
                    // Keep reserved bits [7:6] at 0.
                    cfg_reg <= {2'b00, pwdata_i[5:0]};
                end

                ADDR_WEIGHTS: begin
                    weights_reg <= pwdata_i;
                end

                default: begin
                    cfg_reg     <= cfg_reg;
                    weights_reg <= weights_reg;
                end
            endcase
        end
    end
end

// ---------------------------------------------------------------------------------------------------------------------
// APB reads
// For output_q, the FIFO read pulse is generated in the same access cycle in which PRDATA captures dout.
// ---------------------------------------------------------------------------------------------------------------------
logic out_q_rd;
assign out_q_rd = apb_rd && !apb_error_comb && (paddr_i[1:0] == ADDR_OUT_Q);

always_ff @(posedge clk_i or negedge rstn_i) begin
    if (!rstn_i) begin
        prdata_o <= '0;
    end
    else begin
        if (apb_rd) begin
            unique case (paddr_i[1:0])
                ADDR_OUT_Q   : prdata_o <= (!apb_error_comb) ? out_q_dout  : '0;
                ADDR_STATUS  : prdata_o <= status_reg;
                ADDR_CFG     : prdata_o <= (!apb_error_comb) ? cfg_reg     : '0;
                ADDR_WEIGHTS : prdata_o <= (!apb_error_comb) ? weights_reg : '0;
                default      : prdata_o <= '0;
            endcase
        end
        else begin
            prdata_o <= '0;
        end
    end
end

// ---------------------------------------------------------------------------------------------------------------------
// REQ-ACK handler
// A client transfer is accepted when the client is enabled and its input FIFO is not full.
// ---------------------------------------------------------------------------------------------------------------------
assign ack0 = req0 & client_en[0] & !q0_full;
assign ack1 = req1 & client_en[1] & !q1_full;
assign ack2 = req2 & client_en[2] & !q2_full;
assign ack3 = req3 & client_en[3] & !q3_full;

wire q0_wr = ack0;
wire q1_wr = ack1;
wire q2_wr = ack2;
wire q3_wr = ack3;

// ---------------------------------------------------------------------------------------------------------------------
// Scheduling logic
// ---------------------------------------------------------------------------------------------------------------------
logic [3:0] valid_q;
logic [3:0] grant;
logic [1:0] rr_ptr;
logic [1:0] wrr_ptr;
logic [2:0] wrr_credit;

logic [1:0] selected_idx;
logic       selected_valid;
logic [DATA_WIDTH-1:0] selected_data;

assign valid_q[0] = client_en[0] & !q0_empty;
assign valid_q[1] = client_en[1] & !q1_empty;
assign valid_q[2] = client_en[2] & !q2_empty;
assign valid_q[3] = client_en[3] & !q3_empty;

function automatic logic [2:0] weight_quota(input logic [1:0] idx,
                                            input logic [DATA_WIDTH-1:0] w);
    begin
        unique case (idx)
            2'd0: weight_quota = {1'b0, w[1:0]} + 3'd1;
            2'd1: weight_quota = {1'b0, w[3:2]} + 3'd1;
            2'd2: weight_quota = {1'b0, w[5:4]} + 3'd1;
            2'd3: weight_quota = {1'b0, w[7:6]} + 3'd1;
        endcase
    end
endfunction

function automatic logic [3:0] onehot_from_idx(input logic [1:0] idx);
    begin
        unique case (idx)
            2'd0: onehot_from_idx = 4'b0001;
            2'd1: onehot_from_idx = 4'b0010;
            2'd2: onehot_from_idx = 4'b0100;
            2'd3: onehot_from_idx = 4'b1000;
        endcase
    end
endfunction

function automatic logic [1:0] next_idx(input logic [1:0] idx);
    begin
        next_idx = idx + 2'd1;
    end
endfunction

// Combinational grant selection.
always_comb begin
    grant = 4'b0000;

    if (!out_q_full) begin
        unique case (alg_sel)
            ALG_SP: begin
                // Strict Priority: client 0 has highest priority, then 1, 2, 3.
                if      (valid_q[0]) grant = 4'b0001;
                else if (valid_q[1]) grant = 4'b0010;
                else if (valid_q[2]) grant = 4'b0100;
                else if (valid_q[3]) grant = 4'b1000;
            end

            ALG_RR: begin
                // Round Robin starts searching from rr_ptr.
                unique case (rr_ptr)
                    2'd0: begin
                        if      (valid_q[0]) grant = 4'b0001;
                        else if (valid_q[1]) grant = 4'b0010;
                        else if (valid_q[2]) grant = 4'b0100;
                        else if (valid_q[3]) grant = 4'b1000;
                    end
                    2'd1: begin
                        if      (valid_q[1]) grant = 4'b0010;
                        else if (valid_q[2]) grant = 4'b0100;
                        else if (valid_q[3]) grant = 4'b1000;
                        else if (valid_q[0]) grant = 4'b0001;
                    end
                    2'd2: begin
                        if      (valid_q[2]) grant = 4'b0100;
                        else if (valid_q[3]) grant = 4'b1000;
                        else if (valid_q[0]) grant = 4'b0001;
                        else if (valid_q[1]) grant = 4'b0010;
                    end
                    2'd3: begin
                        if      (valid_q[3]) grant = 4'b1000;
                        else if (valid_q[0]) grant = 4'b0001;
                        else if (valid_q[1]) grant = 4'b0010;
                        else if (valid_q[2]) grant = 4'b0100;
                    end
                endcase
            end

            ALG_WRR: begin
                // Weighted Round Robin: current client receives weight+1 grants per round.
                // Empty/disabled clients are skipped.
                if (valid_q[wrr_ptr] && (wrr_credit != 3'd0)) begin
                    grant = onehot_from_idx(wrr_ptr);
                end
                else begin
                    unique case (wrr_ptr)
                        2'd0: begin
                            if      (valid_q[1]) grant = 4'b0010;
                            else if (valid_q[2]) grant = 4'b0100;
                            else if (valid_q[3]) grant = 4'b1000;
                            else if (valid_q[0]) grant = 4'b0001;
                        end
                        2'd1: begin
                            if      (valid_q[2]) grant = 4'b0100;
                            else if (valid_q[3]) grant = 4'b1000;
                            else if (valid_q[0]) grant = 4'b0001;
                            else if (valid_q[1]) grant = 4'b0010;
                        end
                        2'd2: begin
                            if      (valid_q[3]) grant = 4'b1000;
                            else if (valid_q[0]) grant = 4'b0001;
                            else if (valid_q[1]) grant = 4'b0010;
                            else if (valid_q[2]) grant = 4'b0100;
                        end
                        2'd3: begin
                            if      (valid_q[0]) grant = 4'b0001;
                            else if (valid_q[1]) grant = 4'b0010;
                            else if (valid_q[2]) grant = 4'b0100;
                            else if (valid_q[3]) grant = 4'b1000;
                        end
                    endcase
                end
            end

            default: begin
                grant = 4'b0000;
            end
        endcase
    end
end

assign selected_valid = |grant;

always_comb begin
    selected_idx  = 2'd0;
    selected_data = '0;

    unique case (grant)
        4'b0001: begin selected_idx = 2'd0; selected_data = q0_dout; end
        4'b0010: begin selected_idx = 2'd1; selected_data = q1_dout; end
        4'b0100: begin selected_idx = 2'd2; selected_data = q2_dout; end
        4'b1000: begin selected_idx = 2'd3; selected_data = q3_dout; end
        default: begin selected_idx = 2'd0; selected_data = '0;      end
    endcase
end

wire q0_rd = grant[0];
wire q1_rd = grant[1];
wire q2_rd = grant[2];
wire q3_rd = grant[3];

wire out_q_wr = selected_valid & !out_q_full;

// Scheduler state update.
always_ff @(posedge clk_i or negedge rstn_i) begin
    if (!rstn_i) begin
        rr_ptr     <= 2'd0;
        wrr_ptr    <= 2'd0;
        wrr_credit <= weight_quota(2'd0, 8'b11_10_01_00);
    end
    else begin
        if (out_q_wr) begin
            if (alg_sel == ALG_RR) begin
                rr_ptr <= next_idx(selected_idx);
            end

            if (alg_sel == ALG_WRR) begin
                if (selected_idx != wrr_ptr) begin
                    // Moved to a new client because the previous one was empty/disabled or had no credit.
                    wrr_ptr    <= selected_idx;
                    wrr_credit <= weight_quota(selected_idx, weights_reg) - 3'd1;
                end
                else if (wrr_credit <= 3'd1) begin
                    // Current client's quota was consumed. Next cycle starts searching from the following client.
                    wrr_ptr    <= next_idx(selected_idx);
                    wrr_credit <= weight_quota(next_idx(selected_idx), weights_reg);
                end
                else begin
                    wrr_credit <= wrr_credit - 3'd1;
                end
            end
        end

        // When WRR weights are changed, reload the quota for the current WRR pointer.
        if (apb_wr && !apb_error_comb && (paddr_i[1:0] == ADDR_WEIGHTS)) begin
            wrr_credit <= weight_quota(wrr_ptr, pwdata_i);
        end
    end
end

// ---------------------------------------------------------------------------------------------------------------------
// Input FIFOs
// ---------------------------------------------------------------------------------------------------------------------
fifo #(
    .FIFO_DEPTH (4),
    .FIFO_WIDTH (DATA_WIDTH),
    .CNT_WIDTH  (3)
) queue_0 (
    .clk_i    (clk_i),
    .rst_i    (~rstn_i),
    .sw_rst_i (1'b0),
    .wr_i     (q0_wr),
    .din_i    (data0),
    .full_o   (q0_full),
    .rd_i     (q0_rd),
    .dout_o   (q0_dout),
    .empty_o  (q0_empty)
);

fifo #(
    .FIFO_DEPTH (4),
    .FIFO_WIDTH (DATA_WIDTH),
    .CNT_WIDTH  (3)
) queue_1 (
    .clk_i    (clk_i),
    .rst_i    (~rstn_i),
    .sw_rst_i (1'b0),
    .wr_i     (q1_wr),
    .din_i    (data1),
    .full_o   (q1_full),
    .rd_i     (q1_rd),
    .dout_o   (q1_dout),
    .empty_o  (q1_empty)
);

fifo #(
    .FIFO_DEPTH (4),
    .FIFO_WIDTH (DATA_WIDTH),
    .CNT_WIDTH  (3)
) queue_2 (
    .clk_i    (clk_i),
    .rst_i    (~rstn_i),
    .sw_rst_i (1'b0),
    .wr_i     (q2_wr),
    .din_i    (data2),
    .full_o   (q2_full),
    .rd_i     (q2_rd),
    .dout_o   (q2_dout),
    .empty_o  (q2_empty)
);

fifo #(
    .FIFO_DEPTH (4),
    .FIFO_WIDTH (DATA_WIDTH),
    .CNT_WIDTH  (3)
) queue_3 (
    .clk_i    (clk_i),
    .rst_i    (~rstn_i),
    .sw_rst_i (1'b0),
    .wr_i     (q3_wr),
    .din_i    (data3),
    .full_o   (q3_full),
    .rd_i     (q3_rd),
    .dout_o   (q3_dout),
    .empty_o  (q3_empty)
);

// ---------------------------------------------------------------------------------------------------------------------
// Output FIFO
// ---------------------------------------------------------------------------------------------------------------------
fifo #(
    .FIFO_DEPTH (20),
    .FIFO_WIDTH (DATA_WIDTH),
    .CNT_WIDTH  (5)
) out_q (
    .clk_i    (clk_i),
    .rst_i    (~rstn_i),
    .sw_rst_i (1'b0),
    .wr_i     (out_q_wr),
    .din_i    (selected_data),
    .full_o   (out_q_full),
    .rd_i     (out_q_rd),
    .dout_o   (out_q_dout),
    .empty_o  (out_q_empty)
);

endmodule
