module twobittable (
    input clk, reset,
    input [4:0] readindex,
    output predout,

    input writeenable, 
    input [4:0] writeindex,
    input inc 
    // output out
);
    
    wire [31:0] we, sel;
    wire [31:0] stored;

    fivebitdecoder dec1 (sel, writeindex);

    genvar i;

    generate
        for (i=0; i<32; i=i+1) begin
            and a1(we[i], sel[i], writeenable);
            twobitcounter regs1 (clk, we[i], inc, reset, stored[i]);
        end    
    endgenerate

    mux32_32bit mux1 (
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
        predout
    );

    // mux32_32bit mux2 (
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