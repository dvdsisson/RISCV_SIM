`timescale 1ns / 1ps

module mux32_nbit
    #(parameter reg_length = 32) (
    input [(reg_length-1):0] inputzero,
    input [(reg_length-1):0] inputone,
    input [(reg_length-1):0] inputtwo,
    input [(reg_length-1):0] inputthree,
    input [(reg_length-1):0] inputfour,
    input [(reg_length-1):0] inputfive,
    input [(reg_length-1):0] inputsix,
    input [(reg_length-1):0] inputseven,
    input [(reg_length-1):0] inputeight,
    input [(reg_length-1):0] inputnine,
    input [(reg_length-1):0] inputten,
    input [(reg_length-1):0] inputeleven,
    input [(reg_length-1):0] inputtwelve,
    input [(reg_length-1):0] inputthirteen,
    input [(reg_length-1):0] inputfourteen,
    input [(reg_length-1):0] inputfifteen,
    input [(reg_length-1):0] inputsixteen,
    input [(reg_length-1):0] inputseventeen,
    input [(reg_length-1):0] inputeighteen,
    input [(reg_length-1):0] inputnineteen,
    input [(reg_length-1):0] inputtwenty,
    input [(reg_length-1):0] inputtwentyone,
    input [(reg_length-1):0] inputtwentytwo,
    input [(reg_length-1):0] inputtwentythree,
    input [(reg_length-1):0] inputtwentyfour,
    input [(reg_length-1):0] inputtwentyfive,
    input [(reg_length-1):0] inputtwentysix,
    input [(reg_length-1):0] inputtwentyseven,
    input [(reg_length-1):0] inputtwentyeight,
    input [(reg_length-1):0] inputtwentynine,
    input [(reg_length-1):0] inputthirty,
    input [(reg_length-1):0] inputthirtyone,
    input [4:0] select,
    output [(reg_length-1):0] finaloutput
    );
wire [(reg_length-1):0] zero, one, two, three, four, five, six, seven, eight, nine;

mux4_32bit #(.width(reg_length)) (inputzero, inputone, inputtwo, inputthree, select[1:0], zero);
mux4_32bit #(.width(reg_length)) (inputfour, inputfive, inputsix, inputseven, select[1:0], one);
mux4_32bit #(.width(reg_length)) (inputeight, inputnine, inputten, inputeleven, select[1:0], two);
mux4_32bit #(.width(reg_length)) (inputtwelve, inputthirteen, inputfourteen, inputfifteen, select[1:0], three);
mux4_32bit #(.width(reg_length)) (inputsixteen, inputseventeen, inputeighteen, inputnineteen, select[1:0], four);
mux4_32bit #(.width(reg_length)) (inputtwenty, inputtwentyone, inputtwentytwo, inputtwentythree, select[1:0], five);
mux4_32bit #(.width(reg_length)) (inputtwentyfour, inputtwentyfive, inputtwentysix, inputtwentyseven, select[1:0], six);
mux4_32bit #(.width(reg_length)) (inputtwentyeight, inputtwentynine, inputthirty, inputthirtyone, select[1:0], seven);

mux4_32bit #(.width(reg_length)) (zero, one, two, three, select[3:2], eight);
mux4_32bit #(.width(reg_length)) (four, five, six, seven, select[3:2], nine);
mux2_32bit #(.width(reg_length)) (eight, nine, select[4], finaloutput);

endmodule
