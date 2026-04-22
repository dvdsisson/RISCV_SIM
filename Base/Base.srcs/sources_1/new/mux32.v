`timescale 1ns / 1ps

module mux32(
    input inputzero,
    input inputone,
    input inputtwo,
    input inputthree,
    input inputfour,
    input inputfive,
    input inputsix,
    input inputseven,
    input inputeight,
    input inputnine,
    input inputten,
    input inputeleven,
    input inputtwelve,
    input inputthirteen,
    input inputfourteen,
    input inputfifteen,
    input inputsixteen,
    input inputseventeen,
    input inputeighteen,
    input inputnineteen,
    input inputtwenty,
    input inputtwentyone,
    input inputtwentytwo,
    input inputtwentythree,
    input inputtwentyfour,
    input inputtwentyfive,
    input inputtwentysix,
    input inputtwentyseven,
    input inputtwentyeight,
    input inputtwentynine,
    input inputthirty,
    input inputthirtyone,
    input [4:0] select,
    output finaloutput
    );
wire zero, one, two, three, four, five, six, seven, eight, nine;

mux4 Mux1(inputzero, inputone, inputtwo, inputthree, select[1:0], zero);
mux4 Mux2(inputfour, inputfive, inputsix, inputseven, select[1:0], one);
mux4 Mux3(inputeight, inputnine, inputten, inputeleven, select[1:0], two);
mux4 Mux4(inputtwelve, inputthirteen, inputfourteen, inputfifteen, select[1:0], three);
mux4 Mux5(inputsixteen, inputseventeen, inputeighteen, inputnineteen, select[1:0], four);
mux4 Mux6(inputtwenty, inputtwentyone, inputtwentytwo, inputtwentythree, select[1:0], five);
mux4 Mux7(inputtwentyfour, inputtwentyfive, inputtwentysix, inputtwentyseven, select[1:0], six);
mux4 Mux8(inputtwentyeight, inputtwentynine, inputthirty, inputthirtyone, select[1:0], seven);

mux4 Mux9(zero, one, two, three, select[3:2], eight);
mux4 Mux10(four, five, six, seven, select[3:2], nine);
mux2 Mux11(eight, nine, select[4], finaloutput);

endmodule