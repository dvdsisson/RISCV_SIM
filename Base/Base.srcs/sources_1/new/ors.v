module or5 (
    output out,
    input a1, a2, a3, a4, a5
);

    or6 o1 (out, a1, a2, a3, a4, a5, 1'b0);
    
endmodule

module or6 (
    output out,
    input a1, a2, a3, a4, a5, a6
);

    wire [1:0] i;
    nor3$ na1 (i[0], a1, a2, a3);
    nor3$ na2 (i[1], a4, a5, a6);

    nand2$ no1 (out, i[0], i[1]);
    
    
endmodule

module or7 (
    output out,
    input a1, a2, a3, a4, a5, a6, a7
);

    or9 o1 (out, a1, a2, a3, a4, a5, a6, a7, 1'b0, 1'b0);

endmodule

module or8 (
    output out,
    input a1, a2, a3, a4, a5, a6, a7, a8

);

    or9 o1 (out, a1, a2, a3, a4, a5, a6, a7, a8, 1'b0);
    
endmodule

module or9 (
    output out,
    input a1, a2, a3, a4, a5, a6, a7, a8, a9
);

    wire [2:0] i;
    nor3$ na1 (i[0], a1, a2, a3);
    nor3$ na2 (i[1], a4, a5, a6);
    nor3$ na3 (i[2], a7, a8, a9);

    nand3$ no1 (out, i[0], i[1], i[2]);
    
endmodule