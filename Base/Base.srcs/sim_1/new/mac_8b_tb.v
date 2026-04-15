`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/12/2026 07:19:13 PM
// Design Name: 
// Module Name: mac_8b_tb
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


module mac_8b_tb(

    );
    
    reg [7:0] a, b, c;
    wire [7:0] out;
    
    mac_8b mac1 (a,b,c,out);
    
    
    initial begin
        a = 8'h01;
        b = 8'h01;
        c = 8'h01;
        #100
        a = 8'h00;
        #100
        a = 8'h80;
        b = 8'hFF;
        #100;
        a = 8'h00;
        b = 8'h00;
        c = 8'h00;
        #100;
        a = 8'h01;
        b = 8'h80;
        c = 8'hE0;
        #100;
    end
    
endmodule
