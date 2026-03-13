`timescale 1ns / 1ps

module full_adder(
    input A,
    input B,
    input Cin,
    output Sum,
    output Cout
    );
    
wire inter_s;
xor(inter_s, A, B);
xor(Sum, inter_s, Cin);
    
wire a_1;
and(a_1, A, B);
    
wire a_2;
and(a_2, inter_s, Cin);
    
or(Cout, a_1, a_2);
    
endmodule