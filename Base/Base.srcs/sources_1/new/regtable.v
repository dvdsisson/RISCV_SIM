module regtable (
    input clk, reset,
    input [4:0] readindex,
    output [31:0] readdataout,

    input writeenable,
    input [4:0] writeindex,
    input [31:0] datain
    // output [31:0] writedataout
);
    
    wire [31:0] index, we;
    wire [31:0] stored [0:31];

    fivebitdecoder dec1 (sel, index);

    genvar i;

    generate
        for (i=0; i<32; i=i+1) begin
            and (we[i], sel[i], writeenable);
            reg32_en_reset regs1 (datain, clk, we[i], reset, 32'b0, stored[i]);
        end    
    endgenerate


    mux32_32b mux1 (
        stored[0],
        stored[1],
        stored[2],
        stored[3],
        stored[4],
        stored[5],
        stored[6],
        stored[7],
        stored[8],
        stored[9],
        stored[10],
        stored[11],
        stored[12],
        stored[13],
        stored[14],
        stored[15],
        stored[16],
        stored[17],
        stored[18],
        stored[19],
        stored[20],
        stored[21],
        stored[22],
        stored[23],
        stored[24],
        stored[25],
        stored[26],
        stored[27],
        stored[28],
        stored[29],
        stored[30],
        stored[31],
        readindex,
        readdataout
    );

    // mux32_32b mux2 (
    //     stored[0],
    //     stored[1],
    //     stored[2],
    //     stored[3],
    //     stored[4],
    //     stored[5],
    //     stored[6],
    //     stored[7],
    //     stored[8],
    //     stored[9],
    //     stored[10],
    //     stored[11],
    //     stored[12],
    //     stored[13],
    //     stored[14],
    //     stored[15],
    //     stored[16],
    //     stored[17],
    //     stored[18],
    //     stored[19],
    //     stored[20],
    //     stored[21],
    //     stored[22],
    //     stored[23],
    //     stored[24],
    //     stored[25],
    //     stored[26],
    //     stored[27],
    //     stored[28],
    //     stored[29],
    //     stored[30],
    //     stored[31],
    //     index,
    //     dataout
    // );

endmodule