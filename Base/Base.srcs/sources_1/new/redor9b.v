module redor9b (
    input [8:0] in,
    output out
);

wire [2:0] i;

nor3$ no1 (i[0], in[0], in[1], in[2]);
nor3$ no2 (i[1], in[3], in[4], in[5]);
nor3$ no3 (i[2], in[6], in[7], in[8]);

nand3$ na1 (out, i[0], i[1], i[2]);

endmodule