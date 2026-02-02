`timescale 1ns / 1ps

module mux4_nbit

    #(parameter width = 32) (
    input [width-1:0] inputzero,
    input [width-1:0] inputone,
    input [width-1:0] inputtwo,
    input [width-1:0] inputthree,
    input [1:0] select,
    output [width-1:0] finaloutput
);

genvar i;
generate
    for (i = 0; i < width; i = i + 1) begin : mux_bits
        mux4 m (
            .inputzero(inputzero[i]),
            .inputone(inputone[i]),
            .inputtwo(inputtwo[i]),
            .inputthree(inputthree[i]),
            .selectzero(select[0]),
            .selectone(select[1]),
            .finaloutput(finaloutput[i])
        );
    end
endgenerate

endmodule