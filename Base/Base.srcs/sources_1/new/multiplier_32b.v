module multiplier_32b (
    input [31:0] a, b,
    output [63:0] out
);

// Stage 1 - Partial Products

    wire [31:0] s1 [0:62];

    genvar i, j;

    generate
        for (i=0; i<32; i=i+1) begin
            for (j=0; j+i<32; j=j+1) begin
                and2$ s0a1 (s1[i+j][i], a[i], b[j]);
            end
            for (j=32-i; j<32; j=j+1) begin
                and2$ s0a2 (s1[i+j][31-i], a[i], b[j]);
            end
        end
    endgenerate

// Stage 2

    wire [27:0] s2 [0:62];

    generate
        for (i=0; i<28; i=i+1) begin
            for (j=0; j<=i; j=j+1) begin
                assign s2[i][j] = s1[i][j];
                assign s2[63-i][j] = s1[63-i][j];
            end 
        //     assign s2[27][i] = s1[27][i];
        // end
        // for (i=0; i<28; i=i+1) begin
        //     assign s2[36][i] = s1[36][i];
        end
        
    endgenerate



    // Half Adders
    generate
        for (i=28; i<32; i=i+1) begin
            half_adder s2ha1 (s1[i][i-1], s1[i][i], s2[i][26], s2[i+1][27]);
        end
    endgenerate
    //half_adder s2ha2 (s1[27][26], s1[27][27], s2[27][27], s2[28][27]);
    half_adder s2ha3 (s1[32][29], s1[32][30], s2[32][26], s2[33][27]);

    assign s2[28][27] = s1[28][26];



    // Full Adders
    full_adder s2fa1 (s1[29][0], s1[29][1], s1[29][2], s2[29][25], s2[30][0]);
    full_adder s2fa2 (s1[35][0], s1[35][1], s1[35][2], s2[35][27], s2[36][27]);
    generate
        for (i = 0; i<2; i=i+1) begin
            full_adder s2fa3 (s1[30][3*i], s1[30][3*i+1], s1[30][3*i+2], s2[30][25-i], s2[31][i]);
            full_adder s2fa4 (s1[34][3*i], s1[34][3*i+1], s1[34][3*i+2], s2[34][27-i], s2[35][i]);
        end
        for (i = 0; i<3; i=i+1) begin
            full_adder s2fa5 (s1[31][3*i], s1[31][3*i+1], s1[31][3*i+2], s2[31][25-i], s2[32][i]);
            full_adder s2fa6 (s1[32][3*i], s1[32][3*i+1], s1[32][3*i+2], s2[32][25-i], s2[33][i]);
            full_adder s2fa7 (s1[33][3*i], s1[33][3*i+1], s1[33][3*i+2], s2[33][26-i], s2[34][i]);
        end
    endgenerate


    // Remaining Assignments

    generate
        for (i = 0; i<26; i=i+1) begin
            assign s2[28][i] = s1[28][i];
        end
        for (i = 0; i<25; i=i+1) begin
            assign s2[29][i] = s1[29][i];
            assign s2[35][i+2] = s1[35][i];
        end
        for (i = 0; i<23; i=i+1) begin
            assign s2[30][i+1] = s1[30][i];
            assign s2[34][i+3] = s1[34][i];
        end
        for (i = 0; i<21; i=i+1) begin
            assign s2[31][i+2] = s1[31][i];
            assign s2[33][i+3] = s1[33][i];
        end
        for (i = 0; i<20; i=i+1) begin
            assign s2[32][i+3] = s1[32][i];
        end
    endgenerate


// Stage 3

    wire [18:0] s3 [0:62];

    generate
        for (i=0; i<19; i=i+1) begin
            for (j=0; j<i; j=j+1) begin
                assign s3[i][j] = s2[i][j];
                assign s3[63-i][j] = s2[63-i][j];
            end 
        end
        
    endgenerate



    // Half Adders
    generate
        for (i=19; i<28; i=i+1) begin
            half_adder s3ha1 (s2[i][i-1], s2[i][i], s3[i][17], s3[i+1][18]);
        end
    endgenerate
    half_adder s3ha3 (s2[36][25], s2[36][26], s3[36][17], s3[37][18]);
    
    assign s3[19][18] = s2[19][17];



    // Full Adders
    //full_adder s3fa1st (s2[20][0], s2[20][1], s2[20][2], s3[20][16], s3[21][0]);s3fa1st+s3facnt

    parameter s3fa1st = 20;
    parameter s3facnt = 8;
    parameter s3faend = 44;
    full_adder s3fa2 (s2[s3faend][0], s2[s3faend][1], s2[s3faend][2], s3[s3faend][18], s3[s3faend+1][18]);
    generate
        for (i=0; i<s3facnt; i=i+1) begin
            for (j=0; j<=i; j=j+1) begin
                full_adder s3fa3 (s2[s3fa1st+i][3*j], s2[s3fa1st+i][3*j+1], s2[s3fa1st+i][3*j+2], s3[s3fa1st+i][16-j], s3[s3fa1st+1+i][j+1]);
                full_adder s3fa4 (s2[s3faend-i][3*j], s2[s3faend-i][3*j+1], s2[s3faend-i][3*j+2], s3[s3faend-i][18-j], s3[s3faend+1-i][j+1]);
            end
        end
        for (j = 0; j<=s3facnt; j=j+1) begin
            full_adder s3fa3 (s2[s3fa1st+s3facnt][3*j], s2[s3fa1st+s3facnt][3*j+1], s2[s3fa1st+s3facnt][3*j+2], s3[s3fa1st+s3facnt][17-j], s3[s3fa1st+s3facnt+1][j+1]);
        end
        for (i = 1; i<8; i=i+1) begin
            for (j=0; j<s3facnt; j=j+1) begin
                full_adder s3fa3 (s2[s3fa1st+s3facnt+i][3*j], s2[s3fa1st+s3facnt+i][3*j+1], s2[s3fa1st+s3facnt+i][3*j+2], s3[s3fa1st+s3facnt+i][18-j], s3[s3fa1st+s3facnt+1+i][j+1]);
            end
        end
        for (i = 1; i<8; i=i+1) begin
            for (j=0; j<s3facnt; j=j+1) begin
                full_adder s3fa3 (s2[s3fa1st+s3facnt+i][3*j], s2[s3fa1st+s3facnt+i][3*j+1], s2[s3fa1st+s3facnt+i][3*j+2], s3[s3fa1st+s3facnt+i][18-j], s3[s3fa1st+s3facnt+1+i][j+1]);
            end
        end
        for (j=0; j<7; j=j+1) begin
            full_adder s3fa3 (s2[s3faend-s3facnt+i][3*j], s2[s3faend-s3facnt+i][3*j+1], s2[s3faend-s3facnt+i][3*j+2], s3[s3faend-s3facnt+i][18-j], s3[s3faend-s3facnt+1+i][j+1]);
        end
    endgenerate


    // // Remaining Assignments


    // generate
    //     for (i = 0; i<26; i=i+1) begin
    //         assign s2[28][i] = s1[28][i];
    //     end
    //     for (i = 0; i<25; i=i+1) begin
    //         assign s2[29][i] = s1[29][i];
    //         assign s2[35][i+2] = s1[35][i];
    //     end
    //     for (i = 0; i<23; i=i+1) begin
    //         assign s2[30][i+1] = s1[30][i];
    //         assign s2[34][i+3] = s1[34][i];
    //     end
    //     for (i = 0; i<21; i=i+1) begin
    //         assign s2[31][i+2] = s1[31][i];
    //         assign s2[33][i+3] = s1[33][i];
    //     end
    //     for (i = 0; i<20; i=i+1) begin
    //         assign s2[32][i+3] = s1[32][i];
    //     end
    // endgenerate





endmodule