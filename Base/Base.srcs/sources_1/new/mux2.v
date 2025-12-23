`timescale 1ns / 1ps

module mux2(
    input inputzero,
    input inputone,
    input select,
    output finaloutput
    );
wire notselect, inputzeroand, inputoneand;

not(notselect, select);
and(inputzeroand, inputzero, notselect);
and(inputoneand, inputone, select);
or(finaloutput, inputzeroand, inputoneand);

endmodule
