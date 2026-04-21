`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/02/2026 07:10:32 AM
// Design Name: 
// Module Name: twobitcounter
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


module twobitcounter(

    input clk, en, inc, reset
    output out

    );

    wire b0_next, b1_next;
    wire b0, b1;
    wire b0_n, b1_n;

    wire i0, i1, i2, i3, i4;

    not (b0_n, b0);
    not (b1_n, b1);

    and (i0,    b0,     b1);
    and (i1,    b0_n,   b1);
    and (i2,    b0,     inc);
    and (i3,    b0_n,   inc);
    and (i4,    b1,     inc);

    or (b0_next, i1, i3, i4); // b0 = (b1 * b0') + (inc * b0') + (inc * b1)
    or (b1_next, i0, i2, i4); // b0 = (b1 * b0)  + (inc * b0)  + (inc * b1)

    dff_en_reset low  (b0_next, clk, reset, 1'b1, en, b0);
    dff_en_reset high (b1_next, clk, reset, 1'b0, en, b1);

    assign out = b1;

endmodule

module dff_en_reset(
    input datainput,
    input clock,
    input enable,
    input reset,
    input resetvalue,
    output dataoutput