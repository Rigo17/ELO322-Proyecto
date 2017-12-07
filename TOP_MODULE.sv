`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06.12.2017 18:17:13
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
    
    //output [15:0] leds,
    //input [0:0] sw,
    
    inout sda,
    inout scl
    );
    
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
    wire i2c_ack_error;
    
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
        .ack_error(i2c_ack_error)
    );
    
    wire clk_1hz;
    reg clk_1hz_prev;
    Clock_Divisor #(1) instance_clk1hz(
        .CLK100MHZ(clk_sys),
        .clk(clk_1hz)
    );
    
    //estados para recibir comando
    reg [7:0] data_wr_1, data_wr_1_nxt;
    reg [7:0] data_wr_2, data_wr_2_nxt;//seguir hasta 6 si se quiere escribir mas de 2 comandos
    reg [2:0] largo_com, largo_com_nxt;
    reg rw_1, rw_1_nxt;
    reg rw_2, rw_2_nxt;
    reg rw_3, rw_3_nxt;
    reg rw_4, rw_4_nxt;
    reg rw_5, rw_5_nxt;
    reg rw_6, rw_6_nxt;
    reg [6:0] addr=7'h00, addr_nxt;
    always_comb begin
        addr_nxt = addr;
        data_wr_1_nxt = data_wr_1;
        data_wr_2_nxt = data_wr_2;
        rw_1_nxt = rw_1;
        rw_2_nxt = rw_2;
        rw_3_nxt = rw_3;
        rw_4_nxt = rw_4;
        rw_5_nxt = rw_5;
        rw_6_nxt = rw_6;
        
        largo_com_nxt = largo_com;
        if (rx_ready)
            begin
            case(rx_data)
                8'd1://set up mpu
                    begin
                        addr_nxt = 7'h69;
                        rw_1_nxt = 1'b0;
                        rw_2_nxt = 1'b0;
                        data_wr_1_nxt = 8'h6b;
                        data_wr_2_nxt = 8'h00;
                        largo_com_nxt = 3'd2;
                    end
                8'd2://pedir 6 registros aceleracion acelerometro
                    begin
                        addr_nxt = 7'h69;
                        rw_1_nxt = 1'b0;
                        rw_2_nxt = 1'b1;
                        rw_3_nxt = 1'b1;
                        rw_4_nxt = 1'b1;
                        rw_5_nxt = 1'b1;
                        rw_6_nxt = 1'b1;
                        data_wr_1_nxt = 8'h3b;//pedir aceleraciones
                        largo_com_nxt = 3'd6;
                    end
                8'd3://pedir 6 registros giro acelerometro
                    begin
                        addr_nxt = 7'h69;
                        rw_1_nxt = 1'b0;
                        rw_2_nxt = 1'b1;
                        rw_3_nxt = 1'b1;
                        rw_4_nxt = 1'b1;
                        rw_5_nxt = 1'b1;
                        rw_6_nxt = 1'b1;
                        data_wr_1_nxt = 8'h44;//pedir giros
                        largo_com_nxt = 3'd6;                        
                    end
                8'd4://pedir 6 registros hora
                    begin
                        addr_nxt = 7'h68;
                        rw_1_nxt = 1'b0;
                        rw_2_nxt = 1'b1;
                        rw_3_nxt = 1'b1;
                        rw_4_nxt = 1'b1;
                        rw_5_nxt = 1'b1;
                        rw_6_nxt = 1'b1;
                        data_wr_1_nxt = 8'h00;//pedir seg-min-hora-dia-semana-mes
                        largo_com_nxt = 3'd6;
                    end
            endcase
            end
    end
    
    always_ff @(posedge clk_sys) begin
        addr <= addr_nxt;
        rw_1 <= rw_1_nxt;
        rw_2 <= rw_2_nxt;
        rw_3 <= rw_3_nxt;
        rw_4 <= rw_4_nxt;
        rw_5 <= rw_5_nxt;
        rw_6 <= rw_6_nxt;
        data_wr_1 <= data_wr_1_nxt;
        data_wr_2 <= data_wr_2_nxt;
        largo_com <= largo_com_nxt;
    end
    //estado para i2c
    reg i2c_busy_prev;
    reg [2:0] i2c_busy_cnt, i2c_busy_cnt_nxt;
    reg i2c_ena_start, i2c_ena_start_nxt;
    reg i2c_rw_1;
    reg i2c_rw_2;
    reg i2c_rw_3;
    reg i2c_rw_4;
    reg i2c_rw_5;
    reg i2c_rw_6;
    reg [7:0] i2c_data_wr_1;
    reg [7:0] i2c_data_wr_2;
    reg [2:0] i2c_largo_com;
    reg [6:0] i2c_addr_new;
    always_comb begin
        i2c_ena = 1'b0;
        //i2c_addr = 7'h00;
        i2c_rw = 1'b0;
        i2c_data_wr = 8'h00;
        i2c_busy_cnt_nxt = ((i2c_busy_prev == 1'b0) && (i2c_busy == 1'b1)) ? i2c_busy_cnt + 3'd1 : i2c_busy_cnt;
        i2c_ena_start_nxt = ((clk_1hz_prev == 1'b0) && (clk_1hz == 1'b1)) ? 1'b1 : (i2c_busy == 1'b1) ? 1'b0 : i2c_ena_start;
        case (i2c_busy_cnt)
            3'd0:
                begin
                    i2c_ena = i2c_ena_start;
                    //i2c_addr = i2c_addr_new;
                    i2c_rw = i2c_rw_1;
                    i2c_data_wr = i2c_data_wr_1;
                end
            3'd1:
                begin
                    if (i2c_largo_com == i2c_busy_cnt) begin
                        i2c_ena = 1'b0;
                        if (i2c_busy == 1'b0) i2c_busy_cnt_nxt = 3'd0;
                    end else begin
                        i2c_ena = 1'b1;
                        //i2c_addr = 7'h69;
                        i2c_rw = i2c_rw_2;
                        i2c_data_wr = i2c_data_wr_2;
                    end                
                end
            3'd2:
                begin
                    if (i2c_largo_com == i2c_busy_cnt) begin
                        i2c_ena = 1'b0;
                        if (i2c_busy == 1'b0) i2c_busy_cnt_nxt = 3'd0;
                    end else begin
                        i2c_ena = 1'b1;
                        //i2c_addr = 7'h69;
                        i2c_rw = i2c_rw_3;
                        i2c_data_wr = i2c_data_wr_2;
                    end                
                end
            3'd3:
                begin
                    if (i2c_largo_com == i2c_busy_cnt) begin
                        i2c_ena = 1'b0;
                        if (i2c_busy == 1'b0) i2c_busy_cnt_nxt = 3'd0;
                    end else begin                
                        i2c_ena = 1'b1;
                        //i2c_addr = 7'h69;
                        i2c_rw = i2c_rw_4;
                        i2c_data_wr = 8'h04;
                    end                
                end
            3'd4:
                begin
                    if (i2c_largo_com == i2c_busy_cnt) begin
                        i2c_ena = 1'b0;
                        if (i2c_busy == 1'b0) i2c_busy_cnt_nxt = 3'd0;
                    end else begin
                        i2c_ena = 1'b1;
                        //i2c_addr = 7'h69;
                        i2c_rw = i2c_rw_5;
                        i2c_data_wr = 8'h05;
                    end                
                end
            3'd5:
                begin
                    if (i2c_largo_com == i2c_busy_cnt) begin
                        i2c_ena = 1'b0;
                        if (i2c_busy == 1'b0) i2c_busy_cnt_nxt = 3'd0;
                    end else begin
                        i2c_ena = 1'b1;
                        //i2c_addr = 7'h69;
                        i2c_rw = i2c_rw_6;
                        i2c_data_wr = 8'h06;
                    end                
                end
            3'd6:
                begin
                    if (i2c_largo_com == i2c_busy_cnt) begin
                        i2c_ena = 1'b0;
                        if (i2c_busy == 1'b0) i2c_busy_cnt_nxt = 3'd0;
                    end else begin
                        i2c_ena = 1'b1;
                        //i2c_addr = 7'h69;
                        i2c_rw = 1'b1;
                        i2c_data_wr = 8'h07;
                    end
                end
            3'd7:
                begin
                i2c_ena = 1'b0;
                if (i2c_busy == 1'b0) i2c_busy_cnt_nxt = 3'd0;
                end
        endcase   
            
    end
    
    always_ff @(posedge clk_sys) begin
        i2c_busy_cnt <= i2c_busy_cnt_nxt;
        i2c_ena_start <= i2c_ena_start_nxt;
        i2c_busy_prev <= i2c_busy;
        
        clk_1hz_prev <= clk_1hz;
        
        if (i2c_busy_cnt == 3'd0) begin
            i2c_data_wr_1 <= data_wr_1;
            i2c_data_wr_2 <= data_wr_2;
            i2c_rw_1 = rw_1;
            i2c_rw_2 = rw_2;
            i2c_rw_3 = rw_3;
            i2c_rw_4 = rw_4;
            i2c_rw_5 = rw_5;
            i2c_rw_6 = rw_6;
            i2c_largo_com <= largo_com;
            i2c_addr <= addr;
        end
    end
    
    
endmodule
