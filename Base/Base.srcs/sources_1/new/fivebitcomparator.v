`timescale 1ns / 1ps

module fivebitcomparator(
    input [4:0] A,
    input [4:0] B, 
    output equal      
    );
wire four, three, two, one, zero;

xnor(four, A[4], B[4]);  
xnor(three, A[3], B[3]);  
xnor(two, A[2], B[2]);  
xnor(one, A[1], B[1]);  
xnor(zero, A[0], B[0]);  
and(equal, four, three, two, one, zero);
    
endmodule
