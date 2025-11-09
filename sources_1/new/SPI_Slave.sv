`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/07 13:17:01
// Design Name: 
// Module Name: SPI_Slave
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module SPI_Slave(
    input logic clk,
    input logic rst,
    input logic ss_n,
    input logic MOSI,
    output logic MISO
    );

    typedef enum {
        IDLE,
        CPO,
        CP1
    } state_t;

endmodule
