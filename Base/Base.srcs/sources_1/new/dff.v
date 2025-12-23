`timescale 1ns / 1ps

module dff(
    input datainput,
    input clock,
    output dataoutput
    );
wire notclock, dataintermediate;

not(notclock, clock);
dlatch master(datainput, notclock, dataintermediate);
dlatch slave(dataintermediate, clock, dataoutput);

endmodule
