`timescale 1ns / 1ps

module dff_en_reset(
    input datainput,
    input clock,
    input enable,
    input reset,
    input resetvalue,
    output dataoutput
);

wire mux_enable_out, mux_reset_out;

mux2 mux_enable(dataoutput, datainput, enable,mux_enable_out);
mux2 mux_reset(mux_enable_out, resetvalue, reset, dff_input);
dff_reset DFF(dff_input, clock, 1'b0, 1'b0, dataoutput);

endmodule