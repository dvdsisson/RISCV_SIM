`timescale 1ns / 1ps

module datacache(
    input [31:0] address,
    input [31:0] inputvalue,
    input LDST,
    input [2:0] LDST_OP,
    output [31:0] outputvalue,
    output MEM_STALL
    );

// need to implement; for now cache not connected, processor accesses memory directly
assign outputvalue = 32'b0;
assign MEM_STALL = 1'b0;

endmodule
