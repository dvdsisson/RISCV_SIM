module fc_conv_bias (
    input clk, start, isFC, isConv,
    input [31:0] data,
    input [31:0] pxl_ptr, ker_ptr, bias_ptr, weight_ptr, out_ptr,
    input [31:0] max_x, max_y, size, cols, max_ch,
    output [31:0] mem_ptr,
    output mem_wr, done,
    output [31:0] out,
    output write_byte //1=bytes, 0=words
);

// isFC, clk, start, ready,
//     input [31:0] max_x, max_y, linesize, pxl_ptr, ker_ptr, bias_ptr, weight_ptr, out_ptr, max_ch, 
//     output reg reset, fc_write, r3write, conv_compute,
//     output reg [31:0] mem_ptr,
//     output reg [1:0] banksel, colsel, regsel,
//     output reg done, mem_req


    wire reset, fc_write, r3write, conv_compute, convreset;
    wire [1:0] banksel, colsel, regsel;

    FSMController fsm (isFC, isConv, clk, start, max_x, max_y, size, cols, pxl_ptr, ker_ptr, bias_ptr, weight_ptr, out_ptr, max_ch, reset, fc_write, r3write, conv_compute, mem_ptr, banksel, colsel, regsel, done, mem_wr, write_byte, convreset);
    fc_bias f1 (clk, isFC, isConv, conv_compute, fc_write, reset, ready, banksel, colsel, regsel, data, r3write, convreset, out);

endmodule