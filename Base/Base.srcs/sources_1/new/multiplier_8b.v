module multiplier_8b (
    input [7:0] a, b,
    output [15:0] out
);

// Stage 1 - Partial Products

    wire [7:0] s1 [0:14];

    genvar i, j;

    generate
        for (i=0; i<8; i=i+1) begin
            for (j=0; j+i<8; j=j+1) begin
                assign s1[i+j][i] = a[i] * b[j];
            end
            for (j=8-i; j<8; j=j+1) begin
                assign s1[i+j][7-i] = a[i] * b[j];
            end
        end
    endgenerate
    


// Stage 2

    wire [5:0] s2 [0:14];
    
    generate
        for (i=0; i<6; i=i+1) begin
            for (j=0; j<=i; j=j+1) begin
                assign s2[i][j] = s1[i][j];
            end
        end
    endgenerate

    half_adder s1ha1 (s1[6][0], s1[6][1], s2[6][0], s2[7][0]);
    
    generate
        for (i=1; i<6; i=i+1) begin
            assign s2[6][i] = s1[6][i+1];
        end
    endgenerate
    
    half_adder s1ha2 (s1[7][0], s1[7][1],           s2[7][1], s2[8][0]);
    full_adder s1fa1 (s1[7][2], s1[7][3], s1[7][4], s2[7][2], s2[8][1]);
    generate
        for (i=3; i<6; i=i+1) begin
            assign s2[7][i] = s1[7][i+2];
        end
    endgenerate

    half_adder s1ha3 (s1[8][0], s1[8][1],           s2[8][2], s2[9][0]);
    full_adder s1fa2 (s1[8][2], s1[8][3], s1[8][4], s2[8][3], s2[9][1]);
    generate
        for (i=4; i<6; i=i+1) begin
            assign s2[8][i] = s1[8][i+1];
        end
    endgenerate

    full_adder s1fa3 (s1[9][0], s1[9][1], s1[9][2], s2[9][2], s2[10][0]);
    generate
        for (i=3; i<6; i=i+1) begin
            assign s2[9][i] = s1[9][i];
        end
    endgenerate

    generate
        for (i=1; i<6; i=i+1) begin
            assign s2[10][i] = s1[10][i-1];
        end
    endgenerate

    generate
        for (i=0; i<4; i=i+1) begin
            assign s2[11][i] = s1[11][i];
        end
    endgenerate
    
    generate
        for (i=0; i<3; i=i+1) begin
            assign s2[12][i] = s1[12][i];
        end
    endgenerate

    generate
        for (i=0; i<2; i=i+1) begin
            assign s2[13][i] = s1[13][i];
        end
    endgenerate

    assign s2[14][0] = s1[14][0];


// Stage 3

    wire [3:0] s3 [0:14];

    generate
        for (i=0; i<4; i=i+1) begin
            for (j=0; j<=i; j=j+1) begin
                assign s3[i][j] = s2[i][j];
            end
        end
    endgenerate

    half_adder s3ha1 (s2[4][0], s2[4][1], s3[4][0], s3[5][0]);

    generate
        for (i=1; i<4; i=i+1) begin
            assign s3[4][i] = s2[4][i+1];
        end
    endgenerate

    generate
        for (i=5; i<12; i=i+1) begin
            full_adder s3fa1 (s2[i][0], s2[i][1], s2[i][2], s3[i][1], s3[i+1][0]);
        end
    endgenerate

    half_adder s3ha2 (s2[5][3], s2[5][4], s3[5][2], s3[6][2]);

    assign s3[5][3] = s2[5][5];

    generate
        for (i=6; i<11; i=i+1) begin
            full_adder s3fa2 (s2[i][3], s2[i][4], s2[i][5], s3[i][3], s3[i+1][2]);
        end
    endgenerate

    assign s3[11][3] = s2[11][3];

    generate
        for (i=1; i<4; i=i+1) begin
            assign s3[12][i] = s2[12][i-1];
        end
        for (i=0; i<2; i=i+1) begin
            assign s3[13][i] = s2[13][i];
        end
    endgenerate

    assign s3[14][0] = s2[14][0];



// Stage 4

    wire [2:0] s4 [0:14];

    generate
        for (i=0; i<3; i=i+1) begin
            for (j=0; j<=i; j=j+1) begin
                assign s4[i][j] = s3[i][j];
            end
        end

        for (i=3; i<15; i=i+1) begin
            assign s4[i][0] = s3[i][0];
        end
    endgenerate

    assign s4[3][2] = s3[3][2];
    half_adder s4ha1 (s3[3][3], s3[3][4], s4[3][1], s4[4][1]);

    generate
        for (i=4; i<13; i=i+1) begin
            full_adder s4fa1 (s3[i][1], s3[i][2], s3[i][3], s4[i][2], s4[i+1][1]);
        end
    endgenerate

    assign s4[13][2] = s3[13][1];

// Stage 5

    wire [1:0] s5 [0:14];

    generate
        for (i=0; i<2; i=i+1) begin
            for (j=0; j<=i; j=j+1) begin
                assign s5[i][j] = s4[i][j];
            end
        end
    endgenerate

    half_adder s5ha1 (s4[2][0], s4[2][1], s5[2][0], s5[3][0]);
    assign s5[2][1] = s4[2][2];

    generate
        for (i=3; i<14; i=i+1) begin
            full_adder s5fa1 (s4[i][0], s4[i][1], s4[i][2], s5[i][1], s5[i+1][0]);
        end
    endgenerate

    assign s5[14][1] = s4[14][0];

// Final

    wire [31:0] fin;
    wire cout;

    assign s5[0][1] = 1'b0;

    wire [14:0] s5a, s5b;

    generate
        for (i=0; i<15; i=i+1) begin
            assign s5a[i] = s5[i][0];
            assign s5b[i] = s5[i][1];
        end
    endgenerate

    adder finaladd ({17'b0, s5a}, {17'b0, s5b}, 1'b0, fin, cout);

    assign out = fin [15:0];



endmodule