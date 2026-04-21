`timescale 1ns / 1ps

module dlatch(
    input D,
    input Enable,     
    output Q
);

wire D_bar, S, R, Q_bar;

inv1$ i1 (D_bar, D);
nand2$ na1 (S, D, Enable);
nand2$ na2 (R, D_bar, Enable);
nand2$ na3 (Q, S, Q_bar);
nand2$ na4 (Q_bar, R, Q);

endmodule