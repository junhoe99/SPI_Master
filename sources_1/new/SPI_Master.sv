`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/07 13:14:01
// Design Name: 
// Module Name: SPI_Master
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


module SPI_Master (
    // Global Signals
    input logic clk,
    input logic reset,
    // Internal Signals
    input logic start,
    input logic [7:0] tx_data,
    output logic [7:0] rx_data,
    output logic tx_ready,
    output logic done,
    // External SPI Signals
    output logic SCLK,
    output logic MOSI,
    input logic MISO
    // Slave Select은 일반적으로 GPIO 핀으로 제어되고, 상위 wrapper 모듈에서 관리.
);


    // 현재 설계에서는, SCLK의 반주기를 CPO(SCLK=0), 나머지 반 주기를 CP1(SCLK=1)로 정의하고,
    // 각 State에서 MOSI, MISO 신호를 처리하는 방식으로 구현.
    typedef enum {
        IDLE,
        CP0,
        CP1
    } state_t;

    state_t c_state, n_state;

    logic [7:0] tx_data_reg, tx_data_next;          // To prevent Latch
    logic [7:0] rx_data_reg, rx_data_next;          // To prevent Latch

    logic [5:0] sclk_count_reg, sclk_count_next;    // To prevent Latch
    logic [2:0] bit_count_reg, bit_count_next;        // To prevent Latch


    // State Register
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            c_state <= IDLE;
            tx_data_reg <= 8'b0;
            rx_data_reg <= 8'b0;
            sclk_count_reg <= 6'b0;
            bit_count_reg <= 3'b0;
        end else begin
            c_state <= n_state;
            tx_data_reg <= tx_data_next;
            rx_data_reg <= rx_data_next;
            sclk_count_reg <= sclk_count_next;
            bit_count_reg <= bit_count_next;
        end
    end


    // Next State Logic(Combinational) + Output Logic(Combinational)
    always_comb begin
        n_state = c_state;  // 기본값 설정
        tx_data_next = tx_data_reg;  // 기본값 설정
        rx_data_next = rx_data_reg;  // 기본값 설정
        sclk_count_next = sclk_count_reg;  // 기본값 설정
        bit_count_next = bit_count_reg;  // 기본값 설정
        tx_ready = 1'b0;  // 기본값 설정
        done = 1'b0;  // 기본값 설정
        SCLK = 1'b0;  // CPOL = 0기준, 기본값 설정
        case (c_state)
            IDLE: begin
                    done = 1'b0;          // Output Port 신호이므로, register화 하지 않아도 됨.
                    tx_ready = 1'b1;      // Output Port 신호이므로, register화 하지 않아도 됨.
                    sclk_count_next = 0;
                    bit_count_next = 0;
                if (start) begin
                    n_state = CP0;
                    tx_data_next = tx_data;  //TX data latching
                end else begin
                    n_state = IDLE;
                end
            end
            CP0: begin
                SCLK = 0; // Output Port 신호이므로, register화 하지 않아도 됨.
                if (sclk_count_reg == 49) begin    // Rising Edge
                    rx_data_next = {rx_data[6:0], MISO};  // MSB first 수신
                    sclk_count_next = 0;
                    n_state = CP1;
                end else begin
                    sclk_count_next = sclk_count_reg + 1;
                    n_state = CP0;
                end
            end
            CP1: begin
                SCLK = 1; // Output Port 신호이므로, register화 하지 않아도 됨.
                if (sclk_count_reg == 49) begin
                    sclk_count_next = 0;
                    if (bit_count_reg == 7) begin   // Falling Edge
                        bit_count_next = 0;
                        done = 1;
                        n_state = IDLE;
                    end else begin
                        bit_count_next = bit_count_reg + 1;
                        tx_data_next = {tx_data_reg[6:0], 1'b0};  // MSB first 전송
                        n_state = CP0;
                    end
                end else begin
                    sclk_count_next = sclk_count_reg + 1;
                    n_state = CP1;
                end
            end
        endcase
    end

    // 왜, tx_data, bit_count, sclk_count같은 신호들을 레지스터화 했는가?
    // => Latch 방지 목적.
    // => Combinational logic에서 신호의 다음 상태를 결정할 때,
    //    해당 신호들이 레지스터화 되어 있지 않으면, 신호의 이전 상태를 유지하기 위해 Latch가 생성될 수 있음.
    //    이는 예상치 못한 동작을 초래할 수 있음.
    // 하지만 만약 해당 신호가 Module의 output 포트라면, 레지스터화 하지 않아도 됨.
    // => Module의 output 포트는 기본적으로 Combinational logic에서 값을 할당받기 때문에,
    //    Latch가 생성될 위험이 없음. 
    //
    // 즉, 모듈의 internal signal들이 combinational logic속에서 그 값이 바뀌게 된다면
    // 해당 signal들은 레지스터화 해야함. (LATCH 방지 목적)
    // 반면에, 모듈의 output 포트들은 레지스터화 하지 않아도 됨.

    assign MOSI = tx_data_reg[7];  // MSB first 전송
    assign rx_data = rx_data_reg;  // 최종 수신 데이터
endmodule
