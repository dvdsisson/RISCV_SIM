module addressgen  (
    input [31:0] x, y, vert, hor, ptr,
    output [31:0] address
);

    wire [31:0] i1;
    mac_32b m1 (vert, y, ptr, i1);
    mac_32b m2 (x, hor, i1, address);
endmodule