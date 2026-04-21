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
    output [4:0] hashindex, // Need to keep to update table

    input isBranch, Taken,
    input [4:0] EX_index, 
    input [31:0] EX_PC, EX_Target

    );


    // Global History Register
    wire [4:0] GHR, hashindex;
    shf_reg shf0 #(.length(5)) (clk, isBranch, Taken, GHR);

    genvar i;
    generate
        for (i=0; i<5; i=i+1) begin
            xnor x1 (hashindex[i], curr_PC[i+2], GHR[i]);
        end
    endgenerate

    // Table Indexing

    wire [31:0] tagout, target;
    wire predout;

    regtable tags           (clk, reset, hashindex, tagout,     isBranch, EX_index, EX_PC);
    regtable targ           (clk, reset, hashindex, target,     isBranch, EX_index, EX_Target);
    twobittable counters    (clk, reset, hashindex, predout,    isBranch, EX_index, Taken);

    // Tag Checking
    wire [31:0] xortag;
    wire tagmatch;

    generate
        for (i=0; i<32; i=i+1) begin
            xnor x2 (xortag[i], curr_PC[i], tagout[i]);
        end
    endgenerate
    
    redand32b rand1 (xortag, tagmatch);


    // Output
    wire [31:0] PC_plus_four;
    adder(curr_PC, 32'h4, 1'b0, PC_plus_four);

    and amuxout1 (pred_Taken, tagmatch, predout);
    
    mux2_32bit outmux (PC_plus_four, target, pred_Taken, pred_PC);



    





































endmodule