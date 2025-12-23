`timescale 1ns / 1ps

module mux16_32bit(
    input [31:0] inputzero,
    input [31:0] inputone,
    input [31:0] inputtwo,
    input [31:0] inputthree,
    input [31:0] inputfour,
    input [31:0] inputfive,
    input [31:0] inputsix,
    input [31:0] inputseven,
    input [31:0] inputeight,
    input [31:0] inputnine,
    input [31:0] inputten,
    input [31:0] inputeleven,
    input [31:0] inputtwelve,
    input [31:0] inputthirteen,
    input [31:0] inputfourteen,
    input [31:0] inputfifteen,
    input [3:0] select,
    output [31:0] finaloutput
    );
wire [31:0] zero, one, two, three;

mux4_32bit(inputzero, inputone, inputtwo, inputthree, select[1:0], zero);
mux4_32bit(inputfour, inputfive, inputsix, inputseven, select[1:0], one);
mux4_32bit(inputeight, inputnine, inputten, inputeleven, select[1:0], two);
mux4_32bit(inputtwelve, inputthirteen, inputfourteen, inputfifteen, select[1:0], three);

mux4_32bit(zero, one, two, three, select[3:2], finaloutput);

endmodule
