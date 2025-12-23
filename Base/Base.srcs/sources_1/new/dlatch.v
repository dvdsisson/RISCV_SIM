`timescale 1ns / 1ps

module dlatch(
    input datainput,
    input enable,
    output dataoutput
    );
wire notdatainput, datainputand, notdatainputand, notdataoutput;

not(notdatainput, datainput);
and(datainputand, datainput, enable);
and(notdatainputand, notdatainput, enable);
nor(notdataoutput, datainputand, dataoutput);
nor(dataoutput, notdatainputand, notdataoutput);

endmodule
