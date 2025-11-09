`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/07 14:15:12
// Design Name: 
// Module Name: tb_Master
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


module tb_Master ();

    // Signals
    logic clk;
    logic reset;
    logic start;
    logic [7:0] tx_data;
    logic [7:0] rx_data;
    logic tx_ready;
    logic done;
    logic SCLK;
    logic MOSI;
    logic MISO;


    // Loopback Test
    SPI_Master dut(
        .*,
        .MISO(MOSI)  // Loopback
    );

    // Clock Generation
    always #5 clk = ~clk;  // sys_clk : 100MHz Clock



    //SPI_Master dut (
    //    .clk(clk),
    //    .reset(reset),
    //    .start(start),
    //    .tx_data(tx_data),
    //    .rx_data(rx_data),
    //    .tx_ready(tx_ready),
    //    .done(done),
    //    .SCLK(SCLK),
    //    .MOSI(MOSI),
    //    .MISO(MISO)
    //);


    initial begin
        clk   = 0;
        reset = 1;
        #10;
        reset = 0;
    end

    initial begin
        repeat (5) @(negedge clk);
        MOSI_sender(8'h3C);  // Master가 Slave로 보낼 데이터
        MOSI_sender(8'hA5);  // Slave가 Master로 보낼 데이터
        MOSI_sender(8'h5A);  // Slave가 Master로 보낼 데이터

        #100; $finish;
    end


    task MOSI_sender(input logic [7:0] data);
        begin
            @(posedge clk);
            wait (tx_ready);
            start   = 1'b1;
            tx_data = data;  // Example data to send
            @(posedge clk);
            start = 1'b0;
            wait (done);
            @(posedge clk);
        end
    endtask

    task MISO_sender(input logic [7:0] data);
        integer i;
        begin
            for (i = 7; i >= 0; i = i - 1) begin  // MSB first
                @(negedge SCLK);
                MISO = data[i];
            end
        end
    endtask

endmodule
