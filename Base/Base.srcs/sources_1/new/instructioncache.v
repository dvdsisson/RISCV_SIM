`timescale 1ns / 1ps

module instructioncache(
    input [31:0] address,
    output [31:0] outputvalue
    );

// need to implement; for now cache not connected, processor accesses memory directly
assign outputvalue = 32'b0;

endmodule
