`timescale 1ns / 1ps

module mux2_nbit
    #(parameter width = 32) (
    input [width-1:0] inputzero,
    input [width-1:0] inputone,
    input select,
    output [width-1:0] finaloutput
);

genvar i;
generate
    for (i = 0; i < width; i = i + 1) begin : mux_bits
        mux2 m (
            .inputzero(inputzero[i]),
            .inputone(inputone[i]),
            .select(select),
            .finaloutput(finaloutput[i])
        );
    end
endgenerate

endmodule