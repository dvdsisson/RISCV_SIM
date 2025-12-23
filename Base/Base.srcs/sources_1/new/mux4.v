`timescale 1ns / 1ps

module mux4(
    input inputzero,
    input inputone,
    input inputtwo,
    input inputthree,
    input selectzero,
    input selectone,
    output finaloutput
    );
wire notselectzero, notselectone, inputzeroand, inputoneand, inputtwoand, inputthreeand;

not(notselectzero, selectzero);
not(notselectone, selectone);
and(inputzeroand, inputzero, notselectzero, notselectone);
and(inputoneand, inputone, selectzero, notselectone);
and(inputtwoand, inputtwo, notselectzero, selectone);
and(inputthreeand, inputthree, selectzero, selectone);
or(finaloutput, inputzeroand, inputoneand, inputtwoand, inputthreeand);

endmodule
