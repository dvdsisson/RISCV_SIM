`timescale 1ns / 1ps

module mux8_32bit(
    input [31:0] inputzero,
    input [31:0] inputone,
    input [31:0] inputtwo,
    input [31:0] inputthree,
    input [31:0] inputfour,
    input [31:0] inputfive,
    input [31:0] inputsix,
    input [31:0] inputseven,
    input [2:0] select,
    output [31:0] finaloutput
    );
wire [31:0] zero, one;

mux4_32bit(inputzero, inputone, inputtwo, inputthree, select[1:0], zero);
mux4_32bit(inputfour, inputfive, inputsix, inputseven, select[1:0], one);

mux2_32bit(zero, one, select[2], finaloutput);

endmodule
