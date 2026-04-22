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

    // Metadata Storage Block Read/Write
    input [15:0] MSaddress,
    input [31:0] MSinputvalue,
    input MSW,
    output reg [31:0] MSoutputvalue,

    // Size Extraction Block Read
    input [15:0] SEaddress,
    output reg [31:0] SEoutputvalue,

    // Kernel Size Extraction Block Read
    input [15:0] KSEaddress,
    output reg [31:0] KSEoutputvalue,

    // Pixel Decode Block Read/Write
    input [15:0] PDaddress,
    input [31:0] PDinputvalue,
    input PDW,
    output reg [31:0] PDoutputvalue,

    // FC Block Read/Write
    input [15:0] FCaddress,
    input [31:0] FCinputvalue,
    input FCW,
    output reg [31:0] FCoutputvalue,

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

// Metadata Storage Block

always @(*) begin
    MSoutputvalue = 32'b0;
    if (MSW == 0) begin
        MSoutputvalue = {mem_array[MSaddress+3], mem_array[MSaddress+2], mem_array[MSaddress+1], mem_array[MSaddress]};
    end
end

always @(posedge clock) begin
    if (MSW == 1) begin
        mem_array[MSaddress]   <= MSinputvalue[7:0];
        mem_array[MSaddress+1] <= MSinputvalue[15:8];
        mem_array[MSaddress+2] <= MSinputvalue[23:16];
        mem_array[MSaddress+3] <= MSinputvalue[31:24];
    end
end

// Size Extraction Block

always @(*) begin
    SEoutputvalue = {mem_array[SEaddress+3], mem_array[SEaddress+2],
                mem_array[SEaddress+1], mem_array[SEaddress]};
end

// Kernel Size Extraction Block

always @(*) begin
    KSEoutputvalue = {mem_array[KSEaddress+3], mem_array[KSEaddress+2],
                mem_array[KSEaddress+1], mem_array[KSEaddress]};
end

// Pixel Decode Block

always @(*) begin
    PDoutputvalue = 32'b0;
    if (PDW == 0) begin
        PDoutputvalue = {mem_array[PDaddress+3], mem_array[PDaddress+2], mem_array[PDaddress+1], mem_array[PDaddress]};
    end
end

always @(posedge clock) begin
    if (PDW == 1) begin
        mem_array[PDaddress]   <= PDinputvalue[7:0];
        mem_array[PDaddress+1] <= PDinputvalue[15:8];
        mem_array[PDaddress+2] <= PDinputvalue[23:16];
        mem_array[PDaddress+3] <= PDinputvalue[31:24];
    end
end

// FC Block

always @(*) begin
    FCoutputvalue = 32'b0;
    if (FCW == 0) begin
        FCoutputvalue = {mem_array[FCaddress+3], mem_array[FCaddress+2], mem_array[FCaddress+1], mem_array[FCaddress]};
    end
end

always @(posedge clock) begin
    if (FCW == 1) begin
        mem_array[FCaddress]   <= FCinputvalue[7:0];
        mem_array[FCaddress+1] <= FCinputvalue[15:8];
        mem_array[FCaddress+2] <= FCinputvalue[23:16];
        mem_array[FCaddress+3] <= FCinputvalue[31:24];
    end
end


assign MEM_STALL = 1'b0;


endmodule