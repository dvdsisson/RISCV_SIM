`timescale 1ns / 1ps

module divider(
    input [31:0] A,
    input [31:0] B,
    input clk, rst, start,
    output [31:0] DIVoutput,
    output [31:0] DIVUoutput,
    output [31:0] REMoutput,
    output [31:0] REMUoutput,
    output done
    );

    divider_block usigned_div(clk, rst, start, A, B, 1'b0, REMUoutput, DIVUoutput, done);
    divider_block usigned_div(clk, rst, start, A, B, 1'b1, REMoutput, DIVoutput, done);

endmodule