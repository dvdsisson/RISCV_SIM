`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/26/2026 09:47:06 AM
// Design Name: 
// Module Name: fc_bias_tb
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


module fc_bias_tb(

    );

    reg clk = 0;
    always #10 clk = ~clk;

    reg isFC, isConv, write, banksel, start;
    reg [1:0] regsel;
    reg [31:0] data; 
    wire r3write;
    wire [31:0] out;
    reg ready = 0;
    
    
    reg [31:0] max_x = 8;
    reg [31:0] max_y = 8;
    
    reg [31:0] linesize = 8;
    reg [31:0] pxl_ptr, ker_ptr, bias_ptr, weight_ptr, out_ptr, max_ch;
    
    
    
    wire reset;
    
    wire fc_write, r3write, conv_computer, done, mem_req;
    
    wire [31:0] mem_ptr;
    wire [1:0] banksel, colsel, regsel;
    
    fc_conv_bias fcblock (clk, start, ready, isFC, isConv, data, pxl_ptr, ker_ptr, bias_ptr, weight_ptr, out_ptr, max_x, max_y, linesize, max_ch);
    initial begin
        max_ch = 1;
        isFC = 1;
        isConv = 1;
        write = 0;
//        banksel = 0;
//        regsel = 0;
        #40
        start = 1;
//        banksel = 0;
//        regsel = 0;
        data = 32'h100;
        #20
        start = 0;
//        banksel = 1;
//        regsel = 2;
//        data = 32'h300;
        #20
          ready = 1;
        
//        banksel = 0;
//        regsel = 2;
//        data = 32'h410;
        #20
//        banksel = 1;
//        regsel = 3;
//        data = 32'h502;
        #20
//        banksel = 1;
//        regsel = 2;
//        data = 32'h101;
        #1000
        
        
        
        
        
//        isFC = 1;
//        write = 0;
//        banksel = 0;
//        regsel = 0;
//        #20
//        write = 1;
//        banksel = 0;
//        regsel = 0;
//        data = 32'h100;
//        #10
//        banksel = 1;
//        regsel = 2;
//        data = 32'h300;
//        #10
//        banksel = 0;
//        regsel = 0;
//        data = 32'h410;
//        #10
//        banksel = 1;
//        regsel = 3;
//        data = 32'h502;
//        #10
//        banksel = 1;
//        regsel = 2;
//        data = 32'h680;
//        #10
        $finish;
        
        
    
    
    end

endmodule