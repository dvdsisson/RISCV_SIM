`timescale 1ns / 1ps

module multiplier(
    input [31:0] A,
    input [31:0] B,
    output [31:0] MULoutput,
    output [31:0] MULHoutput,
    output [31:0] MULHSUoutput,
    output [31:0] MULHUoutput
    );

// Top Layer of Partial Product
wire [31:0] p0_inter;
wire [31:0] p1_inter;
wire [31:0] p2_inter;
wire [31:0] p3_inter;
wire [31:0] p4_inter;
wire [31:0] p5_inter;
wire [31:0] p6_inter;
wire [31:0] p7_inter;
wire [31:0] p8_inter;
wire [31:0] p9_inter;
wire [31:0] p10_inter;
wire [31:0] p11_inter;
wire [31:0] p12_inter;
wire [31:0] p13_inter;
wire [31:0] p14_inter;
wire [31:0] p15_inter;
wire [31:0] p16_inter;
wire [31:0] p17_inter;
wire [31:0] p18_inter;
wire [31:0] p19_inter;
wire [31:0] p20_inter;
wire [31:0] p21_inter;
wire [31:0] p22_inter;
wire [31:0] p23_inter;
wire [31:0] p24_inter;
wire [31:0] p25_inter;
wire [31:0] p26_inter;
wire [31:0] p27_inter;
wire [31:0] p28_inter;
wire [31:0] p29_inter;
wire [31:0] p30_inter;
wire [31:0] p31_inter;

genvar i;
generate
    for (i = 0; i < 32; i = i + 1) begin : logic_bits
        and (p0_inter[i], A[0], B[i]);
        and (p1_inter[i], A[1], B[i]);
        and (p2_inter[i], A[2], B[i]);
        and (p3_inter[i], A[3], B[i]);
        and (p4_inter[i], A[4], B[i]);
        and (p5_inter[i], A[5], B[i]);
        and (p6_inter[i], A[6], B[i]);
        and (p7_inter[i], A[7], B[i]);
        and (p8_inter[i], A[8], B[i]);
        and (p9_inter[i], A[9], B[i]);
        and (p10_inter[i], A[10], B[i]);
        and (p11_inter[i], A[11], B[i]);
        and (p12_inter[i], A[12], B[i]);
        and (p13_inter[i], A[13], B[i]);
        and (p14_inter[i], A[14], B[i]);
        and (p15_inter[i], A[15], B[i]);
        and (p16_inter[i], A[16], B[i]);
        and (p17_inter[i], A[17], B[i]);
        and (p18_inter[i], A[18], B[i]);
        and (p19_inter[i], A[19], B[i]);
        and (p20_inter[i], A[20], B[i]);
        and (p21_inter[i], A[21], B[i]);
        and (p22_inter[i], A[22], B[i]);
        and (p23_inter[i], A[23], B[i]);
        and (p24_inter[i], A[24], B[i]);
        and (p25_inter[i], A[25], B[i]);
        and (p26_inter[i], A[26], B[i]);
        and (p27_inter[i], A[27], B[i]);
        and (p28_inter[i], A[28], B[i]);
        and (p29_inter[i], A[29], B[i]);
        and (p30_inter[i], A[30], B[i]);
        and (p31_inter[i], A[31], B[i]);
    end
endgenerate

wire [31:0] p0_lsb = p0_inter;

wire [31:0] p1_lsb = {p1_inter[30:0],  1'b0};
wire [31:0] p1_msb = {31'b0, p1_inter[31]};

wire [31:0] p2_lsb = {p2_inter[29:0],  2'b0};
wire [31:0] p2_msb = {30'b0, p2_inter[31:30]};

wire [31:0] p3_lsb = {p3_inter[28:0],  3'b0};
wire [31:0] p3_msb = {29'b0, p3_inter[31:29]};

wire [31:0] p4_lsb = {p4_inter[27:0],  4'b0};
wire [31:0] p4_msb = {28'b0, p4_inter[31:28]};

wire [31:0] p5_lsb = {p5_inter[26:0],  5'b0};
wire [31:0] p5_msb = {27'b0, p5_inter[31:27]};

wire [31:0] p6_lsb = {p6_inter[25:0],  6'b0};
wire [31:0] p6_msb = {26'b0, p6_inter[31:26]};

wire [31:0] p7_lsb = {p7_inter[24:0],  7'b0};
wire [31:0] p7_msb = {25'b0, p7_inter[31:25]};

wire [31:0] p8_lsb = {p8_inter[23:0],  8'b0};
wire [31:0] p8_msb = {24'b0, p8_inter[31:24]};

wire [31:0] p9_lsb  = {p9_inter[22:0],  9'b0};
wire [31:0] p9_msb  = {23'b0, p9_inter[31:23]};

wire [31:0] p10_lsb = {p10_inter[21:0], 10'b0};
wire [31:0] p10_msb = {22'b0, p10_inter[31:22]};

wire [31:0] p11_lsb = {p11_inter[20:0], 11'b0};
wire [31:0] p11_msb = {21'b0, p11_inter[31:21]};

wire [31:0] p12_lsb = {p12_inter[19:0], 12'b0};
wire [31:0] p12_msb = {20'b0, p12_inter[31:20]};

wire [31:0] p13_lsb = {p13_inter[18:0], 13'b0};
wire [31:0] p13_msb = {19'b0, p13_inter[31:19]};

wire [31:0] p14_lsb = {p14_inter[17:0], 14'b0};
wire [31:0] p14_msb = {18'b0, p14_inter[31:18]};

wire [31:0] p15_lsb = {p15_inter[16:0], 15'b0};
wire [31:0] p15_msb = {17'b0, p15_inter[31:17]};

wire [31:0] p16_lsb = {p16_inter[15:0], 16'b0};
wire [31:0] p16_msb = {16'b0, p16_inter[31:16]};

wire [31:0] p17_lsb = {p17_inter[14:0], 17'b0};
wire [31:0] p17_msb = {15'b0, p17_inter[31:15]};

wire [31:0] p18_lsb = {p18_inter[13:0], 18'b0};
wire [31:0] p18_msb = {14'b0, p18_inter[31:14]};

wire [31:0] p19_lsb = {p19_inter[12:0], 19'b0};
wire [31:0] p19_msb = {13'b0, p19_inter[31:13]};

wire [31:0] p20_lsb = {p20_inter[11:0], 20'b0};
wire [31:0] p20_msb = {12'b0, p20_inter[31:12]};

wire [31:0] p21_lsb = {p21_inter[10:0], 21'b0};
wire [31:0] p21_msb = {11'b0, p21_inter[31:11]};

wire [31:0] p22_lsb = {p22_inter[9:0],  22'b0};
wire [31:0] p22_msb = {10'b0, p22_inter[31:10]};

wire [31:0] p23_lsb = {p23_inter[8:0],  23'b0};
wire [31:0] p23_msb = {9'b0, p23_inter[31:9]};

wire [31:0] p24_lsb = {p24_inter[7:0],  24'b0};
wire [31:0] p24_msb = {8'b0, p24_inter[31:8]};

wire [31:0] p25_lsb = {p25_inter[6:0],  25'b0};
wire [31:0] p25_msb = {7'b0, p25_inter[31:7]};

wire [31:0] p26_lsb = {p26_inter[5:0],  26'b0};
wire [31:0] p26_msb = {6'b0, p26_inter[31:6]};

wire [31:0] p27_lsb = {p27_inter[4:0],  27'b0};
wire [31:0] p27_msb = {5'b0, p27_inter[31:5]};

wire [31:0] p28_lsb = {p28_inter[3:0],  28'b0};
wire [31:0] p28_msb = {4'b0, p28_inter[31:4]};

wire [31:0] p29_lsb = {p29_inter[2:0],  29'b0};
wire [31:0] p29_msb = {3'b0, p29_inter[31:3]};

wire [31:0] p30_lsb = {p30_inter[1:0],  30'b0};
wire [31:0] p30_msb = {2'b0, p30_inter[31:2]};

wire [31:0] p31_lsb = {p31_inter[0],    31'b0};
wire [31:0] p31_msb = {1'b0, p31_inter[31:1]};

// Right Side
// Layer 0
wire c0_0;
wire [31:0] sum_0_0;
adder(.A(p0_lsb), .B(p1_lsb), .Cin(1'b0), .S(sum_0_0), .Cout(c0_0));

wire c1_0;
wire [31:0] sum_1_0;
adder(.A(p2_lsb), .B(p3_lsb), .Cin(1'b0), .S(sum_1_0), .Cout(c1_0));

wire c2_0;
wire [31:0] sum_2_0;
adder(.A(p4_lsb), .B(p5_lsb), .Cin(1'b0), .S(sum_2_0), .Cout(c2_0));

wire c3_0;
wire [31:0] sum_3_0;
adder(.A(p6_lsb), .B(p7_lsb), .Cin(1'b0), .S(sum_3_0), .Cout(c3_0));

wire c4_0;
wire [31:0] sum_4_0;
adder(.A(p8_lsb),  .B(p9_lsb),  .Cin(1'b0), .S(sum_4_0),  .Cout(c4_0));

wire c5_0;
wire [31:0] sum_5_0;
adder(.A(p10_lsb), .B(p11_lsb), .Cin(1'b0), .S(sum_5_0), .Cout(c5_0));

wire c6_0;
wire [31:0] sum_6_0;
adder(.A(p12_lsb), .B(p13_lsb), .Cin(1'b0), .S(sum_6_0), .Cout(c6_0));

wire c7_0;
wire [31:0] sum_7_0;
adder(.A(p14_lsb), .B(p15_lsb), .Cin(1'b0), .S(sum_7_0), .Cout(c7_0));

wire c8_0;
wire [31:0] sum_8_0;
adder(.A(p16_lsb), .B(p17_lsb), .Cin(1'b0), .S(sum_8_0), .Cout(c8_0));

wire c9_0;
wire [31:0] sum_9_0;
adder(.A(p18_lsb), .B(p19_lsb), .Cin(1'b0), .S(sum_9_0), .Cout(c9_0));

wire c10_0;
wire [31:0] sum_10_0;
adder(.A(p20_lsb), .B(p21_lsb), .Cin(1'b0), .S(sum_10_0), .Cout(c10_0));

wire c11_0;
wire [31:0] sum_11_0;
adder(.A(p22_lsb), .B(p23_lsb), .Cin(1'b0), .S(sum_11_0), .Cout(c11_0));

wire c12_0;
wire [31:0] sum_12_0;
adder(.A(p24_lsb), .B(p25_lsb), .Cin(1'b0), .S(sum_12_0), .Cout(c12_0));

wire c13_0;
wire [31:0] sum_13_0;
adder(.A(p26_lsb), .B(p27_lsb), .Cin(1'b0), .S(sum_13_0), .Cout(c13_0));

wire c14_0;
wire [31:0] sum_14_0;
adder(.A(p28_lsb), .B(p29_lsb), .Cin(1'b0), .S(sum_14_0), .Cout(c14_0));

wire c15_0;
wire [31:0] sum_15_0;
adder(.A(p30_lsb), .B(p31_lsb), .Cin(1'b0), .S(sum_15_0), .Cout(c15_0));

//Layer 1
wire c_0_1;
wire [31:0] sum_0_1;
adder(.A(sum_0_0), .B(sum_1_0), .Cin(1'b0), .S(sum_0_1), .Cout(c_0_1));

wire c_1_1;
wire [31:0] sum_1_1;
adder(.A(sum_2_0), .B(sum_3_0), .Cin(1'b0), .S(sum_1_1), .Cout(c_1_1));

wire c_2_1;
wire [31:0] sum_2_1;
adder(.A(sum_4_0), .B(sum_5_0), .Cin(1'b0), .S(sum_2_1), .Cout(c_2_1));

wire c_3_1;
wire [31:0] sum_3_1;
adder(.A(sum_6_0), .B(sum_7_0), .Cin(1'b0), .S(sum_3_1), .Cout(c_3_1));

wire c_4_1;
wire [31:0] sum_4_1;
adder(.A(sum_8_0), .B(sum_9_0), .Cin(1'b0), .S(sum_4_1), .Cout(c_4_1));

wire c_5_1;
wire [31:0] sum_5_1;
adder(.A(sum_10_0), .B(sum_11_0), .Cin(1'b0), .S(sum_5_1), .Cout(c_5_1));

wire c_6_1;
wire [31:0] sum_6_1;
adder(.A(sum_12_0), .B(sum_13_0), .Cin(1'b0), .S(sum_6_1), .Cout(c_6_1));

wire c_7_1;
wire [31:0] sum_7_1;
adder(.A(sum_14_0), .B(sum_15_0), .Cin(1'b0), .S(sum_7_1), .Cout(c_7_1));

//Layer 2
wire c_0_2;
wire [31:0] sum_0_2;
adder(.A(sum_0_1), .B(sum_1_1), .Cin(1'b0), .S(sum_0_2), .Cout(c_0_2));

wire c_1_2;
wire [31:0] sum_1_2;
adder(.A(sum_2_1), .B(sum_3_1), .Cin(1'b0), .S(sum_1_2), .Cout(c_1_2));

wire c_2_2;
wire [31:0] sum_2_2;
adder(.A(sum_4_1), .B(sum_5_1), .Cin(1'b0), .S(sum_2_2), .Cout(c_2_2));

wire c_3_2;
wire [31:0] sum_3_2;
adder(.A(sum_6_1), .B(sum_7_1), .Cin(1'b0), .S(sum_3_2), .Cout(c_3_2));

//Layer 3
wire c_0_3;
wire [31:0] sum_0_3;
adder(.A(sum_0_2), .B(sum_1_2), .Cin(1'b0), .S(sum_0_3), .Cout(c_0_3));

wire c_1_3;
wire [31:0] sum_1_3;
adder(.A(sum_2_2), .B(sum_3_2), .Cin(1'b0), .S(sum_1_3), .Cout(c_1_3));

//Layer 4
wire c_0_4;
wire [31:0] sum_lsb;
adder(.A(sum_0_3), .B(sum_1_3), .Cin(1'b0), .S(sum_lsb), .Cout(c_0_4));



//Left Side
//Layer 0
wire [31:0] sum_0_0_M;
adder(.A(p1_msb), .B(p2_msb), .Cin(1'b0), .S(sum_0_0_M));

wire [31:0] sum_1_0_M;
adder(.A(p3_msb), .B(p4_msb), .Cin(1'b0), .S(sum_1_0_M));

wire [31:0] sum_2_0_M;
adder(.A(p5_msb), .B(p6_msb), .Cin(1'b0), .S(sum_2_0_M));

wire [31:0] sum_3_0_M;
adder(.A(p7_msb), .B(p8_msb), .Cin(1'b0), .S(sum_3_0_M));

wire [31:0] sum_4_0_M;
adder(.A(p9_msb),  .B(p10_msb), .Cin(1'b0), .S(sum_4_0_M));

wire [31:0] sum_5_0_M;
adder(.A(p11_msb), .B(p12_msb), .Cin(1'b0), .S(sum_5_0_M));

wire [31:0] sum_6_0_M;
adder(.A(p13_msb), .B(p14_msb), .Cin(1'b0), .S(sum_6_0_M));

wire [31:0] sum_7_0_M;
adder(.A(p15_msb), .B(p16_msb), .Cin(1'b0), .S(sum_7_0_M));

wire [31:0] sum_8_0_M;
adder(.A(p17_msb), .B(p18_msb), .Cin(1'b0), .S(sum_8_0_M));

wire [31:0] sum_9_0_M;
adder(.A(p19_msb), .B(p20_msb), .Cin(1'b0), .S(sum_9_0_M));

wire [31:0] sum_10_0_M;
adder(.A(p21_msb), .B(p22_msb), .Cin(1'b0), .S(sum_10_0_M));

wire [31:0] sum_11_0_M;
adder(.A(p23_msb), .B(p24_msb), .Cin(1'b0), .S(sum_11_0_M));

wire [31:0] sum_12_0_M;
adder(.A(p25_msb), .B(p26_msb), .Cin(1'b0), .S(sum_12_0_M));

wire [31:0] sum_13_0_M;
adder(.A(p27_msb), .B(p28_msb), .Cin(1'b0), .S(sum_13_0_M));

wire [31:0] sum_14_0_M;
adder(.A(p29_msb), .B(p30_msb), .Cin(1'b0), .S(sum_14_0_M));

wire [31:0] sum_15_0_M = p31_msb;

//Layer 1
wire [31:0] sum_0_1_M;
adder(.A(sum_0_0_M), .B(sum_1_0_M), .Cin(1'b0), .S(sum_0_1_M));

wire [31:0] sum_1_1_M;
adder(.A(sum_2_0_M), .B(sum_3_0_M), .Cin(1'b0), .S(sum_1_1_M));

wire [31:0] sum_2_1_M;
adder(.A(sum_4_0_M), .B(sum_5_0_M), .Cin(1'b0), .S(sum_2_1_M));

wire [31:0] sum_3_1_M;
adder(.A(sum_6_0_M), .B(sum_7_0_M), .Cin(1'b0), .S(sum_3_1_M));

wire [31:0] sum_4_1_M;
adder(.A(sum_8_0_M), .B(sum_9_0_M), .Cin(1'b0), .S(sum_4_1_M));

wire [31:0] sum_5_1_M;
adder(.A(sum_10_0_M), .B(sum_11_0_M), .Cin(1'b0), .S(sum_5_1_M));

wire [31:0] sum_6_1_M;
adder(.A(sum_12_0_M), .B(sum_13_0_M), .Cin(1'b0), .S(sum_6_1_M));

wire [31:0] sum_7_1_M;
adder(.A(sum_14_0_M), .B(sum_15_0_M), .Cin(1'b0), .S(sum_7_1_M));

//Layer 2
wire [31:0] sum_0_2_M;
adder(.A(sum_0_1_M), .B(sum_1_1_M), .Cin(1'b0), .S(sum_0_2_M));

wire [31:0] sum_1_2_M;
adder(.A(sum_2_1_M), .B(sum_3_1_M), .Cin(1'b0), .S(sum_1_2_M));

wire [31:0] sum_2_2_M;
adder(.A(sum_4_1_M), .B(sum_5_1_M), .Cin(1'b0), .S(sum_2_2_M));

wire [31:0] sum_3_2_M;
adder(.A(sum_6_1_M), .B(sum_7_1_M), .Cin(1'b0), .S(sum_3_2_M));

//Layer 3
wire [31:0] sum_0_3_M;
adder(.A(sum_0_2_M), .B(sum_1_2_M), .Cin(1'b0), .S(sum_0_3_M));

wire [31:0] sum_1_3_M;
adder(.A(sum_2_2_M), .B(sum_3_2_M), .Cin(1'b0), .S(sum_1_3_M));

//Layer 4
wire [31:0] sum_0_4_M;
adder(.A(sum_0_3_M), .B(sum_1_3_M), .Cin(1'b0), .S(sum_0_4_M));

//Carry Bits
//Bit 0
//Layer 0
wire b0_0_0_0;
wire b0_0_0_1;
full_adder(.A(c0_0), .B(c1_0), .Cin(c2_0), .Sum(b0_0_0_0), .Cout(b0_0_0_1));

wire b0_0_1_0;
wire b0_0_1_1;
full_adder(.A(c3_0), .B(c4_0), .Cin(c5_0), .Sum(b0_0_1_0), .Cout(b0_0_1_1));

wire b0_0_2_0;
wire b0_0_2_1;
full_adder(.A(c6_0), .B(c7_0), .Cin(c8_0), .Sum(b0_0_2_0), .Cout(b0_0_2_1));

wire b0_0_3_0;
wire b0_0_3_1;
full_adder(.A(c9_0), .B(c10_0), .Cin(c11_0), .Sum(b0_0_3_0), .Cout(b0_0_3_1));

wire b0_0_4_0;
wire b0_0_4_1;
full_adder(.A(c12_0), .B(c13_0), .Cin(c14_0), .Sum(b0_0_4_0), .Cout(b0_0_4_1));

//Layer 1
wire b0_1_0_0;
wire b0_1_0_1;
full_adder(.A(b0_0_0_0), .B(b0_0_1_0), .Cin(b0_0_2_0), .Sum(b0_1_0_0), .Cout(b0_1_0_1));

wire b0_1_1_0;
wire b0_1_1_1;
full_adder(.A(b0_0_3_0), .B(b0_0_4_0), .Cin(1'b0), .Sum(b0_1_1_0), .Cout(b0_1_1_1));

//Layer 2
wire b0_2_0_0;
wire b0_2_0_1;
full_adder(.A(b0_1_0_0), .B(b0_1_1_0), .Cin(1'b0), .Sum(b0_2_0_0), .Cout(b0_2_0_1));

//Bit 1
//Layer 0
wire b1_0_0_0;
wire b1_0_0_1;
full_adder(.A(b0_0_0_1), .B(b0_0_1_1), .Cin(b0_0_2_1), .Sum(b1_0_0_0), .Cout(b1_0_0_1));

wire b1_0_1_0;
wire b1_0_1_1;
full_adder(.A(b0_0_3_1), .B(b0_0_4_1), .Cin(b0_1_0_1), .Sum(b1_0_1_0), .Cout(b1_0_1_1));

wire b1_0_2_0;
wire b1_0_2_1;
full_adder(.A(b0_1_1_1), .B(b0_2_0_1), .Cin(1'b0), .Sum(b1_0_2_0), .Cout(b1_0_2_1));

//Layer 1
wire b1_1_0_0;
wire b1_1_0_1;
full_adder(.A(b1_0_0_0), .B(b1_0_1_0), .Cin(b1_0_2_0), .Sum(b1_1_0_0), .Cout(b1_1_0_1));

//Bit 2
//Layer 0
wire b2_0_0_0;
wire b2_0_0_1;
full_adder(.A(b1_0_0_1), .B(b1_0_1_1), .Cin(b1_0_2_1), .Sum(b2_0_0_0), .Cout(b2_0_0_1));

//Layer 1
wire b2_0_1_0;
wire b2_0_1_1;
full_adder(.A(b2_0_0_0), .B(b1_1_0_1), .Cin(1'b0), .Sum(b2_0_1_0), .Cout(b2_0_1_1));

//Bit 3
wire b3_0_0_0;
wire b3_0_0_1;
full_adder(.A(b2_0_0_1), .B(b2_0_1_1), .Cin(1'b0), .Sum(b3_0_0_0), .Cout(b3_0_0_1));

wire [31:0] carry_wire = {27'b0, b3_0_0_1, b3_0_0_0, b2_0_1_0, b1_1_0_0, b0_2_0_0};

wire [31:0] sum_msb;
adder(.A(sum_0_4_M), .B(carry_wire), .Cin(1'b0), .S(sum_msb));

wire [63:0] a_sign_correction;

generate
    for (i = 0; i < 32; i = i + 1) begin : gen_a_sign
        assign a_sign_correction[i]     = 1'b0;           // lower 32 bits are 0 because shifted left 32
        assign a_sign_correction[i+32] = A[31] & B[i];    // upper 32 bits
    end
endgenerate

wire [63:0] b_sign_correction;
generate
    for (i = 0; i < 32; i = i + 1) begin : gen_b_sign
        assign b_sign_correction[i]     = 1'b0;           // lower 32 bits are 0 because shifted left 32
        assign b_sign_correction[i+32] = B[31] & A[i];    // upper 32 bits
    end
endgenerate

wire [63:0] correction_sum;
wire carry_out_correction;
wire inter_carry;

adder(.A(a_sign_correction[31:0]), .B(b_sign_correction[31:0]), .Cin(1'b0), .S(correction_sum[31:0]), .Cout(inter_carry));
adder(.A(a_sign_correction[63:32]), .B(b_sign_correction[63:32]), .Cin(inter_carry), .S(correction_sum[63:32]), .Cout(carry_out_correction));

wire [63:0] unsigned_product = {sum_msb, sum_lsb};
wire [63:0] full_product_signed;
wire carry_out_final;

// LSB addition (lower 32 bits)
wire [31:0] full_lsb;
wire cout_lsb;

adder add_lsb (
    .A(sum_lsb),
    .B(correction_sum[31:0]),
    .Cin(1'b0),
    .S(full_lsb),
    .Cout(cout_lsb)
);

// MSB addition (upper 32 bits)
wire [31:0] full_msb;

adder add_msb (
    .A(sum_msb),
    .B(correction_sum[63:32]),
    .Cin(cout_lsb),
    .S(full_msb),
    .Cout(carry_out_final)
);

assign full_product_signed = {full_msb, full_lsb};

// For HSU

wire [31:0] hsu_lsb;
wire cout_hsu;
wire carry_out_final_hsu;

adder(
    .A(sum_lsb),
    .B(a_sign_correction[31:0]),
    .Cin(1'b0),
    .S(hsu_lsb),
    .Cout(cout_hsu)
);

// MSB addition (upper 32 bits)
wire [31:0] hsu_msb;

adder(
    .A(sum_msb),
    .B(a_sign_correction[63:32]),
    .Cin(cout_hsu),
    .S(hsu_msb),
    .Cout(carry_out_final_hsu)
);

assign MULoutput = sum_lsb;
assign MULHoutput = full_msb;
assign MULHSUoutput = hsu_msb;
assign MULHUoutput = sum_msb;
   
endmodule
