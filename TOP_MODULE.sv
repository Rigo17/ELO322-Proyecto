`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04.12.2017 20:46:55
// Design Name: 
// Module Name: TOP_MODULE
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


module TOP_MODULE(
    input clk_sys,
    input cpu_resetn,
    
    input uart_rx,
    //output uart_tx,
    
    output [15:0] leds,
    input [0:0] sw,
    
    inout sda,
    inout scl   
    );
        
     
    //Defincion cables
    //Variables UART
    
    wire [7:0] rx_data;
    wire rx_ready;
    //reg [7:0] tx_data;
    //reg tx_start;
    //wire tx_busy;    
    
    
    //Instanciacion_modulos
    UART_RX_MASTER instance_uart_rx (
        .clk(clk_sys),
        .reset(~cpu_resetn),
        .rx(uart_rx),
        .rx_data(rx_data),
        .rx_ready(rx_ready)
    );
    /*
    UART_TX_MASTER instance_uart_tx (
        .clk(clk_sys),
        .reset(~cpu_resetn),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .tx(uart_tx),
        .tx_busy(tx_busy)
    );
    */
    
    reg i2c_ena;
    reg [6:0] i2c_addr;
    reg i2c_rw;
    reg [7:0] i2c_data_wr;
    wire i2c_busy;
    wire [7:0] i2c_data_rd;
    
    i2c_master instance_i2c_master (
        .clk(clk_sys),
        .reset_n(cpu_resetn),
        .ena(i2c_ena), //in 1
        .addr(i2c_addr),//in 7 MPU=0x69
        .rw(i2c_rw), //in 1
        .data_wr(i2c_data_wr), // in 8
        .busy(i2c_busy), //out 1
        .data_rd(i2c_data_rd), //out 8
        .sda(sda),
        .scl(scl),
        .ack_error()
    );
    
    reg i2c_busy_prev;
    reg [2:0] i2c_busy_cnt, i2c_busy_cnt_nxt; //max 7
    reg [47:0] i2c_data_rd_last, i2c_data_rd_last_nxt; //almacena 6 datos
    reg i2c_ena_start, i2c_ena_start_nxt;
    reg i2c_mpu_setup, i2c_mpu_setup2, i2c_mpu_setup_nxt;
    always_comb begin
        i2c_ena = 1'b0;
        i2c_addr = 7'h00;
        i2c_rw = 1'b0;
        i2c_data_wr = 8'haa;
        i2c_busy_cnt_nxt = i2c_busy_cnt;
        i2c_data_rd_last_nxt = i2c_data_rd_last;
        i2c_ena_start_nxt = (rx_ready==1'b1) ? 1'b1 : (i2c_busy==1'b1) ? 1'b0 : i2c_ena_start;
        i2c_mpu_setup_nxt = i2c_mpu_setup;
        
        if ((i2c_busy_prev == 1'b0) && (i2c_busy == 1'b1)) i2c_busy_cnt_nxt = i2c_busy_cnt + 3'd1;
        case(i2c_busy_cnt)
            3'd0: 
                begin
                    if(i2c_mpu_setup) begin
                        i2c_ena = sw;
                        i2c_addr = 7'h69;
                        i2c_rw = 1'b0;
                        i2c_data_wr = 8'h6b;
                    end else begin
                        i2c_ena = i2c_ena_start;
                        i2c_addr = 7'h69;
                        i2c_rw = 1'b0;
                        i2c_data_wr = 8'h3b;
                    end
                end
            3'd1://pido dato 1
                begin
                    if(i2c_mpu_setup) begin
                        i2c_ena = 1'b1;
                        i2c_addr = 7'h69;
                        i2c_rw = 1'b0;
                        i2c_data_wr = 8'h00;
                    end else begin
                        i2c_ena = 1'b1;
                        i2c_addr = 7'h69;
                        i2c_rw = 1'b1;
                    end                                        
                end
            3'd2://pido dato 2
                begin
                    if(i2c_mpu_setup) begin
                        i2c_ena = 1'b0;
                        if (i2c_busy == 1'b0) begin
                            i2c_busy_cnt_nxt = 3'd0;
                            i2c_mpu_setup_nxt = 1'b0;
                        end
                    end else begin
                        i2c_data_rd_last_nxt = {i2c_data_rd_last[47:8], i2c_data_rd};
                        i2c_ena = 1'b1;
                        i2c_addr = 7'h69;
                        i2c_rw = 1'b1;
                    end
                end
            3'd3://pido dato 3
                begin
                    i2c_data_rd_last_nxt = {i2c_data_rd_last[47:16],i2c_data_rd , i2c_data_rd_last[7:0]};
                    i2c_ena = 1'b1;
                    i2c_addr = 7'h69;
                    i2c_rw = 1'b1;
                end
            3'd4://pido dato 4
                begin
                    i2c_data_rd_last_nxt = {i2c_data_rd_last[47:24],i2c_data_rd , i2c_data_rd_last[15:0]};
                    i2c_ena = 1'b1;
                    i2c_addr = 7'h69;
                    i2c_rw = 1'b1;
                end
            3'd5://pido dato 5
                begin
                    i2c_data_rd_last_nxt = {i2c_data_rd_last[47:32],i2c_data_rd , i2c_data_rd_last[23:0]};
                    i2c_ena = 1'b1;
                    i2c_addr = 7'h69;
                    i2c_rw = 1'b1;
                end
            3'd6://pido dato 6
                begin
                    i2c_data_rd_last_nxt = {i2c_data_rd_last[47:40],i2c_data_rd , i2c_data_rd_last[31:0]};
                    i2c_ena = 1'b1;
                    i2c_addr = 7'h69;
                    i2c_rw = 1'b1;
                end            
            3'd7://termino la comunicacion
                begin
                    i2c_data_rd_last_nxt = {i2c_data_rd , i2c_data_rd_last[39:0]};
                    i2c_ena = 1'b0;
                    if (i2c_busy == 1'b0 ) i2c_busy_cnt_nxt = 3'd0;
                end
        endcase
    end
    
    always_ff @ (posedge clk_sys) begin
        if(~cpu_resetn) begin
            i2c_busy_cnt <= 3'd0;
            i2c_mpu_setup <= 1'd1;
        end else begin 
            i2c_busy_cnt  <= i2c_busy_cnt_nxt;
            i2c_mpu_setup <= i2c_mpu_setup_nxt;
        end
        i2c_data_rd_last <= i2c_data_rd_last_nxt;
        i2c_ena_start <= i2c_ena_start_nxt;
        i2c_busy_prev <= i2c_busy;
        i2c_mpu_setup2 <= i2c_mpu_setup;
    end
    
    assign leds = i2c_data_rd_last;
endmodule
