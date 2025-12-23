`timescale 1ns / 1ps

module branchcomparator(
    input [31:0] A,
    input [31:0] B,
    input [2:0] COMP_OP,
    output result
    );
wire ugreater, unotgreater, uless, unotless, uequal, unotequal;
wire sgreater, snotgreater, sless, snotless, sequal, snotequal;
wire zero, one;

unsignedcomparator_32bit(A, B, ugreater, unotgreater, uless, unotless, uequal, unotequal);
signedcomparator_32bit(A, B, sgreater, snotgreater, sless, snotless, sequal, snotequal);

mux4(1'b0, uequal, unotequal, sless, COMP_OP[0], COMP_OP[1], zero);
mux4(snotless, uless, unotless, 1'b1, COMP_OP[0], COMP_OP[1], one);
mux2(zero, one, COMP_OP[2], result);

endmodule
