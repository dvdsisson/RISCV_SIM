module fc_conv_bias (
    input clk, start, ready, isFC, isConv,
    input [31:0] data,
    input [31:0] pxl_ptr, ker_ptr, bias_ptr, weight_ptr, out_ptr,
    input [31:0] max_x, max_y, linesize, max_ch,
    output [31:0] mem_ptr,
    output mem_req, done,
    output [31:0] out
);

// isFC, clk, start, ready,
//     input [31:0] max_x, max_y, linesize, pxl_ptr, ker_ptr, bias_ptr, weight_ptr, out_ptr, max_ch, 
//     output reg reset, fc_write, r3write, conv_compute,
//     output reg [31:0] mem_ptr,
//     output reg [1:0] banksel, colsel, regsel,
//     output reg done, mem_req


    wire reset, fc_write, r3write, conv_compute;
    wire [1:0] banksel, colsel, regsel;

    FSMController fsm (isFC, isConv, clk, start, ready, max_x, max_y, pxl_ptr, ker_ptr, bias_ptr, weight_ptr, out_ptr, max_ch, reset, fc_write, r3write, conv_compute, mem_ptr, banksel, colsel, regsel, done, mem_req);
    fc_bias f1 (clk, isFC, conv_compute, fc_write, reset, ready, banksel, regsel, data, r3write, out);
    
endmodule