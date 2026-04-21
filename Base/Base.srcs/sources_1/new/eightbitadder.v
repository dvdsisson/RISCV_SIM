`timescale 1ns / 1ps

module eightbitadder(
    input [7:0] A,
    input [7:0] B,
    input Cin,
    output [7:0] S,
    output Cout
    );  
    
wire [7:0] G, P;
wire C1, C2, C3, C4, C5, C6, C7;

and2$ a1 (G[0], A[0], B[0]);
and2$ a2 (G[1], A[1], B[1]);
and2$ a3 (G[2], A[2], B[2]);
and2$ a4 (G[3], A[3], B[3]);
and2$ a5 (G[4], A[4], B[4]);
and2$ a6 (G[5], A[5], B[5]);
and2$ a7 (G[6], A[6], B[6]);
and2$ a8 (G[7], A[7], B[7]);

xor2$ x1 (P[0], A[0], B[0]);
xor2$ x2 (P[1], A[1], B[1]);
xor2$ x3 (P[2], A[2], B[2]);
xor2$ x4 (P[3], A[3], B[3]);
xor2$ x5 (P[4], A[4], B[4]);
xor2$ x6 (P[5], A[5], B[5]);
xor2$ x7 (P[6], A[6], B[6]);
xor2$ x8 (P[7], A[7], B[7]);

wire i1, i2, i3, i4, i5, i6, i7, i8, i9, i10;
wire i11, i12, i13, i14, i15, i16, i17, i18, i19, i20, i21;
wire i22, i23, i24, i25, i26, i27, i28;
wire i29, i30, i31, i32, i33, i34, i35, i36;

and2$ a9 (i1, P[0], Cin);
or2$ o1  (C1, G[0], i1);

and2$ a10 (i2, P[1], G[0]);
and3$ a11 (i3, P[1], P[0], Cin);
or3$ o2   (C2, G[1], i2,   i3);

and2$ a12 (i4, P[2], G[1]);
and3$ a13 (i5, P[2], P[1], G[0]);
and4$ a14 (i6, P[2], P[1], P[0], Cin);
or4$ o3   (C3, G[2], i4,   i5,   i6);

and2$ a15 (i7,  P[3], G[2]);
and3$ a16 (i8,  P[3], P[2], G[1]);
and4$ a17 (i9,  P[3], P[2], P[1], G[0]);
and5 a18  (i10, P[3], P[2], P[1], P[0], Cin);
or5 o4    (C4,  G[3], i7,   i8,   i9,   i10);

and2$ a19 (i11, P[4], G[3]);
and3$ a20 (i12, P[4], P[3], G[2]);
and4$ a21 (i13, P[4], P[3], P[2], G[1]);
and5 a22  (i14, P[4], P[3], P[2], P[1], G[0]);
and6 a23  (i15, P[4], P[3], P[2], P[1], P[0], Cin);
or6 o5    (C5,  G[4], i11,  i12,  i13,  i14,  i15);

and2$ a24 (i16, P[5], G[4]);
and3$ a25 (i17, P[5], P[4], G[3]);
and4$ a26 (i18, P[5], P[4], P[3], G[2]);
and5 a27  (i19, P[5], P[4], P[3], P[2], G[1]);
and6 a28  (i20, P[5], P[4], P[3], P[2], P[1], G[0]);
and7 a29  (i21, P[5], P[4], P[3], P[2], P[1], P[0], Cin);
or7 o6    (C6,  G[5], i16,  i17,  i18,  i19,  i20,  i21);

and2$ a30 (i22, P[6], G[5]);
and3$ a31 (i23, P[6], P[5], G[4]);
and4$ a32 (i24, P[6], P[5], P[4], G[3]);
and5 a33  (i25, P[6], P[5], P[4], P[3], G[2]);
and6 a34  (i26, P[6], P[5], P[4], P[3], P[2], G[1]);
and7 a35  (i27, P[6], P[5], P[4], P[3], P[2], P[1], G[0]);
and8 a36  (i28, P[6], P[5], P[4], P[3], P[2], P[1], P[0], Cin);
or8 o7    (C7,  G[6], i22,  i23,  i24,  i25,  i26,  i27,  i28);

and2$ a37 (i29,  P[7], G[6]);
and3$ a38 (i30,  P[7], P[6], G[5]);
and4$ a39 (i31,  P[7], P[6], P[5], G[4]);
and5 a40  (i32,  P[7], P[6], P[5], P[4], G[3]);
and6 a41  (i33,  P[7], P[6], P[5], P[4], P[3], G[2]);
and7 a42  (i34,  P[7], P[6], P[5], P[4], P[3], P[2], G[1]);
and8 a43  (i35,  P[7], P[6], P[5], P[4], P[3], P[2], P[1], G[0]);
and9 a44  (i36,  P[7], P[6], P[5], P[4], P[3], P[2], P[1], P[0], Cin);
or9 o8    (Cout, G[7], i29,  i30,  i31,  i32,  i33,  i34,  i35,  i36);

xor2$ x9  (S[0], P[0], Cin);
xor2$ x10 (S[1], P[1], C1);
xor2$ x11 (S[2], P[2], C2);
xor2$ x12 (S[3], P[3], C3);
xor2$ x13 (S[4], P[4], C4);
xor2$ x14 (S[5], P[5], C5);
xor2$ x15 (S[6], P[6], C6);
xor2$ x16 (S[7], P[7], C7);

wire [7:0] C;
assign C = {C7, C6, C5, C4, C3, C2, C1, Cin};

endmodule
