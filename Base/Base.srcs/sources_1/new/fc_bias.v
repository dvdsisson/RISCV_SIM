module fc_bias (
    input clk, isFC, conv_compute, write, reset, ready, banksel,
    input [1:0] regsel,
    input [31:0] data,
    input r3store,
    output [31:0] out
);
    wire [3:0] we;
    wire [1:0] regselinv;
    wire invFC, invbanksel;

    genvar i;
    generate
        for (i = 0; i < 2; i = i+1) begin
            inv1$ i1 (regselinv[i], regsel[i]);
        end
    endgenerate
    inv1$ i2 (invFC, isFC);
    inv1$ i3 (invbanksel, banksel);

    // inv logic to save time
    nor2$ n1 (we[0], regsel[1],    regsel[0]);
    nor2$ n2 (we[1], regsel[1],    regselinv[0]);
    nor2$ n3 (we[2], regselinv[1], regsel[0]);
    nor2$ n4 (we[3], regselinv[1], regselinv[0]);

    wire [3:0] reg1we;
    generate
        for (i = 0; i < 4; i = i+1) begin
            and2$ a1 (reg1we[i], invFC, we[i]);
        end
    endgenerate




    wire [31:0] reg1out [0:3];
    wire [31:0] reg2out [0:3];
    wire [31:0] reg3out [0:3];
    wire [3:0] reg1en, reg1intermediate;
    wire [3:0] reg2en;
    wire [3:0] reg3en;
    wire reg1override;

    nor2$ n5 (reg1override, banksel, invFC); //high if bank = 0 & isFC


    // and2$ a1 (reg1intermediate[0], we[0], invbanksel);
    
    generate
        for (i = 1; i < 4; i=i+1) begin
            nand3$ n5 (reg1intermediate[i], we[i], invbanksel, write); //and + inv
            nor2$ n6 (reg1en[i], reg1intermediate[i], reg1override); // bank & we & !override
        end
        for (i = 0; i < 4; i=i+1) begin
            and3$ a2 (reg2en[i], we[i], write, banksel);
        end
        for (i = 0; i < 3; i=i+1) begin
            and3$ a3 (reg3en[i], we[i+1], 1'b1, r3store); //???
        end
        and3$ a3p2 (reg3en[3], we[0], 1'b1, r3store); //???
    endgenerate

    and3$ a4 (reg1intermediate[0], we[0], invbanksel, write);
    or2$ o1 (reg1en[0], reg1override, reg1intermediate[0]); // bank & we || override

    wire [31:0] mathout;

    wire [1:0] mathregsel1, mathregsel;

    assign mathregsel = regsel - 1;
    assign mathregsel1 = isFC ? 2'b0 : mathregsel; // & {!reg1override, !reg1override};


    generate
        for (i = 0; i < 4; i = i + 1) begin
            reg32_en_reset reg1 (data, clk, reg1en[i], reset, 32'b0, reg1out[i]);
            reg32_en_reset reg2 (data, clk, reg2en[i], reset, 32'b0, reg2out[i]);
            reg32_en_reset reg3 (mathout, clk, reg3en[i], reset, 32'b0, reg3out[i]);
        end
    endgenerate 



    wire [31:0] reg1op, reg2op, reg3op;
    wire [1:0] regsel1;

    and2$ and10 (regsel1[1], regsel[1], invFC);
    and2$ and11 (regsel1[0], regsel[0], invFC);



    mux4_32bit mux1 (reg1out[0], reg1out[1], reg1out[2], reg1out[3], mathregsel1, reg1op);
    mux4_32bit mux2 (reg2out[0], reg2out[1], reg2out[2], reg2out[3], mathregsel, reg2op);
    mux4_32bit mux3 (reg3out[0], reg3out[1], reg3out[2], reg3out[3], mathregsel, reg3op);
    

    // wire [31:0] opB, opC;

    // wire [7:0] mac_out [0:3];

    // mux2_32bit mux4 (reg2op, 32'h01010101, isFC, opB);
    // mux2_32bit mux5 (32'h0, reg2op, isFC, opC);

    // generate
    //     for (i = 0; i < 8; i = i+1) begin
    //         mac_8b mac1 (reg1op[7+i*8:i*8], opB[7+i*8:i*8], opC[7+i*8:i*8], mac_out[i]); // Should trap for overflow (just a saturating mux)
    //     end
    // endgenerate

    // wire [7:0] intermediate_s1 [1:0];
    // wire [7:0] intermediate_s2, intermediate_s3;   


    wire [7:0] macout, fcaddout, fcout;
    wire macoverflow;
    mac_8b mac1 (reg1op, reg2op, macout);
    eightbitadder add1 (macout, reg3op, 1'b0, fcaddout, macoverflow);
    mux2_8b mux4 (fcaddout, 8'hFF, macoverflow, fcout);

    wire [31:0] packaddout;
    packadd pack1 (reg1op, reg2op, packaddout);

    mux2_32bit mux5 (packaddout, {24'b0, fcout}, isFC, mathout); //mac out instead of 0


    mux2_32bit mux6 (reg3op, {reg3out[3][7:0],reg3out[2][7:0],reg3out[1][7:0],reg3out[0][7:0]}, isFC, out);


    wire [71:0] convout;

    convmath Convolution (clk, reset, conv_compute, reg1out[0], reg2out[0], reg2out[1], reg2out[2], reg2out[3], convout);
    
    

endmodule