`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/25/2026 08:28:28 PM
// Design Name: 
// Module Name: addressgen_tb
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


module addressgen_tb(

    );
    
    reg [31:0] x, y, vert, hor, ptr;
    wire [31:0] addr1, addr2, addr3;
    
    initial begin
        x = 0;
        y = 0;
        hor = 32'h1;
        vert = 32'h100;
        ptr = 32'h1000;
        #10
        x = 1;
        #10
        y = 1;
        #10
        x = 2;
        y = 7;
        #100
        x = 0;
        y = 0;
        hor = 32'h4;
        vert = 32'h1;
        ptr = 32'h1000;
        #10
        x = 1;
        #10
        y = 1;
        #10
        x = 2;
        y = 7;
    end
    
    addressgen a1 (x, y, vert, hor, ptr, addr1);
    addressgen a2 (x, y+1, vert, hor, ptr, addr2);
    addressgen a3 (x, y+2, vert, hor, ptr, addr3);
    
endmodule