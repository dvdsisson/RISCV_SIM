`timescale 1ns / 1ps

module logicunit(
    input [31:0] A,
    input [31:0] B,
    output [31:0] oroutput,
    output [31:0] andoutput,
    output [31:0] xoroutput
    );
    
genvar i;
generate
    for (i = 0; i < 32; i = i + 1) begin : logic_bits
        or  u_or  (oroutput[i],  A[i], B[i]);
        and u_and (andoutput[i], A[i], B[i]);
        xor u_xor (xoroutput[i], A[i], B[i]);
    end
endgenerate

endmodule
