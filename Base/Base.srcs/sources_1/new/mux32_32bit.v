`timescale 1ns / 1ps

module mux32_32bit(
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
    input [31:0] inputsixteen,
    input [31:0] inputseventeen,
    input [31:0] inputeighteen,
    input [31:0] inputnineteen,
    input [31:0] inputtwenty,
    input [31:0] inputtwentyone,
    input [31:0] inputtwentytwo,
    input [31:0] inputtwentythree,
    input [31:0] inputtwentyfour,
    input [31:0] inputtwentyfive,
    input [31:0] inputtwentysix,
    input [31:0] inputtwentyseven,
    input [31:0] inputtwentyeight,
    input [31:0] inputtwentynine,
    input [31:0] inputthirty,
    input [31:0] inputthirtyone,
    input [4:0] select,
    output [31:0] finaloutput
    );
wire [31:0] zero, one, two, three, four, five, six, seven, eight, nine;

mux4_32bit(inputzero, inputone, inputtwo, inputthree, select[1:0], zero);
mux4_32bit(inputfour, inputfive, inputsix, inputseven, select[1:0], one);
mux4_32bit(inputeight, inputnine, inputten, inputeleven, select[1:0], two);
mux4_32bit(inputtwelve, inputthirteen, inputfourteen, inputfifteen, select[1:0], three);
mux4_32bit(inputsixteen, inputseventeen, inputeighteen, inputnineteen, select[1:0], four);
mux4_32bit(inputtwenty, inputtwentyone, inputtwentytwo, inputtwentythree, select[1:0], five);
mux4_32bit(inputtwentyfour, inputtwentyfive, inputtwentysix, inputtwentyseven, select[1:0], six);
mux4_32bit(inputtwentyeight, inputtwentynine, inputthirty, inputthirtyone, select[1:0], seven);

mux4_32bit(zero, one, two, three, select[3:2], eight);
mux4_32bit(four, five, six, seven, select[3:2], nine);
mux2_32bit(eight, nine, select[4], finaloutput);

endmodule
