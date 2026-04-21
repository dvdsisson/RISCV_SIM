`timescale 1ns / 1ps

module full_adder(
    input A,
    input B,
    input Cin,
    output Sum,
    output Cout
    );
    
wire inter_s;
xor2$ x1 (inter_s, A, B);
xor2$ x2 (Sum, inter_s, Cin);
    
wire a_1;
and2$ a1 (a_1, A, B);
    
wire a_2;
and2$ a2 (a_2, inter_s, Cin);
    
or2$ o1 (Cout, a_1, a_2);
    
endmodule