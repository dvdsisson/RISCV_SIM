`timescale 1ns / 1ps

module reg32_en
    
    #(parameter length = 32) (
    input [length-1:0] datainput,
    input clock,
    input enable,
    output [length-1:0] dataoutput
    );

genvar i;
generate
    for (i = 0; i < length; i = i + 1) begin : dff_array
        dff_en u_dff (
            .datainput(datainput[i]),
            .clock(clock),
            .enable(enable),
            .dataoutput(dataoutput[i])
        );
    end
endgenerate

endmodule