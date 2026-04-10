`timescale 1ns / 1ps

module adder(
    input [31:0] A,
    input [31:0] B,
    input Cin,
    output [31:0] S,
    output Cout
    );  

wire C1, C2, C3;

eightbitadder EightBitAdder1(A[7:0], B[7:0], Cin, S[7:0], C1);
eightbitadder EightBitAdder2(A[15:8], B[15:8], C1, S[15:8], C2);
eightbitadder EightBitAdder3(A[23:16], B[23:16], C2, S[23:16], C3);
eightbitadder EightBitAdder4(A[31:24], B[31:24], C3, S[31:24], Cout);

endmodule