`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/26/2026 06:54:20 PM
// Design Name: 
// Module Name: fivebitequality
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


module fivebitequality(
    output equal,
    input [4:0] a,
    input [4:0] b
    );
    
    wire [4:0] xnor_result, and_0, and_1, and_2;
    
    xnor(xnor_result, a, b);
    and(and_0, xnor_result[0], xnor_result[1]);
    and(and_1, xnor_result[2], xnor_result[3]);
    and(and_2, and_0, xnor_result[5]);
    and(equal, and_2, and_1);
    
    
endmodule
