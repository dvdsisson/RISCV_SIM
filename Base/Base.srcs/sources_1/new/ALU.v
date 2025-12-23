`timescale 1ns / 1ps

module ALU(
    input [31:0] A,
    input [31:0] B,
    input [4:0] ALU_OP,
    output [31:0] C,
    output EX_STALL
    );
 
wire [31:0] notB, adderinputB, adderoutput;
wire [31:0] SRLoutput, SRAoutput, SLLoutput;
wire [31:0] SLToutput, SLTUoutput;
wire sgreater, snotgreater, sless, snotless, sequal, snotequal;
wire ugreater, unotgreater, uless, unotless, uequal, unotequal;
wire [31:0] ORoutput, ANDoutput, XORoutput;
wire [31:0] MULoutput, MULHoutput, MULHSUoutput, MULHUoutput;
wire [31:0] DIVoutput, DIVUoutput, REMoutput, REMUoutput;
wire [31:0] zero, one;

assign zero = 32'b00000000000000000000000000000000;
assign one = 32'b00000000000000000000000000000001;

genvar i;
generate
    for (i = 0; i < 32; i = i + 1) begin : invert_bits
        not n1(notB[i], B[i]);
    end
endgenerate

mux2_32bit(B, notB, ALU_OP[0], adderinputB);
adder(A, adderinputB, ALU_OP[0], adderoutput);
shifter(A, B[4:0], SRLoutput, SRAoutput, SLLoutput);
signedcomparator_32bit(A, B, sgreater, snotgreater, sless, snotless, sequal, snotequal);
unsignedcomparator_32bit(A, B, ugreater, unotgreater, uless, unotless, uequal, unotequal);
mux2_32bit(zero, one, sless, SLToutput); 
mux2_32bit(zero, one, uless, SLTUoutput);
logicunit(A, B, ORoutput, ANDoutput, XORoutput);
multiplier(A, B, MULoutput, MULHoutput, MULHSUoutput, MULHUoutput);
divider(A, B, DIVoutput, DIVUoutput, REMoutput, REMUoutput);

mux32_32bit(adderoutput, adderoutput, zero, zero, SRLoutput, SRAoutput, SLLoutput, zero, SLToutput, SLTUoutput, zero, zero, ORoutput, ANDoutput, XORoutput, zero, MULoutput, MULHoutput, MULHSUoutput, MULHUoutput, DIVoutput, DIVUoutput, REMoutput, REMUoutput, zero, zero, zero, zero, zero, zero, zero, B, ALU_OP, C); 
assign EX_STALL = 1'b0;

endmodule
