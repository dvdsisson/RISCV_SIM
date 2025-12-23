`timescale 1ns / 1ps

module divider(
    input [31:0] A,
    input [31:0] B,
    output [31:0] DIVoutput,
    output [31:0] DIVUoutput,
    output [31:0] REMoutput,
    output [31:0] REMUoutput
    );

// need to implement; for now, ouputting zeroes
assign DIVoutput = 32'b00000000000000000000000000000000;
assign DIVUoutput = 32'b00000000000000000000000000000000;
assign REMoutput = 32'b00000000000000000000000000000000;
assign REMUoutput = 32'b00000000000000000000000000000000;
 
endmodule
