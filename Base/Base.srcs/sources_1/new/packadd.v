module packadd (
    input [31:0] a, b,
    output [31:0] out
);

    wire [3:0] overflow;
    wire [7:0] satout [0:3];
    wire [7:0] intermediate [0:3];

    genvar i;
    generate
        for (i=0; i<4; i=i+1) begin
            eightbitadder add1 (a[8*i+7:8*i], b[8*i+7:8*i], 1'b0, intermediate[i], overflow[i]);
            mux2_8b mux1 (intermediate[i][7:0], 8'hFF, overflow[i], satout[i]);
        end    
    endgenerate

    assign out = {satout[3], satout[2], satout[1], satout[0]};
    
endmodule