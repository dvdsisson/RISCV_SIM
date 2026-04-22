module mac_8b (
    input [31:0] a, b, //prev 7:0
    output [7:0] out
);
    // wire [15:0] multout[i];
    // multiplier_8b m1 (a, b, multout[i]);

    // wire multoverflow;
    // or or1 (multoverflow, multout[i][15], multout[i][14], multout[i][13], multout[i][12], multout[i][11], multout[i][10], multout[i][9]);

    // wire [7:0] multout;
    // mux2_8b mux1 (multout[i][7:0], 8'hFF, multoverflow, multout);

    // wire addoverflow;
    // wire [7:0] addout;
    // eightbitadder a1 (multout, c, 1'b0, addout, addoverflow);

    // mux2_8b mux2 (addout, 8'hFF, addoverflow, out);

    wire [14:0] multout [0:3];
    wire [3:0] multoverflow;
    wire [7:0] satout [0:3];

    genvar i;
    generate
        for (i=0; i<4; i=i+1) begin
            multiplier_8b mult1 (a[8*i+7:8*i], b[8*i+7:8*i], multout[i]);
            redor9b or1 ({2'b0, multout[i][14:8]}, multoverflow[i]);
            assign satout[i] = {0, multout[i][14:8]};
            // mux2_8b mux1 (multout[i][7:0], 8'hFF, multoverflow[i], satout[i]);
        end    
    endgenerate
    
    compressionadder cadd1 ({satout[3], satout[2], satout[1], satout[0]}, out);

endmodule
