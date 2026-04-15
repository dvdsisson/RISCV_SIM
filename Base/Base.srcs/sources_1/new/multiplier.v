`timescale 1ns / 1ps

module multiplier(
    input  [31:0] A,
    input  [31:0] B,
    output [31:0] MULoutput,      // lower 32 bits
    output [31:0] MULHoutput,     // signed * signed upper 32 bits
    output [31:0] MULHSUoutput,   // signed * unsigned upper 32 bits
    output [31:0] MULHUoutput     // unsigned * unsigned upper 32 bits
);

// // need to implement; for now, ouputting zeroes
// assign MULoutput = 32'b00000000000000000000000000000000;
// assign MULHoutput = 32'b00000000000000000000000000000000;
// assign MULHSUoutput = 32'b00000000000000000000000000000000;
// assign MULHUoutput = 32'b00000000000000000000000000000000;

assign MULoutput = A * B;

 
endmodule
