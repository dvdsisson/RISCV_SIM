`timescale 1ns / 1ps

module shifter(
    input [31:0] value,
    input [4:0] shift,
    output [31:0] logicalrightresult,
    output [31:0] arithmeticrightresult,
    output [31:0] logicalleftresult
    );

logicalrightshifter(value, shift, logicalrightresult);
arithmeticrightshifter(value, shift, arithmeticrightresult);
logicalleftshifter(value, shift, logicalleftresult);

endmodule
