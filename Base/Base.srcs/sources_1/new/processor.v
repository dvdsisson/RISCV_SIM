`timescale 1ns / 1ps

module processor(
    input clock,
    input reset
    );

wire LD_ID, LD_EX, LD_MEM, LD_WB;
wire DEP_STALL, EX_STALL, MEM_STALL, ID_BR_STALL, EX_BR_STALL;
wire [31:0] ID_PC_Input, ID_PC_Output, ID_IR_Input, ID_IR_Output;
wire ID_VALID_Input, ID_VALID_Output;
wire [31:0] REG_SR1_OUT, REG_SR2_OUT, REG_SR3_OUT;
wire [31:0] EX_PC_Input, EX_PC_Output, EX_IV_Input, EX_IV_Output, EX_SR1_Input, EX_SR1_Output, EX_SR2_Input, EX_SR2_Output, EX_SR3_Input, EX_SR3_Output, EX_DR_Input, EX_DR_Output, EX_CS_Input, EX_CS_Output;
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

wire [15:0] MDS_mem_addr, SE_mem_addr, KSE_mem_addr, PD_mem_addr, Controller_mem_addr;
wire [31:0] MDS_mem_wdata, MDS_mem_rdata, SE_mem_rdata, KSE_mem_rdata, PD_mem_rdata, PD_mem_wdata, Controller_mem_rdata, Controller_mem_wdata;
wire MDS_mem_wr, PD_mem_wr, Controller_mem_wr;

// MEMORY INITIALIZATION
memory Memory(clock, ID_PC_Input[15:0], ID_IR_Input, MEM_TA_Output[15:0], MEM_ALU_Output, MEM_CS_Output[5], MEM_CS_Output[4:2], WB_MEM_Input, 
MDS_mem_addr, MDS_mem_wdata, MDS_mem_wr, MDS_mem_rdata,
SE_mem_addr, SE_mem_rdata, KSE_mem_addr, KSE_mem_rdata, 
PD_mem_addr, PD_mem_wdata, PD_mem_wr, PD_mem_rdata, PD_byte,
Controller_mem_addr, Controller_mem_wdata, Controller_mem_wr, Controller_mem_rdata, Controller_byte,
MEM_STALL);

// Branch Pred Nets
wire [31:0] curr_PC, pred_PC, bp_ex_PC, bp_ex_target;
wire bp_pred_Taken;
wire [4:0] bp_table_index, bp_ex_table_index;
wire bp_ex_isbranch, bp_ex_taken;

branchPred branchpred1 (clock, reset, curr_PC, pred_PC, bp_pred_taken, bp_table_index, bp_ex_isbranch, bp_ex_taken, bp_ex_table_index, bp_ex_PC, bp_ex_target);

// INSTRUCTION FETCH
// ------------------------------------------------------------------------------
wire i1, i2, i3, i4;
wire [31:0] PC_Input, ID_PC_Input_PlusFour;
wire LD_PC;

wire [7:0] ID_bp_table_index;
wire ID_bp_taken_Output;

//or(i1, ID_BR_STALL, EX_BR_STALL);
//not(ID_VALID_Input, i1);
assign ID_VALID_Input = 1'b1;
or(i2, DEP_STALL, EX_STALL, MEM_STALL);
not(LD_ID, i2); 
not(i3, JMP_PCMUX); 
and(i4, ID_VALID_Input, LD_ID, i3);
or(LD_PC, i4, JMP_PCMUX);
reg32_en_reset PC(PC_Input, clock, LD_PC, reset, 32'b00000000000000000011000000000000, ID_PC_Input);
//instructioncache(ID_PC_Input, ID_IR_Input);
assign curr_PC = ID_PC_Input; //Branch Pred
adder Adder1(ID_PC_Input, 32'b00000000000000000000000000000100, 1'b0, ID_PC_Input_PlusFour);
mux2_32bit Mux1(pred_PC, JMP_PC, JMP_PCMUX, PC_Input); //pred pc instead of plus 4
reg32_en ID_PC(ID_PC_Input, clock, LD_ID, ID_PC_Output);
reg32_en ID_IR(ID_IR_Input, clock, LD_ID, ID_IR_Output);
dff_en ID_VALID(ID_VALID_Input, clock, LD_ID, ID_VALID_Output);

reg5_en ID_bp_Index(bp_table_index, clock, LD_ID, ID_bp_table_index);
dff_en ID_bp_taken(bp_pred_taken, clock, LD_ID, ID_bp_taken_Output);
// ------------------------------------------------------------------------------

// INSTRUCTION DECODE
// ------------------------------------------------------------------------------
wire [4:0] S1Reg, S2Reg, S3Reg;
wire SR1_Needed, SR2_Needed, SR3_Needed;
wire i5, i6, i7, i8, i9, i10;
wire i11, i12, i13, i14, i15, i16;
wire i17, i18;

wire [4:0] EX_bp_table_index;
wire EX_bp_taken_Output;

assign S1Reg = ID_IR_Output[19:15];
mux2_32bit Mux6(ID_IR_Output[24:20], ID_IR_Output[11:7], EX_CS_Input[31], S2Reg);
assign S3Reg = ID_IR_Output[24:20];
assign EX_DR_Input = {27'b0, ID_IR_Output[11:7]};

assign EX_PC_Input = ID_PC_Output;
immediatevaluebuilder ImmediateValueBuilder(ID_IR_Output, EX_CS_Input[21:19], EX_IV_Input);
registerfile RegisterFile(S1Reg, S2Reg, S3Reg, V_WB_LDREG, WB_DR, WB_DATA, clock, REG_SR1_OUT, REG_SR2_OUT, REG_SR3_OUT, reset);
controlstore ControlStore(ID_IR_Output, EX_CS_Input);

assign SR1_Needed = EX_CS_Input[23];
assign SR2_Needed = EX_CS_Input[22];
assign SR3_Needed = EX_CS_Input[29];
// Data Forwarding

wire [31:0] EX_DATA_OUT, MEM_DATA_OUT, WB_DATA_OUT;

wire dep_stall_r1, dep_stall_r2, dep_stall_r3; 
wire v_ex_df;

and(v_ex_df, V_EX_LDREG, EX_CS_Input[5]); 

forwarding df1 (S1Reg, 
V_EX_LDREG,  EX_DR,  v_ex_df,        EX_DATA_OUT,
V_MEM_LDREG, MEM_DR, WB_VALID_Input, MEM_DATA_OUT,
V_WB_LDREG,  WB_DR,  V_WB_LDREG,     WB_DATA_OUT,
REG_SR1_OUT,
dep_stall_r1, EX_SR1_Input);

forwarding df2 (S2Reg, 
V_EX_LDREG,  EX_DR,  v_ex_df,        EX_DATA_OUT,
V_MEM_LDREG, MEM_DR, WB_VALID_Input, MEM_DATA_OUT,
V_WB_LDREG,  WB_DR,  V_WB_LDREG,     WB_DATA_OUT,
REG_SR2_OUT,
dep_stall_r2, EX_SR2_Input);

forwarding df3 (S3Reg, 
V_EX_LDREG,  EX_DR,  v_ex_df,        EX_DATA_OUT,
V_MEM_LDREG, MEM_DR, WB_VALID_Input, MEM_DATA_OUT,
V_WB_LDREG,  WB_DR,  V_WB_LDREG,     WB_DATA_OUT,
REG_SR3_OUT,
dep_stall_r3, EX_SR3_Input);

// fivebitcomparator FiveBitComparator1(S1Reg, EX_DR, i5);
// fivebitcomparator FiveBitComparator2(S1Reg, MEM_DR, i6);
// fivebitcomparator FiveBitComparator3(S1Reg, WB_DR, i7);
// fivebitcomparator FiveBitComparator4(S2Reg, EX_DR, i8);
// fivebitcomparator FiveBitComparator5(S2Reg, MEM_DR, i9);
// fivebitcomparator FiveBitComparator6(S2Reg, WB_DR, i10);

// and(i11, i5, V_EX_LDREG, SR1_Needed, ID_VALID_Output);
// and(i12, i6, V_MEM_LDREG, SR1_Needed, ID_VALID_Output);
// and(i13, i7, V_WB_LDREG, SR1_Needed, ID_VALID_Output);
// and(i14, i8, V_EX_LDREG, SR2_Needed, ID_VALID_Output);
// and(i15, i9, V_MEM_LDREG, SR2_Needed, ID_VALID_Output);
// and(i16, i10, V_WB_LDREG, SR2_Needed, ID_VALID_Output);
// or(DEP_STALL, i11, i12, i13, i14, i15, i16);

and(DEP_STALL, dep_stall_r1, dep_stall_r2, dep_stall_r3);

and(ID_BR_STALL, ID_VALID_Output, EX_CS_Input[18]);
not(i17, DEP_STALL);
and(EX_VALID_Input, ID_VALID_Output, i17);

or(i18, EX_STALL, MEM_STALL);
not(LD_EX, i18); 

reg32_en EX_PC(EX_PC_Input, clock, LD_EX, EX_PC_Output);
reg32_en EX_IV(EX_IV_Input, clock, LD_EX, EX_IV_Output);
reg32_en EX_SR1(EX_SR1_Input, clock, LD_EX, EX_SR1_Output);
reg32_en EX_SR2(EX_SR2_Input, clock, LD_EX, EX_SR2_Output);
reg32_en EX_SR3(EX_SR3_Input, clock, LD_EX, EX_SR3_Output);
reg32_en EX_DR1(EX_DR_Input, clock, LD_EX, EX_DR_Output);
reg32_en EX_CS(EX_CS_Input, clock, LD_EX, EX_CS_Output);
dff_en EX_VALID(EX_VALID_Input, clock, LD_EX, EX_VALID_Output);

reg5_en EX_bp_Index(ID_bp_table_index, clock, LD_ID, EX_bp_table_index);
dff_en EX_bp_taken(ID_bp_taken_Output, clock, LD_ID, EX_bp_taken_Output);
// ------------------------------------------------------------------------------

// EXECUTE
// ------------------------------------------------------------------------------
wire [31:0] i19, i20, i21;
wire i22, alu_ex_stall, ex_stall_out;

assign MEM_PC_Input = EX_PC_Output;
mux2_32bit Mux2(EX_PC_Output, EX_SR1_Output, EX_CS_Output[16], i19);
mux2_32bit Mux3(EX_SR2_Output, EX_IV_Output, EX_CS_Output[15], i20);
adder Adder2(i19, EX_IV_Output, 1'b0, MEM_TA_Input);
assign JMP_PC = MEM_TA_Input;
ALU alu(EX_SR1_Output, i20, EX_CS_Output[14:10], i21, alu_ex_stall);
mux2_32bit Mux4(i21, MEM_TA_Input, EX_CS_Output[9], MEM_ALU_Input);
assign MEM_DR_Input = EX_DR_Output;
assign EX_DR = EX_DR_Output[4:0];
assign MEM_CS_Input = EX_CS_Output;
assign MEM_VALID_Input = EX_VALID_Output;
branchcomparator BranchComparator(EX_SR1_Output, EX_SR2_Output, EX_CS_Output[8:6], i22);

or(EX_STALL, alu_ex_stall, ex_stall_out);

wire branch_take;
and(branch_take, i22, EX_VALID_Output);
and(EX_BR_STALL, EX_VALID_Output, EX_CS_Output[18]);
and(V_EX_LDREG, EX_VALID_Output, EX_CS_Output[17]);
not(LD_MEM, MEM_STALL);


xor (JMP_PCMUX, branch_take, EX_bp_taken_Output);
// Branch Prediction
assign bp_ex_table_index = EX_bp_table_index;
assign bp_ex_PC = EX_PC_Output;
assign bp_ex_target = MEM_TA_Input;
assign bp_ex_taken = branch_take;


and andbpbranch (bp_ex_isbranch, EX_CS_Output[18], MEM_VALID_Input);

// block:
// bp_ex_isbranch, bp_ex_taken, bp_ex_table_index, bp_ex_PC, bp_ex_target


reg32_en MEM_PC(MEM_PC_Input, clock, LD_MEM, MEM_PC_Output);
reg32_en MEM_TA(MEM_TA_Input, clock, LD_MEM, MEM_TA_Output);
reg32_en MEM_ALU(MEM_ALU_Input, clock, LD_MEM, MEM_ALU_Output);

assign EX_DATA_OUT = MEM_ALU_Input;
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

// assign MEM_DATA_OUT = MEM_CS_Output[17] ? WB_ALU_Input : WB_MEM_Input;
mux2_32bit mem_df_mux (WB_MEM_Input, WB_ALU_Input, MEM_CS_Output[17], MEM_DATA_OUT);

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

adder Adder3(WB_PC_Output, 32'b00000000000000000000000000000100, 1'b0, WB_PC_Output_PlusFour);
mux4_32bit Mux5(WB_PC_Output_PlusFour, WB_MEM_Output, WB_ALU_Output, 32'b00000000000000000000000000000000, WB_CS_Output[1:0], WB_DATA);
assign WB_DR = WB_DR_Output[4:0];
assign WB_DATA_OUT = WB_DATA;
and(V_WB_LDREG, WB_VALID_Output, WB_CS_Output[17]);
// ------------------------------------------------------------------------------

// AUGMENTED EXECUTE

wire[31:0] ex_cs;
wire [31:0] rs1, rs2, rs3;
assign ex_cs = EX_CS_Output;
assign rs1 = EX_SR1_Output;
assign rs2 = EX_SR2_Output;
assign rs3 = EX_SR3_Output;


// EXECUTE STALL LOGIC
// ------------------------------------------------------------------------------

wire PD_done_last_cycle, FC_done_last_cycle;
wire [31:0] CS_last_cycle;
wire PD_reset, PD_start_comb, PD_start, PD_done;
wire Controller_start, is_FC_Block, isConv, Controller_done;
dff_en PD_done_flip_flop(PD_done, clock, 1'b1, PD_done_last_cycle);
dff_en FC_done_flip_flop(Controller_done, clock, 1'b1, FC_done_last_cycle);
reg32_en CS_last_cycle_register(ex_cs, clock, 1'b1, CS_last_cycle);

wire not30, mdsint;
not(not30, CS_last_cycle[30]);
or(mdsint, not30, PD_done_last_cycle);
and(MDS_start, mdsint, ex_cs[30], EX_VALID_Output);

wire not27, seint;
not(not27, CS_last_cycle[27]);
or(seint, not27, FC_done_last_cycle);
and(SE_start, seint, ex_cs[27], EX_VALID_Output);

wire finalstart, finaldone, Q1, Q2;
or(finalstart, MDS_start, SE_start);
or(finaldone, PD_done, Controller_done, reset);

nor(Q1, finaldone, Q2);
nor(Q2, finalstart, Q1);
assign ex_stall_out = Q1;

// FIRST STAGE
// ------------------------------------------------------------------------------

wire MDS_reset, MDS_start, MDS_done;
wire [31:0] MDS_pixel_ptr, output_ptrA, output_ptrB, output_ptrC, cycle_cnt;
assign MDS_reset = reset;

metadata_storage_block MDS (
    clock,
    MDS_reset,
    MDS_start,
    rs1,
    rs2,
    MDS_mem_addr,
    MDS_mem_wdata,
    MDS_mem_wr,      
    MDS_mem_rdata,   
    MDS_pixel_ptr,    
    output_ptrA,  
    output_ptrB,  
    output_ptrC,  
    cycle_cnt,   
    MDS_done         
);

wire SE_reset, SE_start, SE_ready, SE_done, is_fc;
wire [31:0] SE_pixel_ptr, chn_amnt_output, cols_output, lat_shifts_output, vert_shifts_output, size_output;
assign SE_reset = reset;
assign is_fc = ex_cs[28];

size_extraction_block2 SE(
    clock,
    SE_reset,
    SE_start,
    rs3,
    is_fc,
    SE_mem_addr,
    SE_mem_rdata, 
    SE_pixel_ptr,
    chn_amnt_output,
    cols_output,
    lat_shifts_output,   
    vert_shifts_output,  
    size_output,
    SE_ready,
    SE_done
);

wire KSE_reset, KSE_start, KSE_done;
wire [31:0] kern_size, kern_ptr_out;
assign KSE_reset = reset;
assign KSE_start = SE_ready;

kern_size_extraction_block KSE(
    clock,
    KSE_reset,
    KSE_start,
    rs1,     
    KSE_mem_addr,
    KSE_mem_rdata, 
    kern_size,      
    kern_ptr_out,   
    KSE_done
);

wire [31:0] pixel_ptr;
mux2_32bit Mux(SE_pixel_ptr, MDS_pixel_ptr, ex_cs[30], pixel_ptr);

wire aug1_start;
or(aug1_start, MDS_done, SE_done, KSE_done);
and(PD_start_comb, aug1_start, ex_cs[30]);
dff_en PD_start_dff(PD_start_comb, clock, 1'b1, PD_start);

wire other_blocks;
or(other_blocks, ex_cs[26], ex_cs[25], ex_cs[24]);
and(Controller_start, aug1_start, other_blocks);


// SECOND STAGE
// ------------------------------------------------------------------------------

wire [31:0] S2pixel_ptr_Output, S2output_ptrA_Output, S2output_ptrB_Output, S2output_ptrC_Output, S2cycle_amnt_Output, S2columns_Output, S2lat_shifts_Output, S2vert_shifts_Output, S2chn_amnt_Output, S2kern_size_Output, S2kern_ptr_Output, S2bias_ptr_Output, S2fc_cyc_Output, S2weight_ptr_Output, S2size_Output, S2output_ptr; 
wire LD_S2;
assign LD_S2 = 1'b1;

reg32_en S2pixel_ptr(pixel_ptr, clock, LD_S2, S2pixel_ptr_Output);
reg32_en S2output_ptrA(output_ptrA, clock, LD_S2, S2output_ptrA_Output);
reg32_en S2output_ptrB(output_ptrB, clock, LD_S2, S2output_ptrB_Output);
reg32_en S2output_ptrC(output_ptrC, clock, LD_S2, S2output_ptrC_Output);
reg32_en S2cycle_amnt(cycle_cnt, clock, LD_S2, S2cycle_amnt_Output);
reg32_en S2columns(cols_output, clock, LD_S2, S2columns_Output);
reg32_en S2lat_shifts(lat_shifts_output, clock, LD_S2, S2lat_shifts_Output);
reg32_en S2vert_shifts(vert_shifts_output, clock, LD_S2, S2vert_shifts_Output);
reg32_en S2chn_amnt(chn_amnt_output, clock, LD_S2, S2chn_amnt_Output);
reg32_en S2kern_size(kern_size, clock, LD_S2, S2kern_size_Output);
reg32_en S2kern_ptr(kern_ptr_out, clock, LD_S2, S2kern_ptr_Output);
reg32_en S2bias_ptr(rs1, clock, LD_S2, S2bias_ptr_Output);
reg32_en S2weight_ptr(rs1, clock, LD_S2, S2weight_ptr_Output);
reg32_en S2size(size_output, clock, LD_S2, S2size_Output);
reg32_en S2output_ptrs(rs2, clock, LD_S2, S2output_ptr);

assign PD_reset = reset;
wire PD_byte, Controllerb_byte;

assign PD_byte = 1'b0;
pixel_decode_block PD(
    clock,
    PD_reset,
    PD_start,
    S2pixel_ptr_Output,
    S2output_ptrA_Output,
    S2output_ptrB_Output,
    S2output_ptrC_Output,
    S2cycle_amnt_Output,
    PD_mem_addr,
    PD_mem_wdata,
    PD_mem_wr,      
    PD_mem_rdata,
    PD_done
);

assign is_FC_Block = ex_cs[24];
assign isConv = ex_cs[26];

fc_conv_bias FC(
    clock, 
    Controller_start, 
    is_FC_Block, 
    isConv,
    Controller_mem_rdata,
    S2pixel_ptr_Output, 
    S2kern_ptr_Output, 
    S2bias_ptr_Output, 
    S2weight_ptr_Output, 
    S2output_ptr, 
    S2lat_shifts_Output, 
    S2vert_shifts_Output,
    S2size_Output, 
    S2columns_Output, 
    S2chn_amnt_Output,
    Controller_mem_addr,
    Controller_mem_wr,  // w = 1
    Controller_done,
    Controller_mem_wdata,
    Controller_byte
);

endmodule