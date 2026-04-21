module redand32b (
    input [31:0] in,
    output out
);

    wire [35:0] s0; //36
    wire [11:0] s1; //12
    wire [5:0] s2; //6
    wire [1:0] s3; //2

    assign s0 = {in, 4'b1111};

    genvar i;

    generate
        for (i=0; i<12; i=i+1) begin
            nand3$ na1 (s1[i], s0[3*i], s0[3*i+1], s0[3*i+2]);
        end
        for (i=0; i<6; i=i+1) begin
            nor2$ no1 (s2[i], s1[2*i], s1[2*i+1]);
        end
        for (i=0; i<2; i=i+1) begin
            nand3$ na2 (s3[i], s2[3*i], s2[3*i+1], s2[3*i+2]);
        end
    endgenerate

    nor2$ no2 (out, s3[0], s3[1]);
    
endmodule