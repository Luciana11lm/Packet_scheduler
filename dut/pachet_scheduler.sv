// ---------------------------------------------------------------------------------------------------------------------
// Module name: pachet_scheduler
// HDL        : SystemVerilog
// Author     : Boziesan Stefan
// Description: Pachet Scheduler top module
// Date       : 07.04.2026
// ---------------------------------------------------------------------------------------------------------------------
module pachet_scheduler #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 2 //TODO: hardcode, this parameter should not be modified so it shouldn't be a parameter 
)(
    input clk_i,
    input rstn_i,
    // APB intf
    input                   psel_i,
    input                   penable_i,
    input                   pwrite_i,
    input  [ADDR_WIDTH-1:0] paddr_i,
    input  [DATA_WIDTH-1:0] pwdata_i,
    output [DATA_WIDTH-1:0] prdata_o,
    output                  pready_o,     //TODO: le ai facut in always deci trb sa le faci reg/logic 
    output                  pslverr_o,    //TODO: fa always_ff 
    // REQ-ACK intf
    input                   req0 ,
    output                  ack0 ,
    output [DATA_WIDTH-1:0] data0, 
    
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

//Internal signals


//-------------------------------------------------------------------------------------------------------------
//APB
//-------------------------------------------------------------------------------------------------------------


//-------------------------------------------------------------------------------------------------------------
//regs_wr_idx
//-------------------------------------------------------------------------------------------------------------
logic [3:0] regs_wr_idx;
always@(posedge clk_i or negedge rstn_i)
  if(~rstn_i) regs_wr_idx <= 4'b00_00;
  else
    if(psel_i & ~penable_i & pwrite_i)
        case(paddr_i)
            0 : regs_wr_idx <= 4'b00_01;  //TODO: fifo access, !!should not be able to write the fifo 
            1 : regs_wr_idx <= 4'b00_10;  //TODO: !! status e read only 
            2 : regs_wr_idx <= 4'b01_00;
            3 : regs_wr_idx <= 4'b10_00;
            default : regs_wr_idx <= 4'b00_00;
        endcase
    else regs_wr_idx <= 4'b00_00;
      

//-------------------------------------------------------------------------------------------------------------
//status_reg
//-------------------------------------------------------------------------------------------------------------
//status: Read-only 
logic q0_full, q1_full, q2_full, q3_full, qo_full, qo_mty;
logic [DATA_WIDTH-1:0] status_reg;

//-------------------------------------------------------------------------------------------------------------
//cfg_reg
//-------------------------------------------------------------------------------------------------------------
//logic [1:0] alg_sel;
//logic [3:0] client_en;
logic [DATA_WIDTH-1:0] cfg_reg; 

always@(posedge clk_i or negedge rstn_i)
if(~rstn_i)        cfg_reg <= 8'b0000_1111; else    
if(regs_wr_idx[2]) cfg_reg <= {2'b00, pwdata_i[5:0]};


//-------------------------------------------------------------------------------------------------------------
//weights_reg
//-------------------------------------------------------------------------------------------------------------     
//each client can have 4 weights [3:0] 
// TODO: what to do with 00 value 
//logic [1:0] w0, w1, w2, w3;
logic [DATA_WIDTH-1:0] weights_reg;

always@(posedge clk_i or negedge rstn_i)
if(~rstn_i)        weights_reg <= 8'b11_10_01_00; else    
if(regs_wr_idx[3]) weights_reg <= pwdata_i;       //TODO: implement unique weights 

//-------------------------------------------------------------------------------------------------------------
//pready_o
//-------------------------------------------------------------------------------------------------------------
always@(posedge clk_i or negedge rstn_i)
if(~rstn_i)             pready_o <= 1'b0; else
if(psel_i & ~penable_i) pready_o <= 1'b1; else
if(psel_i &  penable_i) pready_o <= 1'b0; else 
                        pready_o <= pready_o;
    
//-------------------------------------------------------------------------------------------------------------
//prdata
//-------------------------------------------------------------------------------------------------------------
always@(posedge clk_i or negedge rstn_i)
    if(~rstn_i) prdata_o <= 8'b0;
    else
        if(psel_i & ~penable_i & ~pwrite_i)
            case(paddr_i)
                0 : prdata_o <= out_q_dout;
                1 : prdata_o <= {q0_full, q1_full, q2_full, q3_full, out_q_full, out_q_mty, 2'b00};//status_reg;
                2 : prdata_o <= cfg_reg;            
                3 : prdata_o <= weights_reg;
                //TODO:
                //4 : prdata_o <= {2'b00, rx_ovfl, tx_udfl, rx_fifo_empty, rx_fifo_full, tx_fifo_empty_o, tx_fifo_full};
                //dupa modelul asta poti face: campuri sa para ca ai registrii si doar ii concatenezi cand ii dai afara
                default : prdata_o <= 8'b0;
            endcase
        else prdata_o <= 8'b0;



    
//-------------------------------------------------------------------------------------------------------------
//pslverr
//-------------------------------------------------------------------------------------------------------------
/*TODO
-(1)pslverr = q0_full | q1_full | q2_full | q3_full | out_q_full |  
-(2)alg sel == 10 
-(3)non unique weights
-(4)write la weights_reg daca nu e setat alg pe WRR 
-(5)write la adr 0 output queue
-(6)scriere la status(addr 1) 
 */
// -------------------------------------------------------------------------------------------------------------
// pslverr
// -------------------------------------------------------------------------------------------------------------
always@(posedge clk_i or negedge rstn_i)
    if(~rstn_i) pslverr_o <= 1'b0;
    else
        if(psel_i & ~penable_i)
            // cazurile de wr
            if(pwrite_i)
                case(paddr_i)
                    0 :                                  pslverr_o <= 1'b1;  //(5) 
                    1 : if(~sw_rst_o)                    pslverr_o <= 1'b1;
                    2 : if(sw_rst_o | tx_fifo_full)      pslverr_o <= 1'b1;
                    3 :                                  pslverr_o <= 1'b1;
                endcase
            // cazurile de rd
            else
                case(paddr_i)
                    2 :                                  pslverr_o <= 1'b1;
                    3 : if(sw_rst_o | rx_fifo_empty)     pslverr_o <= 1'b1;
                    6 :                                  pslverr_o <= 1'b1;
                    7 :                                  pslverr_o <= 1'b1;
                    default :                            pslverr_o <= 1'b0;
                endcase
        else pslverr_o = 0;



//-------------------------------------------------------------------------------------------------------------
//regs_wr_idx
//-------------------------------------------------------------------------------------------------------------
fifo #(
    .FIFO_DEPTH (4          ),  
    .FIFO_WIDTH (DATA_WIDTH ),  
    .CNT_WIDTH  (3          )   
)queue_0(
    .clk_i    (clk_i  ), 
    .rst_i    (~rstn_i), 
    .sw_rst_i (1'b0   ), 
    .wr_i     (                ), // Write operation
    .din_i    (                ), // Data in
    .full_o   (q0_full         ), 
    //                 
    .rd_i     (                ), // Read operation
    .dout_o   (                ), // Data out
    .empty_o  (                )  // Empty flag
);

fifo #(
    .FIFO_DEPTH (4          ),  
    .FIFO_WIDTH (DATA_WIDTH ),  
    .CNT_WIDTH  (3          )   
)queue_1(
    .clk_i    (clk_i  ),
    .rst_i    (~rstn_i),
    .sw_rst_i (1'b0   ),
    .wr_i     (                ), // Write operation
    .din_i    (                ), // Data in
    .full_o   (q1_full         ),
    //                 
    .rd_i     (                ), // Read operation
    .dout_o   (                ), // Data out
    .empty_o  (                )  // Empty flag
);

//-------------------------------------------------------------------------------------------------------------
//Queue2 FIFO
//-------------------------------------------------------------------------------------------------------------


fifo #(
    .FIFO_DEPTH (4          ), 
    .FIFO_WIDTH (DATA_WIDTH ), 
    .CNT_WIDTH  (3          )  
)queue_2(
    .clk_i    (clk_i  ), 
    .rst_i    (~rstn_i), 
    .sw_rst_i (1'b0   ), 
    .wr_i     (                ), // Write operation
    .din_i    (                ), // Data in
    .full_o   (q2_full         ), 
    //                 
    .rd_i     (                ), // Read operation
    .dout_o   (                ), // Data out
    .empty_o  (                )  // Empty flag
);

//-------------------------------------------------------------------------------------------------------------
//Queue3 FIFO
//-------------------------------------------------------------------------------------------------------------


fifo #(
    .FIFO_DEPTH (4          ),  
    .FIFO_WIDTH (DATA_WIDTH ),  
    .CNT_WIDTH  (3          )   
)queue_3(
    .clk_i    (clk_i  ), 
    .rst_i    (~rstn_i), 
    .sw_rst_i (1'b0   ), 
    .wr_i     (               ), // Write operation
    .din_i    (               ), // Data in
    .full_o   (q3_full        ), 
    //                
    .rd_i     (               ), // Read operation
    .dout_o   (               ), // Data out
    .empty_o  (               )  // Empty flag
);

//-------------------------------------------------------------------------------------------------------------
//Output FIFO
//-------------------------------------------------------------------------------------------------------------
wire                    out_q_rd;
logic [DATA_WIDTH-1:0]  out_q_dout;

fifo #(
    .FIFO_DEPTH (20         ), 
    .FIFO_WIDTH (DATA_WIDTH ), 
    .CNT_WIDTH  (5          )  
)out_q(
    .clk_i    (clk_i  ), 
    .rst_i    (~rstn_i), 
    .sw_rst_i (1'b0   ), 
    .wr_i     (               ), // Write operation
    .din_i    (               ), // Data in
    .full_o   (out_q_full     ), 
    .rd_i     (out_q_rd       ), 
    .dout_o   (out_q_dout     ), 
    .empty_o  (out_q_mty      )  
);

assign out_q_rd = (psel_i & ~penable_i & ~pwrite_i & (paddr_i == 0));

//-------------------------------------------------------------------------------------------------------------
//REQ-ACK
//-------------------------------------------------------------------------------------------------------------
 
//         //client enable & q not full & ack de la prot handler 
assign ack0 = cfg_reg[0] & (~status_reg[7]) & hndl_ack0;
// sau direct iesirea de fifo full, ca status_reg[7] e defapt queue_0.full_o
//... analog celelalte 3 

//TODO: req-ack handle, sau direct logica in top
// TODO: conect semnalele de la fifo uri 
// TODO: planificare 

//!q0_full ==1 => nack0 = 1( daca q e full, nu dai ack pe canalul respectiv 
endmodule