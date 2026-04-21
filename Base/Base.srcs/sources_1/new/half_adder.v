`timescale 1ns / 1ps

module half_adder(
    input A,
    input B,
    output Sum,
    output Carry
    );
    
xor2$ x1 (Sum, A, B);
and2$ a1 (Carry, A, B); 
    
endmodule