module compressionadder (
    input [31:0] a,
    output [7:0] out
);


    genvar i;


    wire [7:0] s1 [0:3];
    wire [3:0] s2Overflow;
    wire [7:0] s2 [0:1];
    wire [7:0] s2intermediate [0:1];
    wire s3Overflow;
    wire [7:0] s3intermediate;
    wire [7:0] s3;

    assign {s1[3], s1[2], s1[1], s1[0]} = a;
    
    generate
        for (i=0; i<2; i=i+1) begin
            eightbitadder add2 (s1[2*i], s1[2*i+1], 1'b0, s2intermediate[i], s2Overflow[i]);
            mux2_8b mux2 (s2intermediate[i], 8'hFF, s2Overflow[i], s2[i]);
        end
    endgenerate
    
    eightbitadder add3 (s2[0], s2[1], 1'b0, s3intermediate, s3Overflow);
    mux2_8b mux3 (s3intermediate, 8'hFF, s3Overflow, out);


endmodule