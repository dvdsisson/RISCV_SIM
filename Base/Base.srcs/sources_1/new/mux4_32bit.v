`timescale 1ns / 1ps

module mux4_32bit(
    input [31:0] inputzero,
    input [31:0] inputone,
    input [31:0] inputtwo,
    input [31:0] inputthree,
    input [1:0] select,
    output [31:0] finaloutput
);

genvar i;
generate
    for (i = 0; i < 32; i = i + 1) begin : mux_bits
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