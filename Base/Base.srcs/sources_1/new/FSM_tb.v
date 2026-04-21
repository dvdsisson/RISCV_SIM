`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/26/2026 04:21:27 AM
// Design Name: 
// Module Name: FSM_tb
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


module FSM_tb(

    );
    
    reg clk = 0;
    
    always #10 clk = ~clk;
    
    reg isFC, clk, start, ready;
    reg [31:0] max_x, max_y, linesize, pxl_ptr, ker_ptr, bias_ptr, weight_ptr, out_ptr, max_ch; 
    wire reset, fc_write, r3write, conv_compute;
    wire [31:0] mem_ptr;
    wire [1:0] banksel, colsel, regse;
    wire done, mem_req;

    FSMController FSM1 (isFC, clk, start, ready, max_x, max_y, linesize, pxl_ptr, ker_ptr, bias_ptr, weight_ptr, out_ptr, max_ch);
    
    
    reg [31:0] ptr = 32'h1000;
    wire [31:0] addr1, addr2, addr3, addr4;
    
    addressgen a1 (x, y, vert, hor, ptr, addr1);
    addressgen a2 (x, y+1, vert, hor, ptr, addr2);
    addressgen a3 (x, y+2, vert, hor, ptr, addr3);
    addressgen a4 (x, y+3, vert, hor, ptr, addr4);
    
    
    initial begin
        start = 1;
        max_x = 8;
        max_y = 2;
        ready = 0;
        isFC = 1;
        
        #50
        start = 1;
        ready  = 1;
        #5
        ready = 0;
        #25
        ready = 1;
        
        
    
    end
    
endmodule