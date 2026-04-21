`timescale 1ns / 1ps

module dff_reset(
    input datainput,
    input clock,
    input reset,         
    input resetvalue,   
    output dataoutput
);

wire not_clock, datain_effective, master_q;

inv1$ i1 (not_clock, clock);
mux2 mux_reset(datainput, resetvalue, reset, datain_effective);
dlatch master(datain_effective, not_clock, master_q);
dlatch slave(master_q, clock, dataoutput);

endmodule