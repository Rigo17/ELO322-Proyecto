`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07.10.2017 12:15:41
// Design Name: 
// Module Name: Clock_Divisor
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


module Clock_Divisor #(parameter frecuencia = 1)
(
    input CLK100MHZ,
    output reg clk
);

    reg [26:0] cnt=27'd0, cnt_next;
    wire [26:0] max_cnt;
    assign max_cnt = (27'd100_000_000) /(frecuencia * 2);
    
    always_ff @(posedge CLK100MHZ)begin
        if(cnt == max_cnt) clk <= ~clk;
        if(cnt == max_cnt) cnt <= 26'd1;
        else cnt <= cnt + 26'd1;
    end
endmodule
