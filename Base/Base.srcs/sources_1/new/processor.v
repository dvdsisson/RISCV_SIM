`timescale 1ns / 1ps

module processor(
    input clock
    );

wire LD_ID, LD_EX, LD_MEM, LD_WB;
wire DEP_STALL, EX_STALL, MEM_STALL, ID_BR_STALL, EX_BR_STALL;
wire [31:0] ID_PC_Input, ID_PC_Output, ID_IR_Input, ID_IR_Output;
wire ID_VALID_Input, ID_VALID_Output;
wire [31:0] EX_PC_Input, EX_PC_Output, EX_IV_Input, EX_IV_Output, EX_SR1_Input, EX_SR1_Output, EX_SR2_Input, EX_SR2_Output, EX_DR_Input, EX_DR_Output, EX_CS_Input, EX_CS_Output;
wire EX_VALID_Input, EX_VALID_Output;
wire [31:0] MEM_PC_Input, MEM_PC_Output, MEM_TA_Input, MEM_TA_Output, MEM_ALU_Input, MEM_ALU_Output, MEM_DR_Input, MEM_DR_Output, MEM_CS_Input, MEM_CS_Output;
wire MEM_VALID_Input, MEM_VALID_Output;
wire [31:0] WB_PC_Input, WB_PC_Output, WB_MEM_Input, WB_MEM_Output, WB_ALU_Input, WB_ALU_Output, WB_DR_Input, WB_DR_Output, WB_CS_Input, WB_CS_Output;
wire WB_VALID_Input, WB_VALID_Output;

wire [31:0] JMP_PC;
wire JMP_PCMUX;

wire V_EX_LDREG, V_MEM_LDREG, V_WB_LDREG;
wire [4:0] EX_DR, MEM_DR, WB_DR;
wire [31:0] WB_DATA;

// MEMORY INITIALIZATION
memory(clock, ID_PC_Input[15:0], ID_IR_Input, MEM_TA_Output[15:0], MEM_ALU_Output, MEM_CS_Output[5], MEM_CS_Output[4:2], WB_MEM_Input, MEM_STALL);

// INSTRUCTION FETCH
// ------------------------------------------------------------------------------
wire i1, i2, i3, i4;
wire [31:0] PC_Input, ID_PC_Input_PlusFour;
wire LD_PC;

or(i1, ID_BR_STALL, EX_BR_STALL);
not(ID_VALID_Input, i1);
or(i2, DEP_STALL, EX_STALL, MEM_STALL);
not(LD_ID, i2); 
not(i3, JMP_PCMUX); 
and(i4, ID_VALID_Input, LD_ID, i3);
or(LD_PC, i4, JMP_PCMUX);
reg32_en PC(PC_Input, clock, LD_PC, ID_PC_Input);
//instructioncache(ID_PC_Input, ID_IR_Input);
adder(ID_PC_Input, 32'b00000000000000000000000000000100, 1'b0, ID_PC_Input_PlusFour);
mux2_32bit(ID_PC_Input_PlusFour, JMP_PC, JMP_PCMUX, PC_Input);

reg32_en ID_PC(ID_PC_Input, clock, LD_ID, ID_PC_Output);
reg32_en ID_IR(ID_IR_Input, clock, LD_ID, ID_IR_Output);
dff_en ID_VALID(ID_VALID_Input, clock, LD_ID, ID_VALID_Output);
// ------------------------------------------------------------------------------

// INSTRUCTION DECODE
// ------------------------------------------------------------------------------
wire [4:0] S1Reg, S2Reg;
wire SR1_Needed, SR2_Needed;
wire i5, i6, i7, i8, i9, i10;
wire i11, i12, i13, i14, i15, i16;
wire i17, i18;

assign S1Reg = ID_IR_Output[19:15];
assign S2Reg = ID_IR_Output[24:20]; 
assign EX_DR_Input = {27'b0, ID_IR_Output[11:7]};

assign EX_PC_Input = ID_PC_Output;
immediatevaluebuilder(ID_IR_Output, EX_CS_Input[21:19], EX_IV_Input);
registerfile(S1Reg, S2Reg, WB_LDREG, WB_DR, WB_DATA, clock, EX_SR1_Input, EX_SR2_Input);
controlstore(ID_IR_Output, EX_CS_Input);

assign SR1_Needed = EX_CS_Input[23];
assign SR2_Needed = EX_CS_Input[22];

fivebitcomparator(S1Reg, EX_DR, i5);
fivebitcomparator(S1Reg, MEM_DR, i6);
fivebitcomparator(S1Reg, WB_DR, i7);
fivebitcomparator(S2Reg, EX_DR, i8);
fivebitcomparator(S2Reg, MEM_DR, i9);
fivebitcomparator(S2Reg, WB_DR, i10);

and(i11, i5, V_EX_LDREG, SR1_Needed, ID_VALID_Output);
and(i12, i6, V_MEM_LDREG, SR1_Needed, ID_VALID_Output);
and(i13, i7, V_WB_LDREG, SR1_Needed, ID_VALID_Output);
and(i14, i8, V_EX_LDREG, SR2_Needed, ID_VALID_Output);
and(i15, i9, V_MEM_LDREG, SR2_Needed, ID_VALID_Output);
and(i16, i10, V_WB_LDREG, SR2_Needed, ID_VALID_Output);
or(DEP_STALL, i11, i12, i13, i14, i15, i16);

and(ID_BR_STALL, ID_VALID_Output, EX_CS_Input[18]);
not(i17, DEP_STALL);
and(EX_VALID_Input, ID_VALID_Output, i17);

or(i18, EX_STALL, MEM_STALL);
not(LD_EX, i18); 

reg32_en EX_PC(EX_PC_Input, clock, LD_EX, EX_PC_Output);
reg32_en EX_IV(EX_IV_Input, clock, LD_EX, EX_IV_Output);
reg32_en EX_SR1(EX_SR1_Input, clock, LD_EX, EX_SR1_Output);
reg32_en EX_SR2(EX_SR2_Input, clock, LD_EX, EX_SR2_Output);
reg32_en EX_DR1(EX_DR_Input, clock, LD_EX, EX_DR_Output);
reg32_en EX_CS(EX_CS_Input, clock, LD_EX, EX_CS_Output);
dff_en EX_VALID(EX_VALID_Input, clock, LD_EX, EX_VALID_Output);
// ------------------------------------------------------------------------------

// EXECUTE
// ------------------------------------------------------------------------------
wire [31:0] i19, i20, i21;
wire i22;

assign MEM_PC_Input = EX_PC_Output;
mux2_32bit(EX_PC_Output, EX_SR1_Output, EX_CS_Output[16], i19);
mux2_32bit(EX_SR2_Output, EX_IV_Output, EX_CS_Output[15], i20);
adder(i19, EX_IV_Output, 1'b0, MEM_TA_Input);
assign JMP_PC = MEM_TA_Input;
ALU(EX_SR1_Output, i20, EX_CS_Output[14:10], i21, EX_STALL);
mux2_32bit(i21, MEM_TA_Input, EX_CS_Output[9], MEM_ALU_Input);
assign MEM_DR_Input = EX_DR_Output;
assign EX_DR = EX_DR_Output[4:0];
assign MEM_CS_Input = EX_CS_Output;
assign MEM_VALID_Input = EX_VALID_Output;
branchcomparator(EX_SR1_Output, EX_SR2_Output, EX_CS_Output[8:6], i22);
and(JMP_PCMUX, i22, EX_VALID_Output);
and(EX_BR_STALL, EX_VALID_Output, EX_CS_Output[18]);
and(V_EX_LDREG, EX_VALID_Output, EX_CS_Output[17]);
not(LD_MEM, MEM_STALL);

reg32_en MEM_PC(MEM_PC_Input, clock, LD_MEM, MEM_PC_Output);
reg32_en MEM_TA(MEM_TA_Input, clock, LD_MEM, MEM_TA_Output);
reg32_en MEM_ALU(MEM_ALU_Input, clock, LD_MEM, MEM_ALU_Output);
reg32_en MEM_DR1(MEM_DR_Input, clock, LD_MEM, MEM_DR_Output);
reg32_en MEM_CS(MEM_CS_Input, clock, LD_MEM, MEM_CS_Output);
dff_en MEM_VALID(MEM_VALID_Input, clock, LD_MEM, MEM_VALID_Output);
// ------------------------------------------------------------------------------

// MEMORY
// ------------------------------------------------------------------------------
wire i23;

assign WB_PC_Input = MEM_PC_Output;
//datacache(MEM_TA_Output, MEM_ALU_Output, MEM_CS_Output[5], MEM_CS_Output[4:2], WB_MEM_Input, MEM_STALL);
assign WB_ALU_Input = MEM_ALU_Output;
assign WB_DR_Input = MEM_DR_Output;
assign MEM_DR = MEM_DR_Output[4:0];
assign WB_CS_Input = MEM_CS_Output;
and(V_MEM_LDREG, MEM_VALID_Output, MEM_CS_Output[17]);
not(i23, MEM_STALL);
and(WB_VALID_Input, MEM_VALID_Output, i23);
assign LD_WB = 1'b1;

reg32_en WB_PC(WB_PC_Input, clock, LD_WB, WB_PC_Output);
reg32_en WB_MEM(WB_MEM_Input, clock, LD_WB, WB_MEM_Output);
reg32_en WB_ALU(WB_ALU_Input, clock, LD_WB, WB_ALU_Output);
reg32_en WB_DR1(WB_DR_Input, clock, LD_WB, WB_DR_Output);
reg32_en WB_CS(WB_CS_Input, clock, LD_WB, WB_CS_Output);
dff_en WB_VALID(WB_VALID_Input, clock, LD_WB, WB_VALID_Output);
// ------------------------------------------------------------------------------

// WRITEBACK
// ------------------------------------------------------------------------------
wire [31:0] WB_PC_Output_PlusFour;

adder(WB_PC_Output, 32'b00000000000000000000000000000100, 1'b0, WB_PC_Output_PlusFour);
mux4_32bit(WB_PC_Output_PlusFour, WB_MEM_Output, WB_ALU_Output, 32'b00000000000000000000000000000000, WB_CS_Output[1:0], WB_DATA);
assign WB_DR = WB_DR_Output[4:0];
and(V_WB_LDREG, WB_VALID_Output, WB_CS_Output[17]);
// ------------------------------------------------------------------------------

endmodule