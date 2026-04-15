`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/07/2026 12:21:18 PM
// Design Name: 
// Module Name: multiplier_8b_tb
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


module multiplier_8b_tb(

    );
    
    
    reg [7:0] a, b;
    wire [15:0] out;
    
    multiplier_8b mult (a,b,out);
    
    
    initial begin
        a = 8'hFF;
        b = 8'hFF;
        #100
        a = 8'h00;
        #100
        a = 8'h80;
        b = 8'hFF;
        #100;
    end
    
    
endmodule
