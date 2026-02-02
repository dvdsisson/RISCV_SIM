`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/02/2026 07:33:43 AM
// Design Name: 
// Module Name: counter_array
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


module counter_array(

    input clk,
    input [4:0] ReadReg,
    output out,
    input WriteEn,
    input [4:0] WriteReg,
    input inc

    );

    wire [31:0] cntEn, writeDecode;

    fivebitdecoder dec1 (writeDecode, WriteReg);

    genvar i;

    generate
        for (i=0; i<32; i=i+1): begin
            and (cntEn[i], WriteEn, writeDecode[i]);       
        end
    endgenerate

    twobitcounter cnt0  (inc,  clock,  cntEn[0],    Reg0Value);
    twobitcounter cnt1  (inc,  clock,  cntEn[1],    Reg1Value);
    twobitcounter cnt2  (inc,  clock,  cntEn[2],    Reg2Value);
    twobitcounter cnt3  (inc,  clock,  cntEn[3],    Reg3Value);
    twobitcounter cnt4  (inc,  clock,  cntEn[4],    Reg4Value);
    twobitcounter cnt5  (inc,  clock,  cntEn[5],    Reg5Value);
    twobitcounter cnt6  (inc,  clock,  cntEn[6],    Reg6Value);
    twobitcounter cnt7  (inc,  clock,  cntEn[7],    Reg7Value);
    twobitcounter cnt8  (inc,  clock,  cntEn[8],    Reg8Value);
    twobitcounter cnt9  (inc,  clock,  cntEn[9],    Reg9Value);
    twobitcounter cnt10 (inc,  clock,  cntEn[10],   Reg10Value);
    twobitcounter cnt11 (inc,  clock,  cntEn[11],   Reg11Value);
    twobitcounter cnt12 (inc,  clock,  cntEn[12],   Reg12Value);
    twobitcounter cnt13 (inc,  clock,  cntEn[13],   Reg13Value);
    twobitcounter cnt14 (inc,  clock,  cntEn[14],   Reg14Value);
    twobitcounter cnt15 (inc,  clock,  cntEn[15],   Reg15Value);
    twobitcounter cnt16 (inc,  clock,  cntEn[16],   Reg16Value);
    twobitcounter cnt17 (inc,  clock,  cntEn[17],   Reg17Value);
    twobitcounter cnt18 (inc,  clock,  cntEn[18],   Reg18Value);
    twobitcounter cnt19 (inc,  clock,  cntEn[19],   Reg19Value);
    twobitcounter cnt20 (inc,  clock,  cntEn[20],   Reg20Value);
    twobitcounter cnt21 (inc,  clock,  cntEn[21],   Reg21Value);
    twobitcounter cnt22 (inc,  clock,  cntEn[22],   Reg22Value);
    twobitcounter cnt23 (inc,  clock,  cntEn[23],   Reg23Value);
    twobitcounter cnt24 (inc,  clock,  cntEn[24],   Reg24Value);
    twobitcounter cnt25 (inc,  clock,  cntEn[25],   Reg25Value);
    twobitcounter cnt26 (inc,  clock,  cntEn[26],   Reg26Value);
    twobitcounter cnt27 (inc,  clock,  cntEn[27],   Reg27Value);
    twobitcounter cnt28 (inc,  clock,  cntEn[28],   Reg28Value);
    twobitcounter cnt29 (inc,  clock,  cntEn[29],   Reg29Value);    
    twobitcounter cnt30 (inc,  clock,  cntEn[30],   Reg30Value);
    twobitcounter cnt31 (inc,  clock,  cntEn[31],   Reg31Value);

    mux32_nbit #(.reg_length(2)) (Reg0Value, Reg1Value, Reg2Value, Reg3Value, Reg4Value, Reg5Value, Reg6Value, Reg7Value, Reg8Value, Reg9Value, Reg10Value, Reg11Value, Reg12Value, Reg13Value, Reg14Value, Reg15Value, Reg16Value, Reg17Value, Reg18Value, Reg19Value, Reg20Value, Reg21Value, Reg22Value, Reg23Value, Reg24Value, Reg25Value, Reg26Value, Reg27Value, Reg28Value, Reg29Value, Reg30Value, Reg31Value, ReadReg, out);




endmodule
