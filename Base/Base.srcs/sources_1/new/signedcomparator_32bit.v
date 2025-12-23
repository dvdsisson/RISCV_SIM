`timescale 1ns / 1ps

module signedcomparator_32bit(
    input [31:0] A,
    input [31:0] B,
    output greater,
    output notgreater,
    output less,
    output notless,
    output equal,
    output notequal
    );
wire gtintermediate, ltintermediate, eqintermediate, notA31, notB31, notsamesign, samesign;
wire one, two, three, four;

wire [31:0] gt;
wire [31:0] lt;
wire [31:0] eq;

not(notA31, A[31]);
not(notB31, B[31]);
xor(notsamesign, A[31], B[31]);
not(samesign, notsamesign);

assign gt[31] = 1'b0;
assign lt[31] = 1'b0;
assign eq[31] = 1'b1;

genvar i;
generate
    for (i = 30; i >= 0; i = i - 1) begin : COMPARE
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

assign gtintermediate = gt[0];
assign ltintermediate = lt[0];
assign eqintermediate = eq[0];

and(one, notA31, B[31]);
and(two, samesign, gtintermediate);
and(three, A[31], notB31);
and(four, samesign, ltintermediate);
or(greater, one, two);
or(less, three, four);
and(equal, samesign, eqintermediate);

not (notgreater, greater);
not (notless, less);
not (notequal, equal);

endmodule
