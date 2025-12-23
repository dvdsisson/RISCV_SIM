`timescale 1ns / 1ps

module unsignedcomparator_32bit(
    input [31:0] A,
    input [31:0] B,
    output greater,
    output notgreater,
    output less,
    output notless,
    output equal,
    output notequal
    );
    
wire [32:0] gt;
wire [32:0] lt;
wire [32:0] eq;

assign gt[32] = 1'b0;
assign lt[32] = 1'b0;
assign eq[32] = 1'b1;

genvar i;
generate
    for (i = 31; i >= 0; i = i - 1) begin : COMPARE
        comparatorblock cb (
            .greater     (gt[i+1]),
            .less        (lt[i+1]),
            .equal       (eq[i+1]),
            .A           (A[i]),
            .B           (B[i]),
            .nextgreater (gt[i]),
            .nextless    (lt[i]),
            .nextequal   (eq[i])
        );
    end
endgenerate

assign greater = gt[0];
assign less = lt[0];
assign equal = eq[0];

not(notgreater, greater);
not(notless, less);
not(notequal, equal);

endmodule
