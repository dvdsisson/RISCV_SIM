`timescale 1ns / 1ps

module mux2_32bit(
    input [31:0] inputzero,
    input [31:0] inputone,
    input select,
    output [31:0] finaloutput
);

genvar i;
generate
    for (i = 0; i < 32; i = i + 1) begin : mux_bits
        mux2 m (
            .inputzero(inputzero[i]),
            .inputone(inputone[i]),
            .select(select),
            .finaloutput(finaloutput[i])
        );
    end
endgenerate

endmodule