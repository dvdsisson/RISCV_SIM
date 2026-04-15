module mac_32b (
    input [31:0] a, b, c,
    output [31:0] out
);
    wire [31:0] i1;
    multiplier m1 (a, b, i1, , ,);
    adder a1 (i1, c, 1'b0, out, );
    
endmodule