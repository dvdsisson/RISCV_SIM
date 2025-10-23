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
#define NUM_CONTROL_SIGNALS      25
#define WORDS_IN_MEM             0x100000  //1 MB

/***************************************************************/
/*  Architectural state                                         */
/***************************************************************/
uint32_t PC = 0x0;
uint32_t REGS[32];
int      RUN_BIT = TRUE;
int      CYCLE_COUNT = 0;

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
    uint32_t EX_PC, EX_ALU_RESULT, EX_RS2, EX_TA;
    int      EX_RD, EX_V;
    int      EX_CS[NUM_CONTROL_SIGNALS];

    // MEM/WB 
    uint32_t MEM_ALU_RESULT, MEM_DATA;
    int      MEM_RD, MEM_V;
    int      MEM_CS[NUM_CONTROL_SIGNALS];
} PipeState;

PipeState PS, NEW_PS;


enum {
    CS_SR1_NEEDED = 0,
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
    int miss = CYCLE_COUNT % 13 == 0;
    if (miss) { *icache_r = 0; *instr = 0x00000013; return; } // NOP 
    *icache_r = 1;
    int idx = addr >> 2;
    *instr = (MEMORY[idx][3] << 24) | (MEMORY[idx][2] << 16) | (MEMORY[idx][1] << 8) | MEMORY[idx][0];
}

void dcache_access(uint32_t addr, uint32_t *read_word, uint32_t write_word,
                   int *dcache_r, int mem_write) {
    int miss = CYCLE_COUNT % 11 == 0;
    if (miss) { *dcache_r = 0; return; }
    *dcache_r = 1;
    int idx = addr >> 2;
    if (mem_write) {
        MEMORY[idx][0] = write_word & 0xFF;
        MEMORY[idx][1] = (write_word >> 8) & 0xFF;
        MEMORY[idx][2] = (write_word >> 16) & 0xFF;
        MEMORY[idx][3] = (write_word >> 24) & 0xFF;
    } else {
        *read_word = (MEMORY[idx][3] << 24) | (MEMORY[idx][2] << 16) | (MEMORY[idx][1] << 8) | MEMORY[idx][0];
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
    printf("Stalls: dep_stall=%d mem_stall=%d icache_r=%d\n", dep_stall, mem_stall, icache_r);
    printf("IF: V=%d PC=0x%08x IR=0x%08x\n", PS.IF_V, PS.IF_PC, PS.IF_IR);
    printf("ID: V=%d PC=0x%08x IR=0x%08x RS1=0x%08x RS2=0x%08x IMM=0x%08x RD=%d\n",
           PS.ID_V, PS.ID_PC, PS.ID_IR, PS.ID_RS1, PS.ID_RS2, PS.ID_IMM, PS.ID_RD);
    printf("EX: V=%d PC=0x%08x ALU=0x%08x RS2=0x%08x RD=%d\n",
           PS.EX_V, PS.EX_PC, PS.EX_ALU_RESULT, PS.EX_RS2, PS.EX_RD);
    printf("MEM: V=%d ALU=0x%08x DATA=0x%08x RD=%d\n",
           PS.MEM_V, PS.MEM_ALU_RESULT, PS.MEM_DATA, PS.MEM_RD);

    /* also print to dumpsim file */
    fprintf(dumpsim_file, "\n--- Internal State at cycle %d ---\n", CYCLE_COUNT);
    fprintf(dumpsim_file, "PC: 0x%08x\n", PC);
    fprintf(dumpsim_file, "Stalls: dep_stall=%d mem_stall=%d icache_r=%d\n", dep_stall, mem_stall, icache_r);
    fprintf(dumpsim_file, "IF: V=%d PC=0x%08x IR=0x%08x\n", PS.IF_V, PS.IF_PC, PS.IF_IR);
    fprintf(dumpsim_file, "ID: V=%d PC=0x%08x IR=0x%08x RS1=0x%08x RS2=0x%08x IMM=0x%08x RD=%d\n",
           PS.ID_V, PS.ID_PC, PS.ID_IR, PS.ID_RS1, PS.ID_RS2, PS.ID_IMM, PS.ID_RD);
    fprintf(dumpsim_file, "EX: V=%d PC=0x%08x ALU=0x%08x RS2=0x%08x RD=%d\n",
           PS.EX_V, PS.EX_PC, PS.EX_ALU_RESULT, PS.EX_RS2, PS.EX_RD);
    fprintf(dumpsim_file, "MEM: V=%d ALU=0x%08x DATA=0x%08x RD=%d\n",
           PS.MEM_V, PS.MEM_ALU_RESULT, PS.MEM_DATA, PS.MEM_RD);
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

/void IF_stage(void) {
    int icache_r; uint32_t instr;
    icache_access(PC, &instr, &icache_r);
    if (icache_r) {
        NEW_PS.IF_PC = PC;
        NEW_PS.IF_IR = instr;
        NEW_PS.IF_V = 1;
        PC += 4;
    }
}

/***************************************************************/
/* Pipeline Stage: ID                                           */
/***************************************************************/
void ID_stage(void) {
    if (!PS.IF_V) return;
    uint32_t IR = PS.IF_IR;
    int opcode = IR & 0x7F;
    int row = opcode;  /* assume 1:1 mapping per instruction for now */

    memcpy(NEW_PS.ID_CS, CONTROL_STORE[row], sizeof(int) * NUM_CS_SIGNALS);

    int rs1 = (IR >> 15) & 0x1F;
    int rs2 = (IR >> 20) & 0x1F;
    int rd  = (IR >> 7) & 0x1F;

    uint32_t imm = 0;
    int iv = (CONTROL_STORE[row][CS_IV2] << 2) |
             (CONTROL_STORE[row][CS_IV1] << 1) |
             CONTROL_STORE[row][CS_IV0];

    switch (iv) {
        case 0: imm = sext((IR >> 20), 12); break;                  // I-type 
        case 1: imm = sext(((IR >> 25) << 5) | ((IR >> 7) & 0x1F), 12); break; // S-type 
        case 2: imm = sext(((IR >> 31) << 12) | (((IR >> 7) & 1) << 11)
                        | (((IR >> 25) & 0x3F) << 5) | (((IR >> 8) & 0xF) << 1), 13); break; // B-type 
        case 3: imm = (IR & 0xFFFFF000); break;                     // U-type 
        case 4: imm = sext(((IR >> 12) & 0xFF) << 12, 21); break;   // J-type (simplified) 
    }

    NEW_PS.ID_PC = PS.IF_PC;
    NEW_PS.ID_IR = IR;
    NEW_PS.ID_RS1 = REGS[rs1];
    NEW_PS.ID_RS2 = REGS[rs2];
    NEW_PS.ID_IMM = imm;
    NEW_PS.ID_RD = rd;
    NEW_PS.ID_V = 1;
}

/***************************************************************/
/* Pipeline Stage: EX                                           */
/***************************************************************/
void EX_stage(void) {
    if (!PS.ID_V) return;
    uint32_t result = 0, ta = 0;
    int alu_op = (PS.ID_CS[CS_ALU_OP4] << 4) | (PS.ID_CS[CS_ALU_OP3] << 3) |
                 (PS.ID_CS[CS_ALU_OP2] << 2) | (PS.ID_CS[CS_ALU_OP1] << 1) |
                 PS.ID_CS[CS_ALU_OP0];
    uint32_t srcA = PS.ID_RS1;
    uint32_t srcB = PS.ID_CS[CS_ALU_MUX] ? PS.ID_IMM : PS.ID_RS2;

    switch (alu_op) {
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

    ta = PS.ID_PC + PS.ID_IMM;

    NEW_PS.EX_ALU_RESULT = PS.ID_CS[CS_ALU_RESULT_MUX] ? result : ta;
    NEW_PS.EX_RS2 = PS.ID_RS2;
    NEW_PS.EX_PC = PS.ID_PC;
    NEW_PS.EX_RD = PS.ID_RD;
    memcpy(NEW_PS.EX_CS, PS.ID_CS, sizeof(int) * NUM_CS_SIGNALS);
    NEW_PS.EX_V = 1;
}

/***************************************************************/
/* Pipeline Stage: MEM                                          */
/***************************************************************/
void MEM_stage(void) {
    if (!PS.EX_V) return;
    int dcache_r; uint32_t mem_data = 0;

    if (PS.EX_CS[CS_LDST]) {
        int write = PS.EX_CS[CS_LDST_OP0]; 
        dcache_access(PS.EX_ALU_RESULT, &mem_data, PS.EX_RS2, &dcache_r, write);
        if (!dcache_r) return;
    }

    NEW_PS.MEM_ALU_RESULT = PS.EX_ALU_RESULT;
    NEW_PS.MEM_DATA = mem_data;
    NEW_PS.MEM_RD = PS.EX_RD;
    memcpy(NEW_PS.MEM_CS, PS.EX_CS, sizeof(int) * NUM_CS_SIGNALS);
    NEW_PS.MEM_V = 1;
}

/***************************************************************/
/* Pipeline Stage: WB                                           */
/***************************************************************/
void WB_stage(void) {
    if (!PS.MEM_V) return;
    int rd = PS.MEM_RD;
    uint32_t wb_data = 0;

    int wb_mux = (PS.MEM_CS[CS_WB_MUX1] << 1) | PS.MEM_CS[CS_WB_MUX0];
    switch (wb_mux) {
        case 0: wb_data = PS.MEM_ALU_RESULT; break;
        case 1: wb_data = PS.MEM_DATA; break;
        case 2: wb_data = PS.MEM_ALU_RESULT + 4; break; 
    }

    if (PS.MEM_CS[CS_LDREG] && rd != 0)
        REGS[rd] = wb_data;
}

/* ========== initialization, load program, main ========== */

void init_state() {
    memset(&PS,0,sizeof(PipeState));
    memset(&NEW_PS,0,sizeof(PipeState));
    for (int i=0;i<32;i++) REGS[i]=0;
    PC = 0;
    RUN_BIT = TRUE;
    CYCLE_COUNT = 0;
    dep_stall = 0; mem_stall = 0; icache_r = 1;
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
        if (addr + 3 >= MEM_BYTES) break;
        MEMORY[addr]   = word & 0xFF;
        MEMORY[addr+1] = (word>>8) & 0xFF;
        MEMORY[addr+2] = (word>>16) & 0xFF;
        MEMORY[addr+3] = (word>>24) & 0xFF;
        addr += 4;
    }
    fclose(f);
    printf("Loaded program into memory starting at 0x%08x\n", PC);
}

/* get_command function (interactive) */
void get_command(FILE * dumpsim_file) {
    char buffer[32];
    printf("RV32-SIM> ");
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
    init_control_store();
    init_memory();
    load_program(argv[1]);
    init_state();

    FILE *dumpsim_file = fopen("dumpsim","w");
    if (!dumpsim_file) { printf("Can't open dumpsim file\n"); return 1; }

    while (1) get_command(dumpsim_file);
    return 0;
}
