`timescale 1ns / 1ps

module memory(
    input clock,
    // Instruction Cache Read
    input [15:0] ICaddress,
    output reg [31:0] ICoutputvalue,
    // Data Cache Read/Write
    input [15:0] DCaddress,
    input [31:0] DCinputvalue,
    input LDST,
    input [2:0] LDST_OP,
    output reg [31:0] DCoutputvalue,
    output MEM_STALL
);

// 64 KB memory (byte-addressable)
(* ram_style = "registers", keep, dont_touch *)
reg [7:0] mem_array [0:65535];

integer i;
initial begin
    for (i = 0; i < 65536; i = i + 1) begin
        mem_array[i] = 8'b00000000;
    end
end

// Instruction Cache (Read)

always @(*) begin
    ICoutputvalue = {mem_array[ICaddress+3], mem_array[ICaddress+2],
                mem_array[ICaddress+1], mem_array[ICaddress]};
end

// Data Cache (Read/Write)

always @(*) begin
    DCoutputvalue = 32'b0;
    if (LDST && LDST_OP <= 4) begin
        case(LDST_OP)
            3'b000: DCoutputvalue = {{24{mem_array[DCaddress][7]}}, mem_array[DCaddress]}; // LB
            3'b001: DCoutputvalue = {{16{mem_array[DCaddress+1][7]}}, mem_array[DCaddress+1], mem_array[DCaddress]}; // LH
            3'b010: DCoutputvalue = {mem_array[DCaddress+3], mem_array[DCaddress+2], mem_array[DCaddress+1], mem_array[DCaddress]}; // LW
            3'b011: DCoutputvalue = {24'b0, mem_array[DCaddress]}; // LBU
            3'b100: DCoutputvalue = {16'b0, mem_array[DCaddress+1], mem_array[DCaddress]}; // LHU
        endcase
    end
end

always @(posedge clock) begin
    if (LDST && LDST_OP >= 5) begin
        case(LDST_OP)
            3'b101: mem_array[DCaddress] <= DCinputvalue[7:0]; // SB
            3'b110: begin // SH
                mem_array[DCaddress]   <= DCinputvalue[7:0];
                mem_array[DCaddress+1] <= DCinputvalue[15:8];
            end
            3'b111: begin // SW
                mem_array[DCaddress]   <= DCinputvalue[7:0];
                mem_array[DCaddress+1] <= DCinputvalue[15:8];
                mem_array[DCaddress+2] <= DCinputvalue[23:16];
                mem_array[DCaddress+3] <= DCinputvalue[31:24];
            end
        endcase
    end
end

assign MEM_STALL = 1'b0;

endmodule