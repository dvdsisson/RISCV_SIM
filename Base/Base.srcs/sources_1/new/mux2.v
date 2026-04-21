`timescale 1ns / 1ps

module mux2(
    input inputzero,
    input inputone,
    input select,
    output finaloutput
    );
wire notselect, inputzeroand, inputoneand;

inv1$ i1 (notselect, select);
and2$ a1 (inputzeroand, inputzero, notselect);
and2$ a2 (inputoneand, inputone, select);
or2$ o1 (finaloutput, inputzeroand, inputoneand);

endmodule
