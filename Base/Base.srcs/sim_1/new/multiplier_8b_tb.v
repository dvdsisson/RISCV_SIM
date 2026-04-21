`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/07/2026 12:21:18 PM
// Design Name: 
// Module Name: multiplier_8b_tb
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


module multiplier_8b_tb(

    );
    
    
    reg [7:0] a, b, i, j;
    wire [15:0] out;
    reg [15:0] next, next_corr;
    multiplier_8b mult (a,b,out);
    
    wire [15:0] multiplied;
    assign multiplied = a * b;
    
    wire correct;
    assign correct = (next == next_corr); 
    
    wire [15:0] diff;
    assign diff = next ^ next_corr;
    
    
    
    initial begin
        for (i=0; i<8'hFF; i=i+1) begin
            for (j=0; j<8'hFF; j=j+1) begin
                a = 8'h0;
                b = 8'h0;
                #(6)
                a = i;
                b = j;
                #(5.39)
                next = out;
                next_corr = multiplied;
            end
        end
        $finish;
    end
    

endmodule
