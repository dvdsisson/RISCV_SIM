`timescale 1ns / 1ps

module dff_en(
    input datainput,
    input clock,
    input enable,
    output dataoutput
    );
wire effectiveclock;

and(effectiveclock, clock, enable);
dff(datainput, effectiveclock, dataoutput);

endmodule
