module redor6b (
    input [5:0] in,
    output out
);

wire [2:0] i;

nor2$ no1 (i[0], in[0], in[1]);
nor2$ no2 (i[1], in[2], in[3]);
nor2$ no3 (i[2], in[4], in[5]);

nand3$ na1 (out, i[0], i[1], i[2]);

endmodule