`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/26/2026 06:46:28 PM
// Design Name: 
// Module Name: forwarding
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


module forwarding(
    input [4:0] SR_Num,
    
    input V_EX,
    input [4:0] EX_DR,
    input V_EX_DF,
    input [31:0] EX_DATA,
    
    input V_MEM,
    input [4:0] MEM_DR,
    input V_MEM_DF,    
    input [31:0] MEM_DATA,
    
    input V_WB,
    input [4:0] WB_DR,
    input V_WB_DF,
    input [31:0] WB_DATA,
    
    input [31:0] REG_DATA,
    
    output DEP_STALL,
    output [31:0] SR_DATA
    );
    
    
    wire ex_sel, mem_sel, wb_sel,
         ex_reg, mem_reg, wb_reg;
             
    wire ex_stall, mem_stall, wb_stall, stall_0;
    
    wire [31:0] mux_bus_0, mux_bus_1;
    
    fivebitcomparator fbc1 (EX_DR,  SR_Num, ex_reg);
    fivebitcomparator fbc2 (MEM_DR, SR_Num, mem_reg);
    fivebitcomparator fbc3 (WB_DR,  SR_Num, wb_reg);
    
    
    and a1 (ex_sel, V_EX, ex_reg); // Use EX data if EX valid and matches reg    
    and a2 (mem_sel, V_MEM, mem_reg); // MEM candidate for forwarding (valid and matches reg)
    and a3 (wb_sel, V_WB, wb_reg); // WB candidate for forwarding (valid and matches reg)
    
    mux2_32bit mux1 (REG_DATA, WB_DATA, wb_sel, mux_bus_0); // If WB candidate, use WB, else use REG
    mux2_32bit mux2 (mux_bus_0, MEM_DATA, mem_sel, mux_bus_1); // If MEM candidate, use MEM, else use WB/REG
    mux2_32bit mux3 (mux_bus_1, EX_DATA, ex_sel, SR_DATA); // If EX, use EX, else use MEM/WB/REG
    
    // Dep Stall Logic
    and a4 (ex_stall, ex_sel, V_EX_DF); // EX used but not ready yet
    and a5 (mem_stall, mem_sel, V_MEM_DF); // MEM used but not ready yet
    and a6 (wb_stall, wb_sel, V_WB_DF); // WB used but not ready yet
    
    or o1 (DEP_STALL, ex_stall, mem_stall, wb_stall);
    
    
endmodule