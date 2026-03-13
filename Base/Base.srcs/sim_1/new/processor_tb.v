`timescale 1ns / 1ps

module processor_tb;

    reg clock;
    reg reset;

    // Initializing Processor
    processor uut (
        .clock(clock),
        .reset(reset)
    );

    // Clock (10 Nanosecond Period)
    always #5 clock = ~clock;

    initial begin
        
        clock = 0;
        reset = 1;         

	// Forcing Pipeline Signals Low Until In Control Of Pipeline
	force uut.ID_BR_STALL = 1'b0;
	force uut.DEP_STALL = 1'b0;
	force uut.EX_BR_STALL = 1'b0;
	force uut.EX_STALL = 1'b0;
	force uut.JMP_PCMUX = 1'b0;
	force uut.MEM_STALL = 1'b0;
	force uut.V_EX_LDREG = 1'b0;
	force uut.V_MEM_LDREG = 1'b0;
	force uut.V_WB_LDREG = 1'b0;
	force uut.ID_VALID_Output = 1'b0;
	force uut.EX_VALID_Output = 1'b0;
	force uut.MEM_VALID_Output = 1'b0;
	force uut.WB_VALID_Output = 1'b0;
	force uut.EX_DR = 5'b00000;
	force uut.MEM_DR = 5'b00000;
	force uut.WB_DR = 5'b00000;
        #10;
        reset = 0;

        // Loading Program Into Memory (INPUT DESIRED PROGRAM FILE HERE)
        $readmemh("program.mem", uut.Memory.mem_array, 16'h3000);
        // Loading Data Files Into Memory (INPUT DESIRED DATA FILE HERE)
	$readmemh("data.mem", uut.Memory.mem_array, 16'h3030);

        // Releasing Pipeline Signals Now In Control Of Pipeline
	
        release uut.ID_VALID_Output;
	#10

	release uut.ID_BR_STALL;
	release uut.DEP_STALL;
	release uut.EX_VALID_Output;
	#10
	
	release uut.EX_BR_STALL;
	release uut.EX_STALL;
	release uut.JMP_PCMUX;
	release uut.V_EX_LDREG;
	release uut.MEM_VALID_Output;
	release uut.EX_DR;
	#10 

	release uut.MEM_STALL;
	release uut.V_MEM_LDREG;
	release uut.WB_VALID_Output;
	release uut.MEM_DR;
	#10

	release uut.V_WB_LDREG;
	release uut.WB_DR;
        #250; // INPUT DESIRED RUNTIME IN NANOSECONDS HERE

        $finish;

    end


    // Displaying Pipeline And Register Information By Cycle Here
    integer cycle = -1;
    always @(posedge clock) begin
	cycle <= cycle + 1;
        $display("-----------------------------------------");
        $display("Cycle: %0d  PC: %h",
                 cycle,
                 uut.ID_PC_Input);
        $display("Stalls: dep_stall=%b, ex_stall=%b, mem_stall=%b, id_br_stall=%b, ex_br_stall=%b, icache_r=%b, dcache_r=%b, jmp_pcmux=%b",
                 uut.DEP_STALL,
		 uut.EX_STALL,
		 uut.MEM_STALL,
		 uut.ID_BR_STALL,
		 uut.EX_BR_STALL,
		 1'b1,
		 1'b1,
                 uut.JMP_PCMUX);
        $display("IF: V=%b, PC=%h, IR=%h",
                 uut.ID_VALID_Output,
		 uut.ID_PC_Output,
		 uut.ID_IR_Output);
        $display("ID: V=%b, PC=%h, RS1=%h, RS2=%h, IMM=%h, RD=%0d",
                 uut.EX_VALID_Output,
		 uut.EX_PC_Output,
		 uut.EX_SR1_Output,
		 uut.EX_SR2_Output,
		 uut.EX_IV_Output,
		 uut.EX_DR_Output[4:0]);
        $display("EX: V=%b, PC=%h, ALU=%h, TA=%h, RD=%0d",
                 uut.MEM_VALID_Output,
		 uut.MEM_PC_Output,
		 uut.MEM_ALU_Output,
		 uut.MEM_TA_Output,
		 uut.MEM_DR_Output[4:0]);
        $display("MEM: V=%b, PC=%h, ALU=%h, DATA=%h, RD=%0d",
                 uut.WB_VALID_Output,
		 uut.WB_PC_Output,
		 uut.WB_ALU_Output,
		 uut.WB_MEM_Output,
		 uut.WB_DR_Output[4:0]);
        $display("R0=%h R1=%h R2=%h R3=%h",
                 uut.RegisterFile.Reg0Value,
		 uut.RegisterFile.Reg1Value,
		 uut.RegisterFile.Reg2Value,
		 uut.RegisterFile.Reg3Value);
        $display("R4=%h R5=%h R6=%h R7=%h",
                 uut.RegisterFile.Reg4Value,
		 uut.RegisterFile.Reg5Value,
		 uut.RegisterFile.Reg6Value,
		 uut.RegisterFile.Reg7Value);
        $display("R8=%h R9=%h R10=%h R11=%h",
                 uut.RegisterFile.Reg8Value,
		 uut.RegisterFile.Reg9Value,
		 uut.RegisterFile.Reg10Value,
		 uut.RegisterFile.Reg11Value);
        $display("R12=%h 13=%h R14=%h R15=%h",
                 uut.RegisterFile.Reg12Value,
		 uut.RegisterFile.Reg13Value,
		 uut.RegisterFile.Reg14Value,
		 uut.RegisterFile.Reg15Value);
        $display("R16=%h R17=%h R18=%h R19=%h",
                 uut.RegisterFile.Reg16Value,
		 uut.RegisterFile.Reg17Value,
		 uut.RegisterFile.Reg18Value,
		 uut.RegisterFile.Reg19Value);
        $display("R20=%h R21=%h R22=%h R23=%h",
                 uut.RegisterFile.Reg20Value,
		 uut.RegisterFile.Reg21Value,
		 uut.RegisterFile.Reg22Value,
		 uut.RegisterFile.Reg23Value);
        $display("R24=%h R25=%h R26=%h R27=%h",
                 uut.RegisterFile.Reg24Value,
		 uut.RegisterFile.Reg25Value,
		 uut.RegisterFile.Reg26Value,
		 uut.RegisterFile.Reg27Value);
        $display("R28=%h R29=%h R30=%h R31=%h",
                 uut.RegisterFile.Reg28Value,
		 uut.RegisterFile.Reg29Value,
		 uut.RegisterFile.Reg30Value,
		 uut.RegisterFile.Reg31Value);
    end

endmodule