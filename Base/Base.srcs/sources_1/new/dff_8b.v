module dff_8b (
    input [7:0] data,
    input clk, we, rst,
    output [7:0] out
);

    genvar i;
    generate
        for (i=0; i<8; i=i+1) begin
            dff_en_reset dff1 (data[i], clk, we, rst, 1'b0, out[i]);
        end
    endgenerate
    
endmodule