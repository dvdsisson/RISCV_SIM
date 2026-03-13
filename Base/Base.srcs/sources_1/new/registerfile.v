`timescale 1ns / 1ps

module registerfile(
    input [4:0] S1Reg,
    input [4:0] S2Reg,
    input V_WB_LDREG,
    input [4:0] WB_DR,
    input [31:0] WB_DATA,
    input clock,
    output [31:0] S1Value,
    output [31:0] S2Value,
    reset
    );

wire DR4, DR3, DR2, DR1, DR0, NOTDR4, NOTDR3, NOTDR2, NOTDR1, NOTDR0;
wire Reg0Enable, Reg1Enable, Reg2Enable, Reg3Enable, Reg4Enable, Reg5Enable, Reg6Enable, Reg7Enable, Reg8Enable, Reg9Enable, Reg10Enable, Reg11Enable, Reg12Enable, Reg13Enable, Reg14Enable, Reg15Enable, Reg16Enable, Reg17Enable, Reg18Enable, Reg19Enable, Reg20Enable, Reg21Enable, Reg22Enable, Reg23Enable, Reg24Enable, Reg25Enable, Reg26Enable, Reg27Enable, Reg28Enable, Reg29Enable, Reg30Enable, Reg31Enable;
wire [31:0] Reg0Value, Reg1Value, Reg2Value, Reg3Value, Reg4Value, Reg5Value, Reg6Value, Reg7Value, Reg8Value, Reg9Value, Reg10Value, Reg11Value, Reg12Value, Reg13Value, Reg14Value, Reg15Value, Reg16Value, Reg17Value, Reg18Value, Reg19Value, Reg20Value, Reg21Value, Reg22Value, Reg23Value, Reg24Value, Reg25Value, Reg26Value, Reg27Value, Reg28Value, Reg29Value, Reg30Value, Reg31Value;
wire [31:0] intermediateone, intermediatetwo; 
wire equalone, equaltwo, overrideone, overridetwo;

assign DR4 = WB_DR[4];
assign DR3 = WB_DR[3];
assign DR2 = WB_DR[2];
assign DR1 = WB_DR[1];
assign DR0 = WB_DR[0];

not(NOTDR4, DR4); 
not(NOTDR3, DR3); 
not(NOTDR2, DR2); 
not(NOTDR1, DR1); 
not(NOTDR0, DR0); 

and(Reg0Enable, NOTDR4, NOTDR3, NOTDR2, NOTDR1, NOTDR0, V_WB_LDREG);
and(Reg1Enable, NOTDR4, NOTDR3, NOTDR2, NOTDR1, DR0, V_WB_LDREG);
and(Reg2Enable, NOTDR4, NOTDR3, NOTDR2, DR1, NOTDR0, V_WB_LDREG);
and(Reg3Enable, NOTDR4, NOTDR3, NOTDR2, DR1, DR0, V_WB_LDREG);
and(Reg4Enable, NOTDR4, NOTDR3, DR2, NOTDR1, NOTDR0, V_WB_LDREG);
and(Reg5Enable, NOTDR4, NOTDR3, DR2, NOTDR1, DR0, V_WB_LDREG);
and(Reg6Enable, NOTDR4, NOTDR3, DR2, DR1, NOTDR0, V_WB_LDREG);
and(Reg7Enable, NOTDR4, NOTDR3, DR2, DR1, DR0, V_WB_LDREG);
and(Reg8Enable, NOTDR4, DR3, NOTDR2, NOTDR1, NOTDR0, V_WB_LDREG);
and(Reg9Enable, NOTDR4, DR3, NOTDR2, NOTDR1, DR0, V_WB_LDREG);
and(Reg10Enable, NOTDR4, DR3, NOTDR2, DR1, NOTDR0, V_WB_LDREG);
and(Reg11Enable, NOTDR4, DR3, NOTDR2, DR1, DR0, V_WB_LDREG);
and(Reg12Enable, NOTDR4, DR3, DR2, NOTDR1, NOTDR0, V_WB_LDREG);
and(Reg13Enable, NOTDR4, DR3, DR2, NOTDR1, DR0, V_WB_LDREG);
and(Reg14Enable, NOTDR4, DR3, DR2, DR1, NOTDR0, V_WB_LDREG);
and(Reg15Enable, NOTDR4, DR3, DR2, DR1, DR0, V_WB_LDREG);
and(Reg16Enable, DR4, NOTDR3, NOTDR2, NOTDR1, NOTDR0, V_WB_LDREG);
and(Reg17Enable, DR4, NOTDR3, NOTDR2, NOTDR1, DR0, V_WB_LDREG);
and(Reg18Enable, DR4, NOTDR3, NOTDR2, DR1, NOTDR0, V_WB_LDREG);
and(Reg19Enable, DR4, NOTDR3, NOTDR2, DR1, DR0, V_WB_LDREG);
and(Reg20Enable, DR4, NOTDR3, DR2, NOTDR1, NOTDR0, V_WB_LDREG);
and(Reg21Enable, DR4, NOTDR3, DR2, NOTDR1, DR0, V_WB_LDREG);
and(Reg22Enable, DR4, NOTDR3, DR2, DR1, NOTDR0, V_WB_LDREG);
and(Reg23Enable, DR4, NOTDR3, DR2, DR1, DR0, V_WB_LDREG);
and(Reg24Enable, DR4, DR3, NOTDR2, NOTDR1, NOTDR0, V_WB_LDREG);
and(Reg25Enable, DR4, DR3, NOTDR2, NOTDR1, DR0, V_WB_LDREG);
and(Reg26Enable, DR4, DR3, NOTDR2, DR1, NOTDR0, V_WB_LDREG);
and(Reg27Enable, DR4, DR3, NOTDR2, DR1, DR0, V_WB_LDREG);
and(Reg28Enable, DR4, DR3, DR2, NOTDR1, NOTDR0, V_WB_LDREG);
and(Reg29Enable, DR4, DR3, DR2, NOTDR1, DR0, V_WB_LDREG);
and(Reg30Enable, DR4, DR3, DR2, DR1, NOTDR0, V_WB_LDREG);
and(Reg31Enable, DR4, DR3, DR2, DR1, DR0, V_WB_LDREG);

reg32_en_reset Reg0(WB_DATA, clock, Reg0Enable, reset, 32'b00000000000000000000000000000000,Reg0Value);
reg32_en_reset Reg1(WB_DATA, clock, Reg1Enable, reset, 32'b00000000000000000000000000000000, Reg1Value);
reg32_en_reset Reg2(WB_DATA, clock, Reg2Enable, reset, 32'b00000000000000000000000000000000, Reg2Value);
reg32_en_reset Reg3(WB_DATA, clock, Reg3Enable, reset, 32'b00000000000000000000000000000000, Reg3Value);
reg32_en_reset Reg4(WB_DATA, clock, Reg4Enable, reset, 32'b00000000000000000000000000000000, Reg4Value);
reg32_en_reset Reg5(WB_DATA, clock, Reg5Enable, reset, 32'b00000000000000000000000000000000, Reg5Value);
reg32_en_reset Reg6(WB_DATA, clock, Reg6Enable, reset, 32'b00000000000000000000000000000000, Reg6Value);
reg32_en_reset Reg7(WB_DATA, clock, Reg7Enable, reset, 32'b00000000000000000000000000000000, Reg7Value);
reg32_en_reset Reg8(WB_DATA, clock, Reg8Enable, reset, 32'b00000000000000000000000000000000, Reg8Value);
reg32_en_reset Reg9(WB_DATA, clock, Reg9Enable, reset, 32'b00000000000000000000000000000000, Reg9Value);
reg32_en_reset Reg10(WB_DATA, clock, Reg10Enable, reset, 32'b00000000000000000000000000000000, Reg10Value);
reg32_en_reset Reg11(WB_DATA, clock, Reg11Enable, reset, 32'b00000000000000000000000000000000, Reg11Value);
reg32_en_reset Reg12(WB_DATA, clock, Reg12Enable, reset, 32'b00000000000000000000000000000000, Reg12Value);
reg32_en_reset Reg13(WB_DATA, clock, Reg13Enable, reset, 32'b00000000000000000000000000000000, Reg13Value);
reg32_en_reset Reg14(WB_DATA, clock, Reg14Enable, reset, 32'b00000000000000000000000000000000, Reg14Value);
reg32_en_reset Reg15(WB_DATA, clock, Reg15Enable, reset, 32'b00000000000000000000000000000000, Reg15Value);
reg32_en_reset Reg16(WB_DATA, clock, Reg16Enable, reset, 32'b00000000000000000000000000000000, Reg16Value);
reg32_en_reset Reg17(WB_DATA, clock, Reg17Enable, reset, 32'b00000000000000000000000000000000, Reg17Value);
reg32_en_reset Reg18(WB_DATA, clock, Reg18Enable, reset, 32'b00000000000000000000000000000000, Reg18Value);
reg32_en_reset Reg19(WB_DATA, clock, Reg19Enable, reset, 32'b00000000000000000000000000000000, Reg19Value);
reg32_en_reset Reg20(WB_DATA, clock, Reg20Enable, reset, 32'b00000000000000000000000000000000, Reg20Value);
reg32_en_reset Reg21(WB_DATA, clock, Reg21Enable, reset, 32'b00000000000000000000000000000000, Reg21Value);
reg32_en_reset Reg22(WB_DATA, clock, Reg22Enable, reset, 32'b00000000000000000000000000000000, Reg22Value);
reg32_en_reset Reg23(WB_DATA, clock, Reg23Enable, reset, 32'b00000000000000000000000000000000, Reg23Value);
reg32_en_reset Reg24(WB_DATA, clock, Reg24Enable, reset, 32'b00000000000000000000000000000000, Reg24Value);
reg32_en_reset Reg25(WB_DATA, clock, Reg25Enable, reset, 32'b00000000000000000000000000000000, Reg25Value);
reg32_en_reset Reg26(WB_DATA, clock, Reg26Enable, reset, 32'b00000000000000000000000000000000, Reg26Value);
reg32_en_reset Reg27(WB_DATA, clock, Reg27Enable, reset, 32'b00000000000000000000000000000000, Reg27Value);
reg32_en_reset Reg28(WB_DATA, clock, Reg28Enable, reset, 32'b00000000000000000000000000000000, Reg28Value);
reg32_en_reset Reg29(WB_DATA, clock, Reg29Enable, reset, 32'b00000000000000000000000000000000, Reg29Value);    
reg32_en_reset Reg30(WB_DATA, clock, Reg30Enable, reset, 32'b00000000000000000000000000000000, Reg30Value);
reg32_en_reset Reg31(WB_DATA, clock, Reg31Enable, reset, 32'b00000000000000000000000000000000, Reg31Value);

mux32_32bit Mux1(Reg0Value, Reg1Value, Reg2Value, Reg3Value, Reg4Value, Reg5Value, Reg6Value, Reg7Value, Reg8Value, Reg9Value, Reg10Value, Reg11Value, Reg12Value, Reg13Value, Reg14Value, Reg15Value, Reg16Value, Reg17Value, Reg18Value, Reg19Value, Reg20Value, Reg21Value, Reg22Value, Reg23Value, Reg24Value, Reg25Value, Reg26Value, Reg27Value, Reg28Value, Reg29Value, Reg30Value, Reg31Value, S1Reg, intermediateone);
mux32_32bit Mux2(Reg0Value, Reg1Value, Reg2Value, Reg3Value, Reg4Value, Reg5Value, Reg6Value, Reg7Value, Reg8Value, Reg9Value, Reg10Value, Reg11Value, Reg12Value, Reg13Value, Reg14Value, Reg15Value, Reg16Value, Reg17Value, Reg18Value, Reg19Value, Reg20Value, Reg21Value, Reg22Value, Reg23Value, Reg24Value, Reg25Value, Reg26Value, Reg27Value, Reg28Value, Reg29Value, Reg30Value, Reg31Value, S2Reg, intermediatetwo);

fivebitcomparator FiveBitComparator1(S1Reg, WB_DR, equalone);
and(overrideone, equalone, V_WB_LDREG);
fivebitcomparator FiveBitComparator2(S2Reg, WB_DR, equaltwo);
and(overridetwo, equaltwo, V_WB_LDREG);

mux2_32bit Mux3(intermediateone, WB_DATA, overrideone, S1Value);
mux2_32bit Mux4(intermediatetwo, WB_DATA, overridetwo, S2Value);

endmodule
