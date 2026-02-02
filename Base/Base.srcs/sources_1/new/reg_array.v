`timescale 1ns / 1ps

module reg_array

   #(parameter reg_length = 32) (
    input clock,
    input [4:0] ReadReg,
    output [reg_length-1:0] ReadOut,
    input WriteEn,
    input [4:0] WriteReg,
    input [reg_length-1:0] WriteData
    );

wire [31:0] regEnable, writeDecode;

fivebitdecoder dec1 (writeDecode, WriteReg);

genvar i;

generate
    for (i=0; i<32; i=i+1): begin
        and (regEnable[i], WriteEn, writeDecode[i]);       
    end
endgenerate

reg_en Reg0  #(.width(reg_length)) (WriteData,  clock,  regEnable[0],    Reg0Value);
reg_en Reg1  #(.width(reg_length)) (WriteData,  clock,  regEnable[1],    Reg1Value);
reg_en Reg2  #(.width(reg_length)) (WriteData,  clock,  regEnable[2],    Reg2Value);
reg_en Reg3  #(.width(reg_length)) (WriteData,  clock,  regEnable[3],    Reg3Value);
reg_en Reg4  #(.width(reg_length)) (WriteData,  clock,  regEnable[4],    Reg4Value);
reg_en Reg5  #(.width(reg_length)) (WriteData,  clock,  regEnable[5],    Reg5Value);
reg_en Reg6  #(.width(reg_length)) (WriteData,  clock,  regEnable[6],    Reg6Value);
reg_en Reg7  #(.width(reg_length)) (WriteData,  clock,  regEnable[7],    Reg7Value);
reg_en Reg8  #(.width(reg_length)) (WriteData,  clock,  regEnable[8],    Reg8Value);
reg_en Reg9  #(.width(reg_length)) (WriteData,  clock,  regEnable[9],    Reg9Value);
reg_en Reg10 #(.width(reg_length)) (WriteData,  clock,  regEnable[10],   Reg10Value);
reg_en Reg11 #(.width(reg_length)) (WriteData,  clock,  regEnable[11],   Reg11Value);
reg_en Reg12 #(.width(reg_length)) (WriteData,  clock,  regEnable[12],   Reg12Value);
reg_en Reg13 #(.width(reg_length)) (WriteData,  clock,  regEnable[13],   Reg13Value);
reg_en Reg14 #(.width(reg_length)) (WriteData,  clock,  regEnable[14],   Reg14Value);
reg_en Reg15 #(.width(reg_length)) (WriteData,  clock,  regEnable[15],   Reg15Value);
reg_en Reg16 #(.width(reg_length)) (WriteData,  clock,  regEnable[16],   Reg16Value);
reg_en Reg17 #(.width(reg_length)) (WriteData,  clock,  regEnable[17],   Reg17Value);
reg_en Reg18 #(.width(reg_length)) (WriteData,  clock,  regEnable[18],   Reg18Value);
reg_en Reg19 #(.width(reg_length)) (WriteData,  clock,  regEnable[19],   Reg19Value);
reg_en Reg20 #(.width(reg_length)) (WriteData,  clock,  regEnable[20],   Reg20Value);
reg_en Reg21 #(.width(reg_length)) (WriteData,  clock,  regEnable[21],   Reg21Value);
reg_en Reg22 #(.width(reg_length)) (WriteData,  clock,  regEnable[22],   Reg22Value);
reg_en Reg23 #(.width(reg_length)) (WriteData,  clock,  regEnable[23],   Reg23Value);
reg_en Reg24 #(.width(reg_length)) (WriteData,  clock,  regEnable[24],   Reg24Value);
reg_en Reg25 #(.width(reg_length)) (WriteData,  clock,  regEnable[25],   Reg25Value);
reg_en Reg26 #(.width(reg_length)) (WriteData,  clock,  regEnable[26],   Reg26Value);
reg_en Reg27 #(.width(reg_length)) (WriteData,  clock,  regEnable[27],   Reg27Value);
reg_en Reg28 #(.width(reg_length)) (WriteData,  clock,  regEnable[28],   Reg28Value);
reg_en Reg29 #(.width(reg_length)) (WriteData,  clock,  regEnable[29],   Reg29Value);    
reg_en Reg30 #(.width(reg_length)) (WriteData,  clock,  regEnable[30],   Reg30Value);
reg_en Reg31 #(.width(reg_length)) (WriteData,  clock,  regEnable[31],   Reg31Value);

mux32_nbit #(.reg_length(reg_length)) (Reg0Value, Reg1Value, Reg2Value, Reg3Value, Reg4Value, Reg5Value, Reg6Value, Reg7Value, Reg8Value, Reg9Value, Reg10Value, Reg11Value, Reg12Value, Reg13Value, Reg14Value, Reg15Value, Reg16Value, Reg17Value, Reg18Value, Reg19Value, Reg20Value, Reg21Value, Reg22Value, Reg23Value, Reg24Value, Reg25Value, Reg26Value, Reg27Value, Reg28Value, Reg29Value, Reg30Value, Reg31Value, ReadReg, ReadOut);

endmodule
