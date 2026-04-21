`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/02/2026 04:21:45 AM
// Design Name: 
// Module Name: decoder
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


module fivebitdecoder (
    
    output [31:0] out,
    input [4:0] addr
    
    );

    wire [4:0] addr_n;

    not(addr_n[0], addr[0]);
    not(addr_n[1], addr[1]);
    not(addr_n[2], addr[2]);
    not(addr_n[3], addr[3]);
    not(addr_n[4], addr[4]);

    and(out[0],     addr_n[0],  addr_n[1],  addr_n[2],  addr_n[3],  addr_n[4]);
    and(out[1],     addr_n[0],  addr_n[1],  addr_n[2],  addr_n[3],  addr[4]);
    and(out[2],     addr_n[0],  addr_n[1],  addr_n[2],  addr[3],    addr_n[4]);
    and(out[3],     addr_n[0],  addr_n[1],  addr_n[2],  addr[3],    addr[4]);
    and(out[4],     addr_n[0],  addr_n[1],  addr[2],    addr_n[3],  addr_n[4]);
    and(out[5],     addr_n[0],  addr_n[1],  addr[2],    addr_n[3],  addr[4]);
    and(out[6],     addr_n[0],  addr_n[1],  addr[2],    addr[3],    addr_n[4]);
    and(out[7],     addr_n[0],  addr_n[1],  addr[2],    addr[3],    addr[4]);
    and(out[8],     addr_n[0],  addr[1],    addr_n[2],  addr_n[3],  addr_n[4]);
    and(out[9],     addr_n[0],  addr[1],    addr_n[2],  addr_n[3],  addr[4]);
    and(out[10],    addr_n[0],  addr[1],    addr_n[2],  addr[3],    addr_n[4]);
    and(out[11],    addr_n[0],  addr[1],    addr_n[2],  addr[3],    addr[4]);
    and(out[12],    addr_n[0],  addr[1],    addr[2],    addr_n[3],  addr_n[4]);
    and(out[13],    addr_n[0],  addr[1],    addr[2],    addr_n[3],  addr[4]);
    and(out[14],    addr_n[0],  addr[1],    addr[2],    addr[3],    addr_n[4]);
    and(out[15],    addr_n[0],  addr[1],    addr[2],    addr[3],    addr[4]);
    and(out[16],    addr[0],    addr_n[1],  addr_n[2],  addr_n[3],  addr_n[4]);
    and(out[17],    addr[0],    addr_n[1],  addr_n[2],  addr_n[3],  addr[4]);
    and(out[18],    addr[0],    addr_n[1],  addr_n[2],  addr[3],    addr_n[4]);
    and(out[19],    addr[0],    addr_n[1],  addr_n[2],  addr[3],    addr[4]);
    and(out[20],    addr[0],    addr_n[1],  addr[2],    addr_n[3],  addr_n[4]);
    and(out[21],    addr[0],    addr_n[1],  addr[2],    addr_n[3],  addr[4]);
    and(out[22],    addr[0],    addr_n[1],  addr[2],    addr[3],    addr_n[4]);
    and(out[23],    addr[0],    addr_n[1],  addr[2],    addr[3],    addr[4]);
    and(out[24],    addr[0],    addr[1],    addr_n[2],  addr_n[3],  addr_n[4]);
    and(out[25],    addr[0],    addr[1],    addr_n[2],  addr_n[3],  addr[4]);
    and(out[26],    addr[0],    addr[1],    addr_n[2],  addr[3],    addr_n[4]);
    and(out[27],    addr[0],    addr[1],    addr_n[2],  addr[3],    addr[4]);
    and(out[28],    addr[0],    addr[1],    addr[2],    addr_n[3],  addr_n[4]);
    and(out[29],    addr[0],    addr[1],    addr[2],    addr_n[3],  addr[4]);
    and(out[30],    addr[0],    addr[1],    addr[2],    addr[3],    addr_n[4]);
    and(out[31],    addr[0],    addr[1],    addr[2],    addr[3],    addr[4]);

endmodule