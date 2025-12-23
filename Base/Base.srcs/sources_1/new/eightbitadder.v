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

and(G[0], A[0], B[0]);
and(G[1], A[1], B[1]);
and(G[2], A[2], B[2]);
and(G[3], A[3], B[3]);
and(G[4], A[4], B[4]);
and(G[5], A[5], B[5]);
and(G[6], A[6], B[6]);
and(G[7], A[7], B[7]);

xor(P[0], A[0], B[0]);
xor(P[1], A[1], B[1]);
xor(P[2], A[2], B[2]);
xor(P[3], A[3], B[3]);
xor(P[4], A[4], B[4]);
xor(P[5], A[5], B[5]);
xor(P[6], A[6], B[6]);
xor(P[7], A[7], B[7]);

wire i1, i2, i3, i4, i5, i6, i7, i8, i9, i10;
wire i11, i12, i13, i14, i15, i16, i17, i18, i19, i20, i21;
wire i22, i23, i24, i25, i26, i27, i28;
wire i29, i30, i31, i32, i33, i34, i35, i36;

and(i1, P[0], Cin);
or(C1, G[0], i1);

and(i2, P[1], G[0]);
and(i3, P[1], P[0], Cin);
or(C2, G[1], i2, i3);

and(i4, P[2], G[1]);
and(i5, P[2], P[1], G[0]);
and(i6, P[2], P[1], P[0], Cin);
or(C3, G[2], i4, i5, i6);

and(i7, P[3], G[2]);
and(i8, P[3], P[2], G[1]);
and(i9, P[3], P[2], P[1], G[0]);
and(i10, P[3], P[2], P[1], P[0], Cin);
or(C4, G[3], i7, i8, i9, i10);

and(i11, P[4], G[3]);
and(i12, P[4], P[3], G[2]);
and(i13, P[4], P[3], P[2], G[1]);
and(i14, P[4], P[3], P[2], P[1], G[0]);
and(i15, P[4], P[3], P[2], P[1], P[0], Cin);
or(C5, G[4], i11, i12, i13, i14, i15);

and(i16, P[5], G[4]);
and(i17, P[5], P[4], G[3]);
and(i18, P[5], P[4], P[3], G[2]);
and(i19, P[5], P[4], P[3], P[2], G[1]);
and(i20, P[5], P[4], P[3], P[2], P[1], G[0]);
and(i21, P[5], P[4], P[3], P[2], P[1], P[0], Cin);
or(C6, G[5], i16, i17, i18, i19, i20, i21);

and(i22, P[6], G[5]);
and(i23, P[6], P[5], G[4]);
and(i24, P[6], P[5], P[4], G[3]);
and(i25, P[6], P[5], P[4], P[3], G[2]);
and(i26, P[6], P[5], P[4], P[3], P[2], G[1]);
and(i27, P[6], P[5], P[4], P[3], P[2], P[1], G[0]);
and(i28, P[6], P[5], P[4], P[3], P[2], P[1], P[0], Cin);
or(C7, G[6], i22, i23, i24, i25, i26, i27, i28);

and(i29, P[7], G[6]);
and(i30, P[7], P[6], G[5]);
and(i31, P[7], P[6], P[5], G[4]);
and(i32, P[7], P[6], P[5], P[4], G[3]);
and(i33, P[7], P[6], P[5], P[4], P[3], G[2]);
and(i34, P[7], P[6], P[5], P[4], P[3], P[2], G[1]);
and(i35, P[7], P[6], P[5], P[4], P[3], P[2], P[1], G[0]);
and(i36, P[7], P[6], P[5], P[4], P[3], P[2], P[1], P[0], Cin);
or(Cout, G[7], i29, i30, i31, i32, i33, i34, i35, i36);

xor(S[0], P[0], Cin);
xor(S[1], P[1], C1);
xor(S[2], P[2], C2);
xor(S[3], P[3], C3);
xor(S[4], P[4], C4);
xor(S[5], P[5], C5);
xor(S[6], P[6], C6);
xor(S[7], P[7], C7);

endmodule
