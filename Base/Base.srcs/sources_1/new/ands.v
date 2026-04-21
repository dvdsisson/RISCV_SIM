module and5 (
    output out,
    input a1, a2, a3, a4, a5
);

    and6 o1 (out, a1, a2, a3, a4, a5, 1'b1);
    
endmodule

module and6 (
    output out,
    input a1, a2, a3, a4, a5, a6
);

    wire [1:0] i;
    nand3$ na1 (i[0], a1, a2, a3);
    nand3$ na2 (i[1], a4, a5, a6);

    nor2$ no1 (out, i[0], i[1]);
    
    
endmodule

module and7 (
    output out,
    input a1, a2, a3, a4, a5, a6, a7
);

    and9 o1 (out, a1, a2, a3, a4, a5, a6, a7, 1'b1, 1'b1);

endmodule

module and8 (
    output out,
    input a1, a2, a3, a4, a5, a6, a7, a8

);

    and9 o1 (out, a1, a2, a3, a4, a5, a6, a7, a8, 1'b1);
    
endmodule

module and9 (
    output out,
    input a1, a2, a3, a4, a5, a6, a7, a8, a9
);

    wire [2:0] i;
    nand3$ na1 (i[0], a1, a2, a3);
    nand3$ na2 (i[1], a4, a5, a6);
    nand3$ na3 (i[2], a7, a8, a9);

    nor3$ no1 (out, i[0], i[1], i[2]);
    
endmodule