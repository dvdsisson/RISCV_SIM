`timescale 1ns / 1ps

module dff_en(
    input datainput,
    input clock,
    input enable,
    output dataoutput
);

wire mux_out;

mux2 mux_enable(dataoutput, datainput, enable, mux_out);
dff_reset DFF(mux_out, clock, 1'b0, 1'b0, dataoutput);

endmodule