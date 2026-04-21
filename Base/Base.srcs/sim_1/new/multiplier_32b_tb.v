`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/17/2026 09:13:05 PM
// Design Name: 
// Module Name: multiplier_32b_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module multiplier_32b_tb(

    );
    
    parameter period = 10;
    
    reg [31:0] a, b, i, j, next, next_corr;
    
    wire [31:0] out, correct;
    
    reg cin;
    
    wire match;
    
    multiplier_32b mult (a, b);
    
    assign correct = i+j;
    assign match = next == next_corr;
    
    initial begin
        a = 0;
        b=0;
        cin=0;
        #(period)
        a = 1;
        b=-1;
        cin = 1;
        #(period)
        a = 0;
        b=0;
        #(period)
//        for (a=0; a<32'hFFFFFFFF; a=a+1) begin
//            for (b=0; b<32'hFFFFFFFF; b=b+1) begin                
//                i=0;
//                j=0;
//                #(period/2.0);
//                i=a;
//                j=b;e
//                #(period/2.0);
//                next = out;
//                next_corr = correct;
                
//            end
//        end 
        $finish;
    end
    
endmodule
