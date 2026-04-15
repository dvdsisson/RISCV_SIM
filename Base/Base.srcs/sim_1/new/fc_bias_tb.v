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
    always #5 clk = ~clk;

    reg isFC, write, reset, banksel;
    reg [1:0] regsel;
    reg [31:0] data; 
    reg r3write;
    wire [31:0] out;
    
    fc_bias f1 (clk, isFC, write, reset, banksel, regsel, data, r3write, out);
    
    initial begin
        isFC = 0;
        write = 0;
        reset = 1;
        banksel = 0;
        regsel = 0;
        r3write = 1;
        #20
        reset = 0;
        write = 1;
        banksel = 0;
        regsel = 0;
        data = 32'h100;
        #10
        banksel = 1;
        regsel = 2;
        data = 32'h300;
        #10
        banksel = 0;
        regsel = 2;
        data = 32'h410;
        #10
        banksel = 1;
        regsel = 3;
        data = 32'h502;
        #10
        banksel = 1;
        regsel = 2;
        data = 32'h680;
        #10
        
        
        
        
        
        isFC = 1;
        write = 0;
        reset = 1;
        banksel = 0;
        regsel = 0;
        #20
        reset = 0;
        write = 1;
        banksel = 0;
        regsel = 0;
        data = 32'h100;
        #10
        banksel = 1;
        regsel = 2;
        data = 32'h300;
        #10
        banksel = 0;
        regsel = 0;
        data = 32'h410;
        #10
        banksel = 1;
        regsel = 3;
        data = 32'h502;
        #10
        banksel = 1;
        regsel = 2;
        data = 32'h680;
        #10
        $finish;
        
        
    
    
    end

endmodule