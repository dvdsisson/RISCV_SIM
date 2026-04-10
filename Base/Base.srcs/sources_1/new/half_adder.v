`timescale 1ns / 1ps

module half_adder(
    input A,
    input B,
    output Sum,
    output Carry
    );
    
xor(Sum, A, B);
and(Carry, A, B); 
    
endmodule