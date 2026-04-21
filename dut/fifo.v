module fifo #(
    parameter FIFO_DEPTH = 10,  // No of fifo lines "N"
    parameter FIFO_WIDTH = 8,   // No of fifo bits "M"
    parameter CNT_WIDTH = 4     // Fifo counter
)(
//Ports List -------------------------------------------------------------------
    //
    input            clk_i        , // Clock
    input            rst_i        , // Asynchronous Hw Reset active high
    input            sw_rst_i     , // Synchronous Sw Reset active high

    //
    input                       wr_i   , // Write operation
    input    [FIFO_WIDTH-1:0]   din_i  , // Data in
    output reg                  full_o , // Full flag

    //
    input                       rd_i    , // Read operation
    output   [FIFO_WIDTH-1:0]   dout_o  , // Data out
    output reg                  empty_o   // Empty flag

);

// Internal Signals ----------------------------------------------------------------------------------------------------


    // Write counter signals
    reg [CNT_WIDTH-1:0] wr_cnt;                  // Write counter
    wire [CNT_WIDTH-1:0] wr_nxt;                 // Next value of write counter
    wire [CNT_WIDTH-1:0] wr_nxt_0;               // Next value of write counter
    wire [CNT_WIDTH-1:0] nxt_wr_cnt_value;       // Increment or put to "0" write counter

    // Read counter signals
    reg [CNT_WIDTH-1:0] rd_cnt;                  // Read counter
    wire [CNT_WIDTH-1:0] rd_nxt;                 // Next value of read counter
    wire [CNT_WIDTH-1:0] rd_nxt_0;               // Next value of read counter
    wire [CNT_WIDTH-1:0] nxt_rd_cnt_value;       // Increment or put to "0" read counter

    reg [FIFO_WIDTH-1:0] mem [FIFO_DEPTH-1:0];  // FIFO memory with parametrized width and depth

// Code ----------------------------------------------------------------------------------------------------------------

    // Write counter ---------------------------------------------------------------------------------------------------
    assign wr_nxt = (sw_rst_i) ? (0) : (wr_nxt_0);
    assign wr_nxt_0 = (wr_i && ~full_o) ? (nxt_wr_cnt_value) : (wr_cnt);
    assign nxt_wr_cnt_value = (wr_cnt < (FIFO_DEPTH - 1)) ? (wr_cnt + 1) : (0);

    //
    always@(posedge clk_i or posedge rst_i)
        if(rst_i) wr_cnt <= 0;
        else wr_cnt <= wr_nxt;


    // Full flag--------------------------------------------------------------------------------------------------------
    always@(posedge clk_i or posedge rst_i)
        if(rst_i) full_o <= 0;
        else
            if(sw_rst_i) full_o <= 0;
            else
                if(wr_i && ~rd_i && (wr_nxt == rd_cnt)) full_o <= 1;
                else
                    if(rd_i) full_o <=0;
                    else full_o <= full_o;


    // Read counter ---------------------------------------------------------------------------------------------------
    assign rd_nxt = (sw_rst_i) ? (0) : (rd_nxt_0);
    assign rd_nxt_0 = (rd_i && ~empty_o) ? (nxt_rd_cnt_value) : (rd_cnt);
    assign nxt_rd_cnt_value = (rd_cnt < (FIFO_DEPTH - 1)) ? (rd_cnt + 1) : (0);

    //
    always@(posedge clk_i or posedge rst_i)
        if(rst_i) rd_cnt <= 0;
        else rd_cnt <= rd_nxt;


    // Empty flag--------------------------------------------------------------------------------------------------------
    always@(posedge clk_i or posedge rst_i)
        if(rst_i) empty_o <= 1;
        else
            if(sw_rst_i) empty_o <= 1;
            else
                if(~wr_i && rd_i && (rd_nxt == wr_cnt)) empty_o <= 1;
                else
                    if(wr_i) empty_o <=0;
                    else empty_o <= empty_o;


    // Memory----------------------------------------------------------------------------------------------------------
    // Write in memory
    always@(posedge clk_i)
        if(wr_i && ~full_o)  mem[wr_cnt] <= din_i;

    // Read from memory
    assign dout_o = mem[rd_cnt];


endmodule