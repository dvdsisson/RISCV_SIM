`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/02/2026 08:34:43 AM
// Design Name: 
// Module Name: shf_reg
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


module shf_reg

    #(parameter length = 5) (

    input clk, en, in, 
    output [length-1:0] out

    );

    wire [length-1:1] flopOut;

    dff_en flop0 (in, clk, en, flopOut[0]);
    genvar i;
    generate
        for (i=1; i<length; i=i+1) begin: shfReg
            dff_en flop (flopOut[i-1], clk, en, flopOut[i]);
        end
    endgenerate

    assign out[length-1:0] = flopOut[length-1:0];

endmodule