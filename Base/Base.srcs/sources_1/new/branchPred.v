`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/31/2026 05:18:11 AM
// Design Name: 
// Module Name: branchPred
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


module branchPred(

    input clk,

    input [31:0] curr_PC,
    output [31:0] pred_PC,
    output pred_Taken, // Need to keep to update table
    output [7:0] table_index, // Need to keep to update table

    input isBranch, Taken,
    input [7:0] Ex_index, 
    input [31:0] Ex_PC, Target

    );

    wire [4:0] GHR, index;
    wire tagmatch, counterout;
    wire [31:0] PC_plus_four;

    shf_reg shf0 #(.length(5)) (clk, isBranch, Taken, GHR);

    genvar i;
    generate
        for (i = 0; i < 5, i = i+1) begin : bp_xors
            xor(index[i], GHR[i], curr_PC[i+2]);
        end
    endgenerate

    reg_array Tag_Store     #(.reg_length(30))  (clk, index, tag_out,    isBranch, Ex_index, Ex_PC [31:2]); // Length = 32 - 5(tag) - 2(LSB)
    reg_array Target_Store  #(.reg_length(30))  (clk, index, target_out, isBranch, Ex_index, Target [31:2]); // Length = 32 - 2(LSB)
    counter_array Counter_Store                 (clk, index, counterout, isBranch, Ex_index, Taken);

    comparator32b comp (curr_PC[31:0], {tag_out, 2'b0}, tagmatch);

    and(pred_Taken, tagmatch, counterout);

    adder(curr_PC, 32'b00000000000000000000000000000100, 1'b0, PC_plus_four);
    mux2_32bit (PC_plus_four, {target_out, 2'b00}, pred_Taken, pred_PC);

    assign table_index = index;

endmodule
