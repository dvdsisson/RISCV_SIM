`timescale 1ns / 1ps

module dlatch(
    input D,
    input Enable,     
    output Q
);

wire D_bar, S, R, Q_bar;

not (D_bar, D);
nand (S, D, Enable);
nand (R, D_bar, Enable);
nand (Q, S, Q_bar);
nand (Q_bar, R, Q);

endmodule