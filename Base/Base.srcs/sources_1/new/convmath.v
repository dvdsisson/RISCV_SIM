module convmath (
    input clk, reset, compute,
    input [31:0] a, b0, b1, b2, b3,
    output [71:0] out
);

    wire [31:0] matrix [0:3];
    wire [31:0] im2col [0:8];


    assign matrix[0] = b0;
    assign matrix[1] = b1;
    assign matrix[2] = b2;
    assign matrix[3] = b3;

    genvar i,j;
    generate
        for (i=0; i<3; i=i+1) begin
            for (j=0; j<3; j=j+1) begin
                assign im2col[i*3+2-j] = {matrix[i][8*j+15:8*j], matrix[i+1][8*j+15:8*j]};
            end
        end
    endgenerate


    wire [7:0] macout [0:8];
    wire [7:0] dffout [0:8];
    wire [7:0] sumout [0:8];
    generate
        for (i=0; i<9; i=i+1) begin
            mac_8b mac1 (a, im2col[i], macout[i]);
            satadd satadd1 (macout[i], dffout[i], sumout[i]);
            dff_8b dff1 (sumout[i], clk, compute, reset, dffout[i]);
        end
    endgenerate

    assign out = {dffout[0], dffout[1], dffout[2], dffout[3], dffout[4], dffout[5], dffout[6], dffout[7], dffout[8]};

endmodule