// ---------------------------------------------------------------------------------------------------------------------
// Module name: pachet_scheduler
// HDL        : SystemVerilog
// Author     : Boziesan Stefan
// Description: Pachet Scheduler top module
// Date       : 07.04.2026
// ---------------------------------------------------------------------------------------------------------------------
module pachet_scheduler #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 2  //for apb address
    
// TODO: add overhead? for req-ack data: [DATA_WIDTH + OVERHEAD : 0] data 
// si DATA_WIDTH ramane pt intern si apb     
)(
    input clk_i,
    input rst_i,
    // APB intf
    input                   psel_i,
    input                   penable_i,
    input                   pwrite_i,
    input  [ADDR_WIDTH-1:0] paddr_i,
    input  [DATA_WIDTH-1:0] pwdata_i,
    output [DATA_WIDTH-1:0] prdata_o,
    output                  pready_o,
    output                  pslverr_o,
    // REQ-ACK intf
    input                   req0 ,
    output                  ack0 ,
    output [DATA_WIDTH-1:0] data0,  //TODO: only write? 
    
    input                   req1 ,
    output                  ack1 ,
    output [DATA_WIDTH-1:0] data1,
    
    input                   req2 ,
    output                  ack2 ,
    output [DATA_WIDTH-1:0] data2,
    
    input                   req3 ,
    output                  ack3 ,
    output [DATA_WIDTH-1:0] data3,
);

//signals


//REGS:
//status: Read-only 
//q0_full, q1_full, q2_full, q3_full, qo_full, qo_mty, res1, res0
//!q0_full ==1 => nack0 = 1( daca q e full, nu dai ack pe canalul respectiv 
//!qo_full ==1 => pslverr_o = 1; TODO: vezi ce alte cazuri de pslverr poti sa mai dai 
// TODO: eventual orice 1 din reg de status rezulta pslverr
logic [DATA_WIDTH-1:0] status_reg;
logic q0_full, q1_full, q2_full, q3_full, qo_full, qo_mty;

//config: Read-Write
//res7, res6, [1:0] alg_sel, [3:0] client_en
logic [DATA_WIDTH-1:0] cfg_reg; 
logic [1:0] alg_sel;
logic [3:0] client_en;      

//weights: Read-Write
//each client can have 4 weights [3:0] 
// TODO: what to do with 00 value 
logic [DATA_WIDTH-1:0] weights_reg;
logic [1:0] w0, w1, w2, w3;

fifo #(
    .FIFO_DEPTH (4          ),  // No of fifo lines "N"
    .FIFO_WIDTH (DATA_WIDTH ),  // No of fifo bits "M"
    .CNT_WIDTH  (3          )   // Fifo counter
)queue_0(
    .clk_i    (clk_i), // Clock
    .rst_i    (rst_i), // Asynchronous Hw Reset active high
    .sw_rst_i (1'b0 ), // Synchronous Sw Reset active high
    //
    .wr_i     (), // Write operation
    .din_i    (), // Data in
    .full_o   (), // Full flag
    //
    .rd_i     (), // Read operation
    .dout_o   (), // Data out
    .empty_o  ()  // Empty flag
);

fifo #(
    .FIFO_DEPTH (4          ),  // No of fifo lines "N"
    .FIFO_WIDTH (DATA_WIDTH ),  // No of fifo bits "M"
    .CNT_WIDTH  (3          )   // Fifo counter
)queue_1(
    .clk_i    (clk_i), // Clock
    .rst_i    (rst_i), // Asynchronous Hw Reset active high
    .sw_rst_i (1'b0 ), // Synchronous Sw Reset active high
    //
    .wr_i     (), // Write operation
    .din_i    (), // Data in
    .full_o   (), // Full flag
    //
    .rd_i     (), // Read operation
    .dout_o   (), // Data out
    .empty_o  ()  // Empty flag
);

fifo #(
    .FIFO_DEPTH (4          ),  // No of fifo lines "N"
    .FIFO_WIDTH (DATA_WIDTH ),  // No of fifo bits "M"
    .CNT_WIDTH  (3          )   // Fifo counter
)queue_2(
    .clk_i    (clk_i), // Clock
    .rst_i    (rst_i), // Asynchronous Hw Reset active high
    .sw_rst_i (1'b0 ), // Synchronous Sw Reset active high
    //
    .wr_i     (), // Write operation
    .din_i    (), // Data in
    .full_o   (), // Full flag
    //
    .rd_i     (), // Read operation
    .dout_o   (), // Data out
    .empty_o  ()  // Empty flag
);

fifo #(
    .FIFO_DEPTH (4          ),  // No of fifo lines "N"
    .FIFO_WIDTH (DATA_WIDTH ),  // No of fifo bits "M"
    .CNT_WIDTH  (3          )   // Fifo counter
)queue_3(
    .clk_i    (clk_i), // Clock
    .rst_i    (rst_i), // Asynchronous Hw Reset active high
    .sw_rst_i (1'b0 ), // Synchronous Sw Reset active high
    //
    .wr_i     (), // Write operation
    .din_i    (), // Data in
    .full_o   (), // Full flag
    //
    .rd_i     (), // Read operation
    .dout_o   (), // Data out
    .empty_o  ()  // Empty flag
);

fifo #(
    .FIFO_DEPTH (20         ),  // No of fifo lines "N"
    .FIFO_WIDTH (DATA_WIDTH ),  // No of fifo bits "M"
    .CNT_WIDTH  (5          )   // Fifo counter
)out_q(
    .clk_i    (clk_i), // Clock
    .rst_i    (rst_i), // Asynchronous Hw Reset active high
    .sw_rst_i (1'b0 ), // Synchronous Sw Reset active high
    //
    .wr_i     (), // Write operation
    .din_i    (), // Data in
    .full_o   (), // Full flag
    //
    .rd_i     (), // Read operation
    .dout_o   (), // Data out
    .empty_o  ()  // Empty flag
);

 
//         //client enable & q not full & ack de la prot handler 
assign ack0 = cfg_reg[0] & (~status_reg[7]) & hndl_ack0;
// sau direct iesirea de fifo full, ca status_reg[7] e defapt queue_0.full_o
//... analog celelalte 3 

//TODO: req-ack handle, sau direct logica in top
// TODO: conect semnalele de la fifo uri 
// TODO: planificare 
endmodule