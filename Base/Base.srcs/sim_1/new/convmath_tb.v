`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/16/2026 11:29:53 AM
// Design Name: 
// Module Name: convmath_tb
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


module convmath_tb(

    );
    
    reg reset, compute;
    reg [31:0] a, b0, b1, b2, b3;

    parameter real period = 10; //5.45
    
    reg clk = 0;
    always #(period/2.0) clk = ~clk;
    
    convmath conv (clk, reset, compute, a, b0, b1, b2, b3);

    
    initial begin
        reset = 1;
        compute = 0;
        #(period*10)
        reset = 0;
        a = 32'h01000010;
        b0 = 32'h00010203;
        b1 = 32'h04050607;
        b2 = 32'h08090A0B;
        b3 = 32'h0C0D0E0F;
        compute = 1;
        #(period*10);
        $finish;
    end
    
    
endmodule
