#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

/***************************************************************/
/*  Global definitions                                          */
/***************************************************************/
#define TRUE  1
#define FALSE 0
#define Low32bits(x) ((x)&0xFFFFFFFF)

#define NUM_CONTROL_STORE_ROWS   45
#define NUM_CONTROL_SIGNALS      24
#define WORDS_IN_MEM             0x100000  //4 MB

/***************************************************************/
/*  Architectural state                                         */
/***************************************************************/
uint32_t PC = 0x0;
uint32_t REGS[32];
int      RUN_BIT = TRUE;
int      CYCLE_COUNT = 0;

int dep_stall;
int ex_stall;
int mem_stall;
int id_br_stall;
int ex_br_stall;
int icache_r;
int dcache_r;

/***************************************************************/
/*  Main memory and control store                              */
/***************************************************************/
int CONTROL_STORE[NUM_CONTROL_STORE_ROWS][NUM_CONTROL_SIGNALS];
uint8_t MEMORY[WORDS_IN_MEM][4];   /* byte-addressable */

/***************************************************************/
/*  Pipeline register structure                                 */
/***************************************************************/
typedef struct {
    // IF/ID 
    uint32_t IF_PC, IF_IR;
    int      IF_V;

    // ID/EX 
    uint32_t ID_PC, ID_IR, ID_RS1, ID_RS2, ID_IMM;
    int      ID_RD, ID_V;
    int      ID_CS[NUM_CONTROL_SIGNALS];

    // EX/MEM 
    uint32_t EX_PC, EX_IR, EX_ALU_RESULT, EX_TA;
    int      EX_RD, EX_V;
    int      EX_CS[NUM_CONTROL_SIGNALS];

    // MEM/WB 
    uint32_t MEM_PC, MEM_IR, MEM_ALU_RESULT, MEM_DATA;
    int      MEM_RD, MEM_V;
    int      MEM_CS[NUM_CONTROL_SIGNALS];
} PipeState;

PipeState PS, NEW_PS;


enum {
    CS_SR1_NEEDED,
    CS_SR2_NEEDED,
    CS_IV2, CS_IV1, CS_IV0,
    CS_BR_STALL,
    CS_LDREG,
    CS_TA_MUX,
    CS_ALU_MUX,
    CS_ALU_OP4, CS_ALU_OP3, CS_ALU_OP2, CS_ALU_OP1, CS_ALU_OP0,
    CS_ALU_RESULT_MUX,
    CS_COMP_OP2, CS_COMP_OP1, CS_COMP_OP0,
    CS_LDST,
    CS_LDST_OP2, CS_LDST_OP1, CS_LDST_OP0,
    CS_WB_MUX1, CS_WB_MUX0,
    NUM_CS_FIELDS
};


/***************************************************************/
/*  Prototypes for pipeline stages           */
/***************************************************************/
void IF_stage(void);
void ID_stage(void);
void EX_stage(void);
void MEM_stage(void);
void WB_stage(void);

/***************************************************************/
/*  Control Store Loader                                        */
/***************************************************************/
void init_control_store(char *filename) {
    FILE *fp = fopen(filename, "r");
    if (!fp) {
        printf("ERROR: Cannot open control store file %s\n", filename);
        exit(1);
    }
    char line[512];
    int row = 0;
    while (fgets(line, sizeof(line), fp) && row < NUM_CONTROL_STORE_ROWS) {
        char *token = strtok(line, ",");
        int col = 0;
        while (token && col < NUM_CONTROL_SIGNALS) {
            CONTROL_STORE[row][col++] = atoi(token);
            token = strtok(NULL, ",");
        }
        row++;
    }
    fclose(fp);
    printf("Loaded %d control store rows from %s\n", row, filename);
}

/***************************************************************/
/*  Memory helpers and I/O functions                            */
/***************************************************************/
void init_memory(void) {
    memset(MEMORY, 0, sizeof(MEMORY));
}

void load_program(char *filename) {
    FILE *prog = fopen(filename, "r");
    if (!prog) {
        printf("Error: Can't open program file %s\n", filename);
        exit(-1);
    }
    unsigned int address = 0, word;
    int base_addr_set = 0;
    while (fscanf(prog, "%x", &word) != EOF) {
        if (!base_addr_set) { address = word; base_addr_set = 1; continue; }
        int idx = (address >> 2);
        MEMORY[idx][0] = word & 0xFF;
        MEMORY[idx][1] = (word >> 8) & 0xFF;
        MEMORY[idx][2] = (word >> 16) & 0xFF;
        MEMORY[idx][3] = (word >> 24) & 0xFF;
        address += 4;
    }
    fclose(prog);
    PC = 0x0;
    printf("Program loaded, start address 0x%08x\n", PC);
}

/***************************************************************/
/*  Instruction and Data Cache Access                           */
/***************************************************************/
void icache_access(uint32_t addr, uint32_t *instr, int *icache_r) {
    /*int miss = CYCLE_COUNT % 13 == 0;
    if (miss) { *icache_r = 0; *instr = 0x00000013; return; } // NOP*/
    *icache_r = 1;
    int idx = addr >> 2;
    *instr = (MEMORY[idx][3] << 24) | (MEMORY[idx][2] << 16) | (MEMORY[idx][1] << 8) | MEMORY[idx][0];
}

void dcache_access(uint32_t addr, uint32_t *read_word, uint32_t write_word,
                   int *dcache_r, int ldst_op) {
    /*int miss = CYCLE_COUNT % 11 == 0;
    if (miss) { *dcache_r = 0; return; }*/
    *dcache_r = 1;
    int index = addr >> 2;
    int remainder = addr % 4;
    if(ldst_op <= 4) {
        if(remainder == 0) {*(read_word) = (MEMORY[index][3] << 24) + (MEMORY[index][2] << 16) + (MEMORY[index][1] << 8) + (MEMORY[index][0]);}
        else if(remainder == 1) {*(read_word) = (MEMORY[index+1][0] << 24) + (MEMORY[index][3] << 16) + (MEMORY[index][2] << 8) + (MEMORY[index][1]);}
        else if(remainder == 2) {*(read_word) = (MEMORY[index+1][1] << 24) + (MEMORY[index+1][0] << 16) + (MEMORY[index][3] << 8) + (MEMORY[index][2]);}
        else if(remainder == 3) {*(read_word) = (MEMORY[index+1][2] << 24) + (MEMORY[index+1][1] << 16) + (MEMORY[index+1][0] << 8) + (MEMORY[index][3]);}
    }
    else if(ldst_op == 5) {
        MEMORY[index][remainder] = write_word & 0x000000FF;
    }
    else if(ldst_op == 6) {
        if(remainder == 0) {MEMORY[index][0] = write_word & 0x000000FF; MEMORY[index][1] = (write_word & 0x0000FF00) >> 8;}
        else if(remainder == 1) {MEMORY[index][1] = write_word & 0x000000FF; MEMORY[index][2] = (write_word & 0x0000FF00) >> 8;}
        else if(remainder == 2) {MEMORY[index][3] = write_word & 0x000000FF; MEMORY[index][4] = (write_word & 0x0000FF00) >> 8;}
        else if(remainder == 3) {MEMORY[index][3] = write_word & 0x000000FF; MEMORY[index+1][0] = (write_word & 0x0000FF00) >> 8;}
    }
    else if(ldst_op == 7) {
        if(remainder == 0) {MEMORY[index][0] = write_word & 0x000000FF; MEMORY[index][1] = (write_word & 0x0000FF00) >> 8; MEMORY[index][2] = (write_word & 0x00FF0000) >> 16; MEMORY[index][3] = (write_word & 0xFF000000) >> 24;}
        else if(remainder == 1) {MEMORY[index][1] = write_word & 0x000000FF; MEMORY[index][2] = (write_word & 0x0000FF00) >> 8; MEMORY[index][3] = (write_word & 0x00FF0000) >> 16; MEMORY[index+1][0] = (write_word & 0xFF000000) >> 24;}
        else if(remainder == 2) {MEMORY[index][2] = write_word & 0x000000FF; MEMORY[index][3] = (write_word & 0x0000FF00) >> 8; MEMORY[index+1][0] = (write_word & 0x00FF0000) >> 16; MEMORY[index+1][1] = (write_word & 0xFF000000) >> 24;}
        else if(remainder == 3) {MEMORY[index][3] = write_word & 0x000000FF; MEMORY[index+1][0] = (write_word & 0x0000FF00) >> 8; MEMORY[index+1][1] = (write_word & 0x00FF0000) >> 16; MEMORY[index+1][2] = (write_word & 0xFF000000) >> 24;}
    }
}


/*  Dumps and Console Commands           
/***************************************************************/
void mdump(FILE *dumpsim_file, int start, int stop) {
    printf("\nMemory content [0x%08x..0x%08x]\n", start, stop);
    for (int addr = (start >> 2); addr <= (stop >> 2); addr++) {
        printf(" 0x%08x : %02x %02x %02x %02x\n",
               addr << 2, MEMORY[addr][3], MEMORY[addr][2],
               MEMORY[addr][1], MEMORY[addr][0]);
        fprintf(dumpsim_file, "0x%08x : %02x %02x %02x %02x\n",
                addr << 2, MEMORY[addr][3], MEMORY[addr][2],
                MEMORY[addr][1], MEMORY[addr][0]);
    }
    fflush(dumpsim_file);
}

void rdump(FILE *dumpsim_file) {
    printf("\nCycle Count : %d\nPC : 0x%08x\n", CYCLE_COUNT, PC);
    for (int i = 0; i < 32; i++) {
        printf("x%-2d: 0x%08x %s", i, REGS[i],
               (i % 4 == 3) ? "\n" : "  ");
        fprintf(dumpsim_file, "x%-2d: 0x%08x %s", i, REGS[i],
                (i % 4 == 3) ? "\n" : "  ");
    }
    fflush(dumpsim_file);
}

void idump(FILE *dumpsim_file) {
    printf("\n--- Internal State ---\n");
    printf("Cycle: %d  PC: 0x%08x\n", CYCLE_COUNT, PC);
    printf("Stalls: dep_stall=%d ex_stall=%d mem_stall=%d id_br_stall=%d ex_br_stall=%d icache_r=%d dcache_r=%d\n", dep_stall, ex_stall, mem_stall, id_br_stall, ex_br_stall, icache_r, dcache_r);
    printf("IF: V=%d PC=0x%08x IR=0x%08x\n", PS.IF_V, PS.IF_PC, PS.IF_IR);
    printf("ID: V=%d PC=0x%08x IR=0x%08x RS1=0x%08x RS2=0x%08x IMM=0x%08x RD=%d\n",
           PS.ID_V, PS.ID_PC, PS.ID_IR, PS.ID_RS1, PS.ID_RS2, PS.ID_IMM, PS.ID_RD);
    printf("EX: V=%d PC=0x%08x IR=0x%08x ALU=0x%08x TA=0x%08x RD=%d\n",
           PS.EX_V, PS.EX_PC, PS.EX_IR, PS.EX_ALU_RESULT, PS.EX_TA, PS.EX_RD);
    printf("MEM: V=%d PC=0x%08x IR=0x%08x ALU=0x%08x DATA=0x%08x RD=%d\n",
           PS.MEM_V, PS.MEM_PC, PS.MEM_IR, PS.MEM_ALU_RESULT, PS.MEM_DATA, PS.MEM_RD);

    /* also print to dumpsim file */
    fprintf(dumpsim_file, "\n--- Internal State at cycle %d ---\n", CYCLE_COUNT);
    fprintf(dumpsim_file, "PC: 0x%08x\n", PC);
    fprintf(dumpsim_file, "Stalls: dep_stall=%d ex_stall=%d mem_stall=%d id_br_stall=%d ex_br_stall=%d icache_r=%d dcache_r=%d\n", dep_stall, ex_stall, mem_stall, id_br_stall, ex_br_stall, icache_r, dcache_r);
    fprintf(dumpsim_file, "IF: V=%d PC=0x%08x IR=0x%08x\n", PS.IF_V, PS.IF_PC, PS.IF_IR);
    fprintf(dumpsim_file, "ID: V=%d PC=0x%08x IR=0x%08x RS1=0x%08x RS2=0x%08x IMM=0x%08x RD=%d\n",
           PS.ID_V, PS.ID_PC, PS.ID_IR, PS.ID_RS1, PS.ID_RS2, PS.ID_IMM, PS.ID_RD);
    fprintf(dumpsim_file, "EX: V=%d PC=0x%08x IR=0x%08x ALU=0x%08x TA=0x%08x RD=%d\n",
           PS.EX_V, PS.EX_PC, PS.EX_IR, PS.EX_ALU_RESULT, PS.EX_TA, PS.EX_RD);
    fprintf(dumpsim_file, "MEM: V=%d PC=0x%08x IR=0x%08x ALU=0x%08x DATA=0x%08x RD=%d\n",
           PS.MEM_V, PS.MEM_PC, PS.MEM_IR, PS.MEM_ALU_RESULT, PS.MEM_DATA, PS.MEM_RD);
    fflush(dumpsim_file);
}

void help(void) {
    printf("------------ RISC-V Simulator Commands ------------\n");
    printf("go           - run program to completion\n");
    printf("run n       - execute n cycles\n");
    printf("mdump a b   - dump memory [a..b]\n");
    printf("rdump       - dump registers and PC\n");
    printf("?            - display help\n");
    printf("quit        - exit simulator\n\n");
}

/***************************************************************/
/*  Core cycle and run/go functions                             */
/***************************************************************/
void cycle(void) {
    NEW_PS = PS;
    WB_stage();
    MEM_stage();
    EX_stage();
    ID_stage();
    IF_stage();
    PS = NEW_PS;
    CYCLE_COUNT++;
}

// run n cycles 
void run_cycles(int n) {
    if (!RUN_BIT) {
        printf("Can't simulate; simulator halted\n");
        return;
    }
    printf("Simulating for %d cycles...\n", n);
    for (int i = 0; i < n; ++i) {
        cycle();
    }
}

// run until PC==0 and halt 
void go() {
    if (!RUN_BIT) { printf("Can't simulate; simulator halted\n"); return; }
    printf("Simulating until HALTed...\n");
    while (RUN_BIT) {
        cycle();

        if (PC == 0) { RUN_BIT = FALSE; break; }
    }
    printf("Simulator halted\n");
}


/*  Command interface (get_command)                              */
/***************************************************************/
void get_command(FILE *dumpsim_file) {
    char buffer[20]; int start, stop, cycles;
    printf("RISC-V-SIM> ");
    scanf("%s", buffer);
    switch (buffer[0]) {
    case 'G': case 'g': go(); break;
    case 'M': case 'm': scanf("%i %i", &start, &stop); mdump(dumpsim_file,start,stop); break;
    case '?': help(); break;
    case 'Q': case 'q': printf("Bye.\n"); exit(0);
    case 'R': case 'r':
        if (buffer[1]=='d'||buffer[1]=='D') rdump(dumpsim_file);
        else { scanf("%d",&cycles); run(cycles); }
        break;
    default: printf("Invalid command\n"); break;
    }
}


/*  Initialization and Main     
/***************************************************************/
void initialize(char *control_store_file, char *program_file) {
    init_memory();
    init_control_store(control_store_file);
    load_program(program_file);
    memset(&PS,0,sizeof(PS));
    memset(&NEW_PS,0,sizeof(NEW_PS));
    RUN_BIT = TRUE;
    printf("Initialization complete.\n");
}


// converts number to unsigned binary string
void toBinaryStringUnsigned(int number, int bits, char* binary) {
   binary[bits] = '\0';
   double doublenumber = (double) number;
   if(doublenumber == 0) {
      for(int i = 0; i < bits; i++) {
         binary[i] = '0';
      }
      return;
   }
   else {
      for(int i = bits - 1; i >= 0; i--) {
         if(doublenumber >= pow(2, i)) {
            binary[(bits-1)-i] = '1';
            doublenumber = doublenumber - pow(2, i);
         }
         else {
            binary[(bits-1)-i] = '0';
         }
      }
      return;
   }
}
// converts integer to signed binary string
void toBinaryStringSigned(int number, int bits, char* binary) {
   binary[bits] = '\0';
   double doublenumber = (double) number;
   if(doublenumber == 0) {
      for(int i = 0; i < bits; i++) {
         binary[i] = '0';
      }
      return;
   }
   if(doublenumber > 0) {
      binary[0] = '0';
      for(int i = bits - 2; i >= 0; i--) {
         if(doublenumber >= pow(2, i)) {
            binary[(bits-1)-i] = '1';
            doublenumber = doublenumber - pow(2, i);
         }
         else {
            binary[(bits-1)-i] = '0';
         }
      }
      return;
   }
   else if(doublenumber < 0) {
      binary[0] = '1';
      double doublestartingnumber = -1.0 * pow(2, bits-1);
      for(int i = bits - 2; i >= 0; i--) {
         if((doublestartingnumber - doublenumber) <= (-1.0 * pow(2, i))) {
            binary[(bits-1)-i] = '1';
            doublestartingnumber = doublestartingnumber + pow(2, i);
         }
         else {
            binary[(bits-1)-i] = '0';
         }
      }
      return;
   }
}
// converts signed binary string to integer
int toIntegerFromSignedString(char* binary, int bits) {
   int returninteger = 0;
   if(binary[0] == '0') {
      for(int i = 1; i < bits; i++) {
         if(binary[i] == '1') {
            returninteger = returninteger + pow(2, bits - 1 - i);
         }
      }
   }
   else if(binary[0] == '1') {
      returninteger = returninteger + (-1 * pow(2, bits - 1));
      for(int i = 1; i < bits; i++) {
         if(binary[i] == '1') {
            returninteger = returninteger + pow(2, bits - 1 - i);
         }
      }
   }
   return returninteger;
}
// converts unsigned binary string to integer
int toIntegerFromUnsignedString(char* binary, int bits) {
   int returninteger = 0;
   for(int i = 0; i < bits; i++) {
      if(binary[i] == '1') {
         returninteger = returninteger + pow(2, bits - 1 - i);
      }
   }
   return returninteger;
}

// not sure if this is right
int sext(int num, int signbit){
    if ((num >> (signbit)) & 0x01){
       int mask = (- 1) - ((2 << signbit) - 1);
       return(num | mask);
    } else if (!((num >> (signbit)) & 0x01)){
       int mask = (2 << signbit) - 1;
       return(num & mask);
    }
 }

/* ========== Stage implementations ========== */

/* Signals generated by WB stage and needed by previous stages */
int v_wb_ld_reg,
    wb_dr,
    wb_data;

/***************************************************************/
/* Pipeline Stage: WB                                           */
/***************************************************************/
void WB_stage(void) {
    v_wb_ld_reg = PS.MEM_CS[CS_LDREG] & PS.MEM_V;
    wb_dr = PS.MEM_RD;

    int wb_mux = (PS.MEM_CS[CS_WB_MUX1] << 1) + PS.MEM_CS[CS_WB_MUX0];
    switch (wb_mux) {
        case 0: // PC + 4
            wb_data = PS.MEM_PC + 4;
            break;
        case 1: // Memory result
            wb_data = PS.MEM_DATA;
            break;
        case 2: // ALU result
            wb_data = PS.MEM_ALU_RESULT;
            break;
        default:
            wb_data = 0;
            break;
    }
}

/* Signals generated by MEM stage and needed by previous stages */
int v_mem_ld_reg,
    mem_dr;

/***************************************************************/
/* Pipeline Stage: MEM                                          */
/***************************************************************/
void MEM_stage(void) {

    v_mem_ld_reg = PS.EX_CS[CS_LDREG] & PS.EX_V;
    mem_dr = PS.EX_RD;
    
    uint32_t IR = PS.EX_IR;
    int dcache_r = 0; uint32_t mem_data = 0;
    int ldst_op = (PS.EX_CS[CS_LDST_OP2] << 2) + (PS.MEM_CS[CS_LDST_OP1] << 1) + PS.MEM_CS[CS_LDST_OP0];

    if ((PS.EX_V == 1) && (PS.EX_CS[CS_LDST] == 1)) {dcache_access(PS.EX_TA, &mem_data, PS.EX_ALU_RESULT, &dcache_r, ldst_op);}
    if ((PS.EX_V == 1) && (PS.EX_CS[CS_LDST] == 1) && (dcache_r == 0)) {mem_stall = 1;}
    if ((PS.EX_V == 0) || (PS.EX_CS[CS_LDST] == 0) || (dcache_r == 1)) {mem_stall = 0;}

    char data[64] = "0000000000000000000000000000000000000000000000000000000000000000";
    if(ldst_op == 0) {
        mem_data = mem_data & 0x000000FF;
        toBinaryStringSigned(mem_data, 32, data); 
        mem_data = toIntegerFromUnsignedString(data, 32);
    }
    else if(ldst_op == 1) {
        mem_data = mem_data & 0x0000FFFF;
        toBinaryStringSigned(mem_data, 32, data); 
        mem_data = toIntegerFromUnsignedString(data, 32);
    }
    else if(ldst_op == 3) {
        mem_data = mem_data & 0x000000FF;
    }
    else if(ldst_op == 4) {
        mem_data = mem_data & 0x0000FFFF;
    }

    NEW_PS.MEM_ALU_RESULT = PS.EX_ALU_RESULT;
    NEW_PS.MEM_IR = IR;
    NEW_PS.MEM_DATA = mem_data;
    NEW_PS.MEM_PC = PS.EX_PC;
    NEW_PS.MEM_RD = PS.EX_RD;
    memcpy(NEW_PS.MEM_CS, PS.EX_CS, sizeof(int) * NUM_CONTROL_SIGNALS);
    if((PS.EX_V == 1) && (mem_stall == 0)) NEW_PS.MEM_V = 1;
    else NEW_PS.MEM_V = 0;
}

/* Signals generated by EX stage and needed by previous stages */
int v_ex_ld_reg,
    ex_dr,
    jmp_pc,
    jmp_pcmux;

/***************************************************************/
/* Pipeline Stage: EX                                           */
/***************************************************************/
void EX_stage(void) {
    
    v_ex_ld_reg = PS.ID_CS[CS_LDREG] & PS.ID_V;
    ex_dr = PS.ID_RD;
    ex_br_stall = PS.ID_CS[CS_BR_STALL] & PS.ID_V;

    uint32_t IR = PS.ID_IR;
    uint32_t result = 0, ta = 0, comp_result = 0;
    int alu_op = (PS.ID_CS[CS_ALU_OP4] << 4) | (PS.ID_CS[CS_ALU_OP3] << 3) |
                 (PS.ID_CS[CS_ALU_OP2] << 2) | (PS.ID_CS[CS_ALU_OP1] << 1) |
                 PS.ID_CS[CS_ALU_OP0];
    int comp_op = (PS.ID_CS[CS_COMP_OP2] << 2) | (PS.ID_CS[CS_COMP_OP1] << 1) |
                 PS.ID_CS[CS_COMP_OP0];
    uint32_t srcA = PS.ID_RS1;
    uint32_t srcB = PS.ID_CS[CS_ALU_MUX] ? PS.ID_IMM : PS.ID_RS2;

    switch (alu_op) {
        // most of the current cases are not right
        // someone needs to do all of the cases based on ALU instructions
        // should end up with cases 0 through 31
        // note that some of the operations are signed, some of the operations are unsigned
        // the register values are unsigned 32 bit integers, so you're going to have to manipulate values accordingly
        case 0: result = srcA + srcB; break;
        case 1: result = srcA - srcB; break;
        case 2: result = srcA & srcB; break;
        case 3: result = srcA | srcB; break;
        case 4: result = srcA ^ srcB; break;
        case 5: result = srcA << (srcB & 0x1F); break;
        case 6: result = srcA >> (srcB & 0x1F); break;
        case 7: result = ((int32_t)srcA < (int32_t)srcB); break;
        default: result = 0; break;
    }
    ex_stall = 0;

    ta = PS.ID_CS[CS_TA_MUX] ? PS.ID_PC : PS.ID_RS1;
    ta = ta + PS.ID_IMM;
    jmp_pc = ta;

    switch (comp_op) {
        case 0: comp_result = 0; break;
        // cases 0 and 7 are good
        // someone needs to do cases 1 through 6 based on branch instructions
        // comp should equal one if branch is being taken, zero is branch is not being taken
        // note that some of the branch comparisons are signed, some of the branch comparisons are unsigned
        // the register values are unsigned 32 bit integers, so you're going to have to manipulate values accordingly
        case 7: comp_result = 1; break;
        default: comp_result = 0; break;
    }
    jmp_pcmux = comp_result & PS.ID_V;

    int LD_MEM = 0;
    if(mem_stall == 0) {LD_MEM = 1;}

    if(LD_MEM) {
        NEW_PS.EX_ALU_RESULT = PS.ID_CS[CS_ALU_RESULT_MUX] ? result : ta;
        NEW_PS.EX_TA = ta;
        NEW_PS.EX_PC = PS.ID_PC;
        NEW_PS.EX_IR = IR;
        NEW_PS.EX_RD = PS.ID_RD;
        memcpy(NEW_PS.EX_CS, PS.ID_CS, sizeof(int) * NUM_CONTROL_SIGNALS);
        NEW_PS.EX_V = PS.ID_V;
    }

}

/***************************************************************/
/* Pipeline Stage: ID                                           */
/***************************************************************/
void ID_stage(void) {

    uint32_t IR = PS.IF_IR;
    int opcode = IR & 0x7F;
    int row = opcode;  /* assume 1:1 mapping per instruction for now */
    // someone needs to go through and map individual opcodes to corresponding row numbers
    id_br_stall = CONTROL_STORE[row][CS_BR_STALL] & PS.IF_V;

    int rs1 = (IR >> 15) & 0x1F;
    int rs2 = (IR >> 20) & 0x1F;
    int rd  = (IR >> 7) & 0x1F;

    uint32_t imm = 0;
    int iv = (CONTROL_STORE[row][CS_IV2] << 2) |
             (CONTROL_STORE[row][CS_IV1] << 1) |
             CONTROL_STORE[row][CS_IV0];

    switch (iv) { // someone needs to go through these, some of them aren't right
        case 1: imm = sext((IR >> 20), 12); break;                  // I-type 
        case 2: imm = sext(((IR >> 25) << 5) | ((IR >> 7) & 0x1F), 12); break; // S-type 
        case 3: imm = sext(((IR >> 31) << 12) | (((IR >> 7) & 1) << 11)
                        | (((IR >> 25) & 0x3F) << 5) | (((IR >> 8) & 0xF) << 1), 13); break; // B-type 
        case 4: imm = (IR & 0xFFFFF000); break;                     // U-type 
        case 5: imm = sext(((IR >> 12) & 0xFF) << 12, 21); break;   // J-type simplified 
    }

    if (v_wb_ld_reg) REGS[wb_dr] = wb_data;

    if(PS.IF_V == 0) {dep_stall = 0;}
    if(PS.IF_V == 1) {
        dep_stall = 0;
        if((CONTROL_STORE[row][CS_SR1_NEEDED] == 1) && (v_wb_ld_reg == 1) && (rs1 == wb_dr)) {dep_stall = 1;}
        if((CONTROL_STORE[row][CS_SR1_NEEDED] == 1) && (v_mem_ld_reg == 1) && (rs1 == mem_dr)) {dep_stall = 1;}
        if((CONTROL_STORE[row][CS_SR1_NEEDED] == 1) && (v_ex_ld_reg == 1) && (rs1 == ex_dr)) {dep_stall = 1;}
        if((CONTROL_STORE[row][CS_SR2_NEEDED] == 1) && (v_wb_ld_reg == 1) && (rs2 == wb_dr)) {dep_stall = 1;}
        if((CONTROL_STORE[row][CS_SR2_NEEDED] == 1) && (v_mem_ld_reg == 1) && (rs2 == mem_dr)) {dep_stall = 1;}
        if((CONTROL_STORE[row][CS_SR2_NEEDED] == 1) && (v_ex_ld_reg == 1) && (rs2 == ex_dr)) {dep_stall = 1;}
    }

    int LD_EX = 1;
    if(ex_stall == 1) {LD_EX = 0;}
    if(mem_stall == 1) {LD_EX = 0;}

    if(LD_EX) {
        NEW_PS.ID_PC = PS.IF_PC;
        NEW_PS.ID_IR = IR;
        NEW_PS.ID_RS1 = REGS[rs1];
        NEW_PS.ID_RS2 = REGS[rs2];
        NEW_PS.ID_IMM = imm;
        NEW_PS.ID_RD = rd;
        memcpy(NEW_PS.ID_CS, CONTROL_STORE[row], sizeof(int) * NUM_CONTROL_SIGNALS);
        NEW_PS.ID_V = 0;
        if((PS.IF_V == 1) && (dep_stall == 0)) {NEW_PS.ID_V = 1;}
    }

}

/***************************************************************/
/* Pipeline Stage: IF                                          */
/***************************************************************/
void IF_stage(void) {
    
    int icache_r; uint32_t instr;
    icache_access(PC, &instr, &icache_r);
    // assuming that instruction cache will never stall

    int LD_ID = 1;
    if(dep_stall == 1) {LD_ID = 0;}
    if(ex_stall == 1) {LD_ID = 0;}
    if(mem_stall == 1) {LD_ID = 0;}

    if(LD_ID) {
        NEW_PS.IF_PC = PC;
        NEW_PS.IF_IR = instr;
        NEW_PS.IF_V = 0;
        if((id_br_stall == 0) && (ex_br_stall == 0)) {NEW_PS.IF_V = 1;}
    }

    int ld_pc = 0;
    if((id_br_stall == 0) && (ex_br_stall == 0) && (jmp_pcmux == 0) && (LD_ID == 1)) {ld_pc = 1;}
    if(jmp_pcmux == 1) {ld_pc = 1;}

    if(ld_pc == 1) {
        if(jmp_pcmux == 0) {PC = PC + 4;}
        else if(jmp_pcmux == 1) {PC = jmp_pc;}
    }
    
}

/* ========== initialization, load program, main ========== */

void init_state() {
    memset(&PS,0,sizeof(PipeState));
    memset(&NEW_PS,0,sizeof(PipeState));
    for (int i=0;i<32;i++) REGS[i]=0;
    PC = 0;
    RUN_BIT = TRUE;
    CYCLE_COUNT = 0;
    dep_stall = 0; ex_stall = 0; mem_stall = 0; id_br_stall = 0; ex_br_stall = 0; icache_r = 1; dcache_r = 1;
}

void init_memory() {
    memset(MEMORY,0,sizeof(MEMORY));
}

void load_program(const char *fname) {
    FILE *f = fopen(fname,"r");
    if (!f) { printf("Can't open program file %s\n", fname); exit(1); }
    uint32_t word;
    if (fscanf(f,"%x\n",&word) == EOF) { fclose(f); return; }
    PC = word;
    uint32_t addr = PC;
    while (fscanf(f,"%x\n",&word) != EOF) {
        if (addr >= WORDS_IN_MEM) break;
        MEMORY[addr][0]   = word & 0xFF;
        MEMORY[addr][1] = (word>>8) & 0xFF;
        MEMORY[addr][2] = (word>>16) & 0xFF;
        MEMORY[addr][3] = (word>>24) & 0xFF;
        addr += 1;
    }
    fclose(f);
    printf("Loaded program into memory starting at 0x%08x\n", PC);
}

/* get_command function (interactive) */
void get_command(FILE * dumpsim_file) {
    char buffer[32];
    printf("RV32-SIM>");
    if (scanf("%s", buffer) == EOF) exit(0);

    if (buffer[0]=='q' || buffer[0]=='Q') { printf("Bye.\n"); exit(0); }
    else if (buffer[0]=='?') { help(); }
    else if (buffer[0]=='g' || buffer[0]=='G') { go(); }
    else if (buffer[0]=='r' || buffer[0]=='R') {
        if (buffer[1] == 'd' || buffer[1]=='D') rdump(dumpsim_file);
        else {
            int n=1;
            if (scanf("%d", &n) == 1) run_cycles(n);
        }
    } else if (buffer[0]=='m' || buffer[0]=='M') {
        uint32_t s,e; if (scanf("%x %x",&s,&e)==2) mdump(dumpsim_file,s,e);
    } else if (buffer[0]=='i' || buffer[0]=='I') {
        idump(dumpsim_file);
    } else { printf("Unknown command\n"); }
}

/* main */
int main(int argc, char **argv) {
    if (argc < 2) {
        printf("Usage: %s program.hex\n", argv[0]);
        return 1;
    }
    printf("RV32I pipelined simulator\n");
    init_control_store(argv[1]);
    init_memory();
    load_program(argv[2]);
    init_state();

    FILE *dumpsim_file = fopen("dumpsim","w");
    if (!dumpsim_file) { printf("Can't open dumpsim file\n"); return 1; }

    while (1) get_command(dumpsim_file);
    return 0;
}
