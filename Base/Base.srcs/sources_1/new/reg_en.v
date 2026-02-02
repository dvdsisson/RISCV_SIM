`timescale 1ns / 1ps

module reg_en
    #(parameter width = 32) (
    input [width-1:0] datainput,
    input clock,
    input enable,
    output [width-1:0] dataoutput
    );

genvar i;
generate
    for (i = 0; i < width; i = i + 1) begin : dff_array
        dff_en u_dff (
            .datainput(datainput[i]),
            .clock(clock),
            .enable(enable),
            .dataoutput(dataoutput[i])
        );
    end
endgenerate

endmodule