module satadd (
    input [7:0] a, b,
    output [7:0] out
);
    
wire [7:0] addout;

eightbitadder add1 (a, b, 1'b0, addout, overflow);
mux2_8b mux4 (addout, 8'hFF, overflow, out);

endmodule