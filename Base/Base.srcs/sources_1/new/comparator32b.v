`timescale 1ns / 1ps

module comparator32b(
    input [31:0] A,
    input [31:0] B, 
    output equal      
    );
wire [31:0] bitwise_eq;

genvar i;
generate
    for (i=0; i<32; i=i+1) begin: comp
        xnor(bitwise_eq[i], A[i], B[i]);
    end
endgenerate

and(equal, bitwise_eq[0], bitwise_eq[1], bitwise_eq[2], bitwise_eq[3], bitwise_eq[4], bitwise_eq[5], bitwise_eq[6], bitwise_eq[7], bitwise_eq[8], bitwise_eq[9], bitwise_eq[10], bitwise_eq[11], bitwise_eq[12], bitwise_eq[13], bitwise_eq[14], bitwise_eq[15], bitwise_eq[16], bitwise_eq[17], bitwise_eq[18], bitwise_eq[19], bitwise_eq[20], bitwise_eq[21], bitwise_eq[22], bitwise_eq[23], bitwise_eq[24], bitwise_eq[25], bitwise_eq[26], bitwise_eq[27], bitwise_eq[28], bitwise_eq[29], bitwise_eq[30], bitwise_eq[31]);

endmodule
