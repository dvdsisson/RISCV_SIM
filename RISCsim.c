#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <math.h>

/***************************************************************/
/*  Global definitions                                          */
/***************************************************************/
#define TRUE  1
#define FALSE 0
#define Low32bits(x) ((x)&0xFFFFFFFF)

#define NUM_CONTROL_STORE_ROWS          72
#define NUM_CONTROL_STORE_ROWS_ALU      32
#define NUM_CONTROL_STORE_ROWS_MULT     8
#define NUM_CONTROL_STORE_ROWS_LDST     16
#define NUM_CONTROL_STORE_ROWS_BR       8
#define NUM_CONTROL_STORE_ROWS_ADDCONST 2
#define NUM_CONTROL_STORE_ROWS_JMP      2
#define NUM_CONTROL_STORE_ROWS_AUG      4
// POTATO
#define NUM_CONTROL_SIGNALS      32
#define WORDS_IN_MEM             0x20000  //128 KB

// Branch Predection Paramaters
#define GHR_LENGTH               8
#define BRANCH_PRED_TAG_LEN      17 // 17 from log2(0x20000) = 17
#define BRANCH_PRED_SEQ_LEN      2


/***************************************************************/
/*  Architectural state                                         */
/***************************************************************/
uint32_t PC = 0x0;
uint32_t REGS[32];
int      RUN_BIT = TRUE;
int      CYCLE_COUNT = 0;

// Branch Predicition Cache
int BP_Tag_Store [1 << GHR_LENGTH];
int BP_Seq_Store [1 << GHR_LENGTH];
int BP_SeqLen_Store [1 << GHR_LENGTH];
int BP_Target_Store [1 << GHR_LENGTH];
int GHR;

int dep_stall;
int ex_stall;
int mem_stall;
int id_br_stall;
int ex_br_stall;
int aug_stage0_stall;
int aug_stage1_stall;
int icache_r;
int dcache_r;
int jmp_pcmux;

/***************************************************************/
/*  Main memory and control store                              */
/***************************************************************/
int CONTROL_STORE[NUM_CONTROL_STORE_ROWS][NUM_CONTROL_SIGNALS];
int CONTROL_STORE_ALU[NUM_CONTROL_STORE_ROWS_ALU][NUM_CONTROL_SIGNALS];
int CONTROL_STORE_MULT[NUM_CONTROL_STORE_ROWS_MULT][NUM_CONTROL_SIGNALS];
int CONTROL_STORE_LDST[NUM_CONTROL_STORE_ROWS_LDST][NUM_CONTROL_SIGNALS];
int CONTROL_STORE_BR[NUM_CONTROL_STORE_ROWS_BR][NUM_CONTROL_SIGNALS];
int CONTROL_STORE_ADDCONST[NUM_CONTROL_STORE_ROWS_ADDCONST][NUM_CONTROL_SIGNALS];
int CONTROL_STORE_JMP[NUM_CONTROL_STORE_ROWS_JMP][NUM_CONTROL_SIGNALS];
int CONTROL_STORE_AUG[NUM_CONTROL_STORE_ROWS_AUG][NUM_CONTROL_SIGNALS];
uint8_t MEMORY[WORDS_IN_MEM][4];   /* byte-addressable */

/***************************************************************/
/*  Pipeline register structure                                 */
/***************************************************************/
typedef struct {
    // IF/ID 
    uint32_t IF_PC, IF_IR;
    int      IF_V;
    uint8_t  IF_TAKEN;

    // ID/EX 
    uint32_t ID_PC, ID_IR, ID_RS1, ID_RS2, ID_RS3, ID_IMM;
    int      ID_RD, ID_V;
    uint8_t  ID_TAKEN;
    int      ID_CS[NUM_CONTROL_SIGNALS];

    // EX/MEM 
    uint32_t EX_PC, EX_IR, EX_ALU_RESULT, EX_TA;
    int      EX_RD, EX_V;
    int      EX_CS[NUM_CONTROL_SIGNALS];

    // Stage 0 Augmentation
    uint32_t S0_PC, SO_IR;
    uint32_t S0_IMG_PTR;
    uint32_t S0_OUTPUT_PTR;
    uint32_t S0_KERNEL_PTR;
    uint32_t S0_BIAS_PTR;
    uint32_t S0_WEIGHT_PTR;
    uint32_t S0_START;

    // Stage 1 Augmentation
    uint32_t S1_PIXEL_PTR;
    uint32_t S1_OUTPUT_PTR;
    uint32_t S1_OUTPUT_PTR_A;
    uint32_t S1_OUTPUT_PTR_B;
    uint32_t S1_OUTPUT_PTR_C;
    uint32_t S1_CYCLE_AMNT;
    uint32_t S1_COLS;
    uint32_t S1_LAT_SHIFTS;
    uint32_t S1_VERT_SHIFTS;
    uint32_t S1_CHN_AMNT;
    uint32_t S1_KERN_SIZE;
    uint32_t S1_KERN_PTR;
    uint32_t S1_BIAS_PTR;
    uint32_t S1_SIZE;
    uint32_t S1_WEIGHT_PTR;
    uint32_t S1_START;

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
    CS_AUG_SR2,
    CS_PIXEL_PROCESS,
    CS_SR3_NEEDED,
    CS_IS_FC,
    CS_NEEDS_SIZE,
    CS_DP_BLOCK,
    CS_BIAS_ADD,
    CS_FC,
    NUM_CS_FIELDS
    // Add more cs bits if necessary
};


/***************************************************************/
/*  Prototypes for pipeline stages           */
/***************************************************************/
void IF_stage(void);
void ID_stage(void);
void EX_stage(void);
void Aug0_stage(void);
void Aug1_stage(void);
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

    char buffer[256];

    int r = 0; 
    while (fgets(buffer, sizeof(buffer), fp)){
        for (int c = 0; c < NUM_CONTROL_SIGNALS; c++){
            if (buffer[c] == '1'){
                CONTROL_STORE[r][c] = 0x01;
            } else {
                CONTROL_STORE[r][c] = 0x00;
            }
        }
        r++;
    }

    fclose(fp);

    int index = 0;
    for(int i = 0; i < NUM_CONTROL_STORE_ROWS_ALU; i++) {
        for(int j = 0; j < NUM_CONTROL_SIGNALS; j++) {
            CONTROL_STORE_ALU[i][j] = CONTROL_STORE[index][j];
            //printf("%d", CONTROL_STORE[index][j]);
        }
        index++;
        //printf("\n");
    }
    for(int i = 0; i < NUM_CONTROL_STORE_ROWS_MULT; i++) {
        for(int j = 0; j < NUM_CONTROL_SIGNALS; j++) {
            CONTROL_STORE_MULT[i][j] = CONTROL_STORE[index][j];
            //printf("%d", CONTROL_STORE[index][j]);
        }
        index++;
        //printf("\n");
    }
    for(int i = 0; i < NUM_CONTROL_STORE_ROWS_LDST; i++) {
        for(int j = 0; j < NUM_CONTROL_SIGNALS; j++) {
            CONTROL_STORE_LDST[i][j] = CONTROL_STORE[index][j];
            //printf("%d", CONTROL_STORE[index][j]);
        }
        index++;
        //printf("\n");
    }
    for(int i = 0; i < NUM_CONTROL_STORE_ROWS_BR; i++) {
        for(int j = 0; j < NUM_CONTROL_SIGNALS; j++) {
            CONTROL_STORE_BR[i][j] = CONTROL_STORE[index][j];
            //printf("%d", CONTROL_STORE[index][j]);
        }
        index++;
        //printf("\n");
    }
    for(int i = 0; i < NUM_CONTROL_STORE_ROWS_ADDCONST; i++) {
        for(int j = 0; j < NUM_CONTROL_SIGNALS; j++) {
            CONTROL_STORE_ADDCONST[i][j] = CONTROL_STORE[index][j];
            //printf("%d", CONTROL_STORE[index][j]);
        }
        index++;
        //printf("\n");
    }
    for(int i = 0; i < NUM_CONTROL_STORE_ROWS_JMP; i++) {
        for(int j = 0; j < NUM_CONTROL_SIGNALS; j++) {
            CONTROL_STORE_JMP[i][j] = CONTROL_STORE[index][j];
            //printf("%d", CONTROL_STORE[index][j]);
        }
        index++;
        //printf("\n");
    }
    for(int i = 0; i < NUM_CONTROL_STORE_ROWS_AUG; i++) {
        for(int j = 0; j < NUM_CONTROL_SIGNALS; j++) {
            CONTROL_STORE_AUG[i][j] = CONTROL_STORE[index][j];
            printf("%d", CONTROL_STORE[index][j]);
        }
        index++;
        printf("\n");
    }
}

/***************************************************************/
/*  Memory helpers and I/O functions                            */
/***************************************************************/

/*void load_program(char *filename) {
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
}*/

/***************************************************************/
/*  Instruction and Data Cache Access                           */
/***************************************************************/
void icache_access(uint32_t addr, uint32_t *instr, int *icache_r) {
    // could create instruction cache stalls here
    /*int miss = CYCLE_COUNT % 13 == 0;
    // if (miss) { *icache_r = 0; return; }*/
    *icache_r = 1;
    int index = addr >> 2;
    *instr = (MEMORY[index][3] << 24) | (MEMORY[index][2] << 16) | (MEMORY[index][1] << 8) | MEMORY[index][0];
}

void dcache_access(uint32_t addr, uint32_t *read_word, uint32_t write_word, int *dcache_r, int ldst_op) {
    // could create memory stalls here
    /*int miss = CYCLE_COUNT % 13 == 0;
    // if (miss) { *dcache_r = 0; return; }*/
    *dcache_r = 1;
    int index = addr >> 2;
    int remainder = addr % 4;
    if(ldst_op <= 4) {
        if(remainder == 0) {*(read_word) = ((uint32_t)(MEMORY[index][3]) << 24) + ((uint32_t)(MEMORY[index][2]) << 16) + ((uint32_t)(MEMORY[index][1]) << 8) + ((uint32_t)(MEMORY[index][0]));}
        else if(remainder == 1) {*(read_word) = ((uint32_t)(MEMORY[index+1][0]) << 24) + ((uint32_t)(MEMORY[index][3]) << 16) + ((uint32_t)(MEMORY[index][2]) << 8) + ((uint32_t)(MEMORY[index][1]));}
        else if(remainder == 2) {*(read_word) = ((uint32_t)(MEMORY[index+1][1]) << 24) + ((uint32_t)(MEMORY[index+1][0]) << 16) + ((uint32_t)(MEMORY[index][3]) << 8) + ((uint32_t)(MEMORY[index][2]));}
        else if(remainder == 3) {*(read_word) = ((uint32_t)(MEMORY[index+1][2]) << 24) + ((uint32_t)(MEMORY[index+1][1]) << 16) + ((uint32_t)(MEMORY[index+1][0]) << 8) + ((uint32_t)(MEMORY[index][3]));}
    }
    else if(ldst_op == 5) {
        MEMORY[index][remainder] = (uint8_t)(write_word & 0x000000FF);
    }
    else if(ldst_op == 6) {
        if(remainder == 0) {MEMORY[index][0] = (uint8_t)(write_word & 0x000000FF); MEMORY[index][1] = (uint8_t)((write_word & 0x0000FF00) >> 8);}
        else if(remainder == 1) {MEMORY[index][1] = (uint8_t)(write_word & 0x000000FF); MEMORY[index][2] = (uint8_t)((write_word & 0x0000FF00) >> 8);}
        else if(remainder == 2) {MEMORY[index][2] = (uint8_t)(write_word & 0x000000FF); MEMORY[index][3] = (uint8_t)((write_word & 0x0000FF00) >> 8);}
        else if(remainder == 3) {MEMORY[index][3] = (uint8_t)(write_word & 0x000000FF); MEMORY[index+1][0] = (uint8_t)((write_word & 0x0000FF00) >> 8);}
    }
    else if(ldst_op == 7) {
        if(remainder == 0) {MEMORY[index][0] = (uint8_t)(write_word & 0x000000FF); MEMORY[index][1] = (uint8_t)((write_word & 0x0000FF00) >> 8); MEMORY[index][2] = (uint8_t)((write_word & 0x00FF0000) >> 16); MEMORY[index][3] = (uint8_t)((write_word & 0xFF000000) >> 24);}
        else if(remainder == 1) {MEMORY[index][1] = (uint8_t)(write_word & 0x000000FF); MEMORY[index][2] = (uint8_t)((write_word & 0x0000FF00) >> 8); MEMORY[index][3] = (uint8_t)((write_word & 0x00FF0000) >> 16); MEMORY[index+1][0] = (uint8_t)((write_word & 0xFF000000) >> 24);}
        else if(remainder == 2) {MEMORY[index][2] = (uint8_t)(write_word & 0x000000FF); MEMORY[index][3] = (uint8_t)((write_word & 0x0000FF00) >> 8); MEMORY[index+1][0] = (uint8_t)((write_word & 0x00FF0000) >> 16); MEMORY[index+1][1] = (uint8_t)((write_word & 0xFF000000) >> 24);}
        else if(remainder == 3) {MEMORY[index][3] = (uint8_t)(write_word & 0x000000FF); MEMORY[index+1][0] = (uint8_t)((write_word & 0x0000FF00) >> 8); MEMORY[index+1][1] = (uint8_t)((write_word & 0x00FF0000) >> 16); MEMORY[index+1][2] = (uint8_t)((write_word & 0xFF000000) >> 24);}
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
    //fprintf("\nCycle Count : %d\nPC : 0x%08x\n", CYCLE_COUNT, PC);
    for (int i = 0; i < 32; i++) {
        printf("x%-2d: 0x%08x %s", i, REGS[i],
               (i % 4 == 3) ? "\n" : "  ");
        fprintf(dumpsim_file, "x%-2d: 0x%08x %s", i, REGS[i],
                (i % 4 == 3) ? "\n" : "  ");
    }
    fflush(dumpsim_file);
}

void bdump(FILE *dumpsim_file) {
    printf("\nBranch Pred Table:\n");
    for (int i = 0; i < (1 << GHR_LENGTH); i++) {
        printf("x%-2d: 0x%06x | %02x\n", i, BP_Tag_Store[i], BP_Seq_Store[i]);
        fprintf("x%-2d: 0x%06x | %02x\n", i, BP_Tag_Store[i], BP_Seq_Store[i]);
    }
    fflush(dumpsim_file);
}

int idump_ld_agu0, id_rs1, id_rd;
int flag, idump_rs1, idump_rs2, idump_aug0, idump_metadata_storage_state, idump_metadata_storage_next_state;
int idump_pxl_block_state, idump_pxl_block_next_state;
int idump_size_extract_state, idump_size_extract_next_state;
int idump_kern_size_state, idump_kern_size_next_state;
int idump_dp_block_state, idump_dp_block_next_state;
int idump_bias_add_state, idump_bias_add_next_state;
int idump_fc_state, idump_fc_next_state;

void idump(FILE *dumpsim_file) {
    printf("\n--- Internal State ---\n");
    printf("Cycle: %d  PC: 0x%08x\n", CYCLE_COUNT, PC);
    printf("Stalls: dep_stall=%d ex_stall=%d mem_stall=%d id_br_stall=%d ex_br_stall=%d icache_r=%d dcache_r=%d jmp_pcmux=%d\n", dep_stall, ex_stall, mem_stall, id_br_stall, ex_br_stall, icache_r, dcache_r, jmp_pcmux);
    printf("Aug0 Info: ld_aug0=%d, id_sr1=%08x, id_rd=%d\n", idump_ld_agu0, id_rs1, id_rd);
    printf("IF: V=%d PC=0x%08x IR=0x%08x\n", PS.IF_V, PS.IF_PC, PS.IF_IR);
    printf("ID: V=%d PC=0x%08x IR=0x%08x RS1=0x%08x RS2=0x%08x RS3=0x%08x IMM=0x%08x RD=%d\n",
           PS.ID_V, PS.ID_PC, PS.ID_IR, PS.ID_RS1, PS.ID_RS2, PS.ID_RS3, PS.ID_IMM, PS.ID_RD);
    printf("EX: V=%d PC=0x%08x IR=0x%08x ALU=0x%08x TA=0x%08x RD=%d\n",
           PS.EX_V, PS.EX_PC, PS.EX_IR, PS.EX_ALU_RESULT, PS.EX_TA, PS.EX_RD);
    printf("AUG1: START=0x%d PIXEL_PTR=0x%08x OUTPUT_PTR=0x%08x OUTPUT_PTRA=0x%08x OUTPUT_PTRB=%08x OUTPUT_PTRC=%08x CYCLE_AMNT\n",
           PS.S1_START, PS.S1_PIXEL_PTR, PS.S1_OUTPUT_PTR, PS.S1_OUTPUT_PTR_A, PS.S1_OUTPUT_PTR_B, PS.S1_OUTPUT_PTR_C, PS.S1_CYCLE_AMNT);
    printf("MEM: V=%d PC=0x%08x IR=0x%08x ALU=0x%08x DATA=0x%08x RD=%d\n",
           PS.MEM_V, PS.MEM_PC, PS.MEM_IR, PS.MEM_ALU_RESULT, PS.MEM_DATA, PS.MEM_RD);
    printf("Flags: flag=%d, rs1=%d, rs2=%d, idump_aug0=%d\n", flag, idump_rs1, idump_rs2, idump_aug0);
    printf("Metadata_stage: next_state=%d, current_state=%d\n", idump_metadata_storage_next_state, idump_metadata_storage_state);
    printf("Pixel_stage: next_state=%d, current_state=%d\n", idump_pxl_block_next_state, idump_pxl_block_state);
    printf("Size_extract_stage: next_state=%d, current_state=%d\n", idump_size_extract_next_state, idump_size_extract_state);
    printf("Kern_size_stage: next_state=%d, current_state=%d\n", idump_kern_size_next_state, idump_kern_size_state);
    printf("DP_block_stage: next_state=%d, current_state=%d\n", idump_dp_block_next_state, idump_dp_block_state);
    printf("Bias_add_stage: next_state=%d, current_state=%d\n", idump_bias_add_next_state, idump_bias_add_state);
    printf("FC_stage: next_state=%d, current_state=%d\n", idump_fc_next_state, idump_fc_state);

    /* also print to dumpsim file */
    fprintf(dumpsim_file, "\n--- Internal State at cycle %d ---\n", CYCLE_COUNT);
    fprintf(dumpsim_file, "PC: 0x%08x\n", PC);
    fprintf(dumpsim_file, "Stalls: dep_stall=%d ex_stall=%d mem_stall=%d id_br_stall=%d ex_br_stall=%d icache_r=%d dcache_r=%d jmp_pcmux=%d\n", dep_stall, ex_stall, mem_stall, id_br_stall, ex_br_stall, icache_r, dcache_r, jmp_pcmux);
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
    printf("idump       - dump pipeline status\n");
    printf("bdump       - dump branch pred table\n");
    printf("load a f    - load hex data from file f into memory at byte address a\n");
    printf("?            - display help\n");
    printf("quit        - exit simulator\n\n");
}

void dpe(uint32_t kern, uint32_t* buff, uint8_t* out){
    uint8_t elem0 =     (buff[0] >> 24) & 0x000000FF;
    uint8_t elem1 =     (buff[0] >> 16) & 0x000000FF;
    uint8_t elem2 =     (buff[0] >> 8) & 0x000000FF;
    uint8_t elem3 =     (buff[0]) & 0x000000FF;
    uint8_t elem4 =     (buff[1] >> 24) & 0x000000FF;
    uint8_t elem5 =     (buff[1] >> 16) & 0x000000FF;
    uint8_t elem6 =     (buff[1] >> 8) & 0x000000FF;
    uint8_t elem7 =     (buff[1]) & 0x000000FF;
    uint8_t elem8 =     (buff[2] >> 24) & 0x000000FF;
    uint8_t elem9 =     (buff[2] >> 16) & 0x000000FF;
    uint8_t elem10 =    (buff[2] >> 8) & 0x000000FF;
    uint8_t elem11 =    (buff[2]) & 0x000000FF;
    uint8_t elem12 =    (buff[3] >> 24) & 0x000000FF;
    uint8_t elem13 =    (buff[3] >> 16) & 0x000000FF;
    uint8_t elem14 =    (buff[3] >> 8) & 0x000000FF;
    uint8_t elem15 =    (buff[3]) & 0x000000FF;

    uint8_t kern0 =     (kern >> 24) & 0x000000FF;
    uint8_t kern1 =     (kern >> 16) & 0x000000FF;
    uint8_t kern2 =     (kern >> 8) & 0x000000FF;
    uint8_t kern3 =     (kern) & 0x000000FF;

    out[0] = (uint8_t)((elem0*kern0) + (elem1*kern1) + (elem4*kern2) + (elem5*kern3));
    out[1] = (uint8_t)((elem1*kern0) + (elem2*kern1) + (elem5*kern2) + (elem6*kern3));
    out[2] = (uint8_t)((elem2*kern0) + (elem3*kern1) + (elem6*kern2) + (elem7*kern3));
    out[3] = (uint8_t)((elem4*kern0) + (elem5*kern1) + (elem8*kern2) + (elem9*kern3));
    out[4] = (uint8_t)((elem5*kern0) + (elem6*kern1) + (elem9*kern2) + (elem10*kern3));
    out[5] = (uint8_t)((elem6*kern0) + (elem7*kern1) + (elem10*kern2) + (elem11*kern3));
    out[6] = (uint8_t)((elem8*kern0)  + (elem9*kern1)  + (elem12*kern2) + (elem13*kern3));
    out[7] = (uint8_t)((elem9*kern0)  + (elem10*kern1) + (elem13*kern2) + (elem14*kern3));
    out[8] = (uint8_t)((elem10*kern0) + (elem11*kern1) + (elem14*kern2) + (elem15*kern3));

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
/*void get_command(FILE *dumpsim_file) {
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
}*/

void init_state() {
    memset(&PS,0,sizeof(PipeState));
    memset(&NEW_PS,0,sizeof(PipeState));
    for (int i=0;i<32;i++) REGS[i]=0;
    RUN_BIT = TRUE;
    CYCLE_COUNT = 0;
    dep_stall = 0; ex_stall = 0; mem_stall = 0; id_br_stall = 0; ex_br_stall = 0; icache_r = 1; dcache_r = 1;
}

void init_memory(void) {
    memset(MEMORY, 0, sizeof(MEMORY));
}

void load_program(const char *fname) {
    FILE *f = fopen(fname,"r");
    if (!f) { printf("Can't open program file %s\n", fname); exit(1); }
    uint32_t word;
    if (fscanf(f,"%x\n",&word) == EOF) { fclose(f); return; }
    PC = word;
    uint32_t addr = PC;
    addr = addr >> 2;
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

void load_mem_data(const char *fname, uint32_t start_addr) {
    FILE *f = fopen(fname, "r");
    if (!f) {
        printf("ERROR: Cannot open data file '%s'\n", fname);
        return;
    }
 
    uint32_t byte_addr = start_addr;
    int byte_count = 0;
    int c, nibble_buf = -1;
 
    while ((c = fgetc(f)) != EOF) {
        /* Convert character to hex nibble value, skip non-hex chars */
        int nibble;
        if      (c >= '0' && c <= '9') nibble = c - '0';
        else if (c >= 'a' && c <= 'f') nibble = c - 'a' + 10;
        else if (c >= 'A' && c <= 'F') nibble = c - 'A' + 10;
        else continue;
 
        if (nibble_buf == -1) {
            nibble_buf = nibble;        /* got high nibble, wait for low */
        } else {
            /* Both nibbles ready: form one byte and write to MEMORY */
            uint8_t byte = (uint8_t)((nibble_buf << 4) | nibble);
            nibble_buf = -1;
 
            uint32_t word_idx  = byte_addr >> 2;   /* which MEMORY row   */
            uint32_t byte_lane = byte_addr &  3;   /* which byte [0..3]  */
 
            if (word_idx >= WORDS_IN_MEM) {
                printf("WARNING: Data exceeds memory bounds -- truncated.\n");
                break;
            }
 
            MEMORY[word_idx][byte_lane] = byte;
            byte_addr++;
            byte_count++;
        }
    }
 
    fclose(f);
    printf("Loaded %d byte(s) from '%s' into memory starting at 0x%08x\n",
           byte_count, fname, start_addr);
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
    } else if (buffer[0]=='b' || buffer[0]=='B') {
        bdump(dumpsim_file);
    } else if (buffer[0]=='l' || buffer[0]=='L') {
        /* load <hex_addr> <filename>  – load raw data into memory */
        uint32_t start_addr;
        char fname[256];
        if (scanf("%x %255s", &start_addr, fname) == 2) {
            load_mem_data(fname, start_addr);
        } else {
            printf("Usage: load <start_addr_hex> <filename>\n");
        }
    } else { printf("Unknown command\n"); }
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

uint32_t sext(uint32_t input, uint32_t firstemptydigit) {
    uint32_t base = 0xFFFFFFFF;
    base = base << firstemptydigit; 
    base = 0xFFFFFFFF - base;
    input = input & base;
    uint32_t index = 0x00000001 << (firstemptydigit - 1);
    uint32_t value = input & index;
    if (value == 0) {return input;}
    else {
        for(int i = firstemptydigit; i < 32; i++) {
            index = index << 1;
            input = input + index;
        }
        return input;
    }
}


uint8_t branchPredictionEval (int PC) {
    PC = PC >> 2;
    int key = (PC ^ GHR) & (1 << GHR_LENGTH) - 1;
    int tag = PC;
    if (BP_Tag_Store[key] != tag) {return 0;}
    else {return (BP_Seq_Store[key] & 0x2) >> 1;}
}

uint32_t branchPredictionTarget (int PC) {
    PC = PC >> 2;
    int key = (PC ^ GHR) & (1 << GHR_LENGTH) - 1;
    int tag = PC;
    return BP_Target_Store[key];
}

void branchPredictionUpdate (int PC, int target, int result) {
    result &= 1;
    PC = PC >> 2;
    int key = (PC ^ GHR) & (1 << GHR_LENGTH) - 1;
    int tag = PC;
    GHR = (GHR << 1) & (1 << GHR_LENGTH) - 1 ;
    GHR += result;

    // Tag Overwrite
    if (BP_Tag_Store[key] != tag) {
        BP_Tag_Store[key] = tag;
        BP_Seq_Store[key] = 1;
        BP_Target_Store[key] = target;
    }

    // 2 bit sat counter
    if (!result && BP_Seq_Store[key] != 0){BP_Seq_Store[key] -= 1;}
    if (result && BP_Seq_Store[key] != 3){BP_Seq_Store[key] += 1;}

    // Sequence Predictor
    // seq = BP_SeqLen_Store[key] & ((1 << BRANCH_PRED_SEQ_LEN) - 1);
    // if (BP_SeqLen_Store[key] != BRANCH_PRED_SEQ_LEN) {
    //     BP_SeqLen_Store[key] += 1;
    //     BP_Seq_Store[key] = (BP_Seq_Store[key] << 1) + result;
    // }

}




/* ========== Stage implementations ========== */

/* Signals generated by WB stage and needed by previous stages */
int v_wb_ld_reg,
    v_wb_df,
    wb_dr,
    wb_data;

/***************************************************************/
/* Pipeline Stage: WB                                           */
/***************************************************************/
void WB_stage(void) {

    v_wb_ld_reg = PS.MEM_CS[CS_LDREG] & PS.MEM_V;
    v_wb_df = v_wb_ld_reg;
    wb_dr = PS.MEM_RD;

    int wb_mux = (PS.MEM_CS[CS_WB_MUX1] << 1) + PS.MEM_CS[CS_WB_MUX0];
    switch (wb_mux) {
        case 0: // PC + 4
            wb_data = Low32bits(PS.MEM_PC + 4);
            break;
        case 1: // Memory result
            wb_data = Low32bits(PS.MEM_DATA);
            break;
        case 2: // ALU result
            wb_data = Low32bits(PS.MEM_ALU_RESULT);
            break;
        case 3:
            wb_data = 0;
            break;
    }


}

/* Signals generated by MEM stage and needed by previous stages */
int v_mem_ld_reg,
    v_mem_df,
    mem_dr,
    fb_mem_data;
    

/***************************************************************/
/* Pipeline Stage: MEM                                          */
/***************************************************************/
void MEM_stage(void) {

    v_mem_ld_reg = PS.EX_CS[CS_LDREG] & PS.EX_V;
    mem_dr = PS.EX_RD;
    
    uint32_t IR = PS.EX_IR;
    int dcache_r = 0; 
    uint32_t mem_data = 0;
    int ldst_op = (PS.EX_CS[CS_LDST_OP2] << 2) + (PS.EX_CS[CS_LDST_OP1] << 1) + PS.EX_CS[CS_LDST_OP0];

    if ((PS.EX_V == 1) && (PS.EX_CS[CS_LDST] == 1)) {dcache_access(PS.EX_TA, &mem_data, PS.EX_ALU_RESULT, &dcache_r, ldst_op);}
    if ((PS.EX_V == 1) && (PS.EX_CS[CS_LDST] == 1) && (dcache_r == 0)) {mem_stall = 1;}
    if ((PS.EX_V == 0) || (PS.EX_CS[CS_LDST] == 0) || (dcache_r == 1)) {mem_stall = 0;}

    if(ldst_op == 0) {
        mem_data = mem_data & 0x000000FF;
        if((mem_data & 0x00000080) > 0) {mem_data = mem_data + 0xFFFFFF00;}
    }
    else if(ldst_op == 1) {
        mem_data = mem_data & 0x0000FFFF;
        if((mem_data & 0x00008000) > 0) {mem_data = mem_data + 0xFFFF0000;}
    }
    else if(ldst_op == 3) {
        mem_data = mem_data & 0x000000FF;
    }
    else if(ldst_op == 4) {
        mem_data = mem_data & 0x0000FFFF;
    }

    switch ((PS.EX_CS[CS_WB_MUX1] << 1) + PS.EX_CS[CS_WB_MUX0]) {
        case 0: // PC + 4
            mem_data = Low32bits(PS.EX_PC + 4);
            break;
        case 1: // Memory result
            mem_data = Low32bits(mem_data);
            break;
        case 2: // ALU result
            mem_data = Low32bits(PS.EX_ALU_RESULT);
            break;
        case 3:
            mem_data = 0;
            break;
    }

    fb_mem_data = mem_data;

    v_mem_df = v_mem_ld_reg && !mem_stall;
    NEW_PS.MEM_ALU_RESULT = PS.EX_ALU_RESULT;
    NEW_PS.MEM_IR = IR;
    NEW_PS.MEM_DATA = Low32bits(mem_data);
    NEW_PS.MEM_PC = PS.EX_PC;
    NEW_PS.MEM_RD = PS.EX_RD;
    memcpy(NEW_PS.MEM_CS, PS.EX_CS, sizeof(int) * NUM_CONTROL_SIGNALS);
    if((PS.EX_V == 1) && (mem_stall == 0)) {NEW_PS.MEM_V = 1;}
    else {NEW_PS.MEM_V = 0;}
}

/***************************************************************/
/* Individual Blocks: Inside Ex                                */
/***************************************************************/

//FC Registers
uint32_t fc_pxl_ptr, fc_output_ptr, fc_weight_ptr;
uint32_t fc_temp_data, fc_temp_weight;
uint32_t dpe_val;
uint32_t fc_index, fc_size;

// Bias add registers
uint32_t bias_index;
uint32_t temp_data;
uint32_t bias;
uint32_t sum;
uint32_t bias_ptr;
uint32_t bias_pxl_ptr;
uint32_t sum_ptr;
uint32_t cnv_size;


// Aug0/Aug1 Registers
uint32_t pixel_ptr, output_ptr, output_ptrA, output_ptrB, output_ptrC, cycle_amnt, cols, lat_shifts, vert_shifts, chn_amnt, kern_size, kern_ptr, bias_ptr, size, weight_ptr, ready;

// Dot Product local Registers
uint32_t vert, lat, kern_ch, chn;
uint32_t row0, row1, row2, row3;
uint8_t out_layers[9];
uint8_t decode_stall;
uint32_t kern_buf[16];
uint32_t buff[64];

// Metadata_storage local Registers
uint32_t width;
uint32_t height;
uint32_t channels = 0x03;
uint32_t size;
uint32_t dblSize;

// Pixel Decoding Local Registers
uint32_t one, two, thr;
uint32_t red, grn, blu;
uint32_t inter_output_ptrA, inter_output_ptrB, inter_output_ptrC;
uint32_t inter_pixel_ptr, inter_cycle_amnt;

// State Aug 0
uint32_t metadata_storage_state = 0;
uint32_t metadata_storage_next_state = 0;
uint32_t size_extract_state = 0;
uint32_t size_extract_next_state = 0;
uint32_t kern_size_state = 0;
uint32_t kern_size_next_state = 0;
uint32_t meta_block_done = 0;
uint32_t size_block_done = 0;
uint32_t kern_block_done = 0;
uint32_t kern_ready = 0;
int aug0_start;

// State Aug 1
uint32_t pixel_block_state;
uint32_t pixel_block_next_state;
uint32_t dot_product_state;
uint32_t dot_product_next_state;
uint32_t bias_add_state;
uint32_t bias_add_next_state;
uint32_t fc_proc_state;
uint32_t fc_proc_next_state;
uint32_t aug1_stall;

void fully_connected(uint32_t start, uint32_t state, uint32_t* next_state){
    int dcache_r = 0;

    if (state == 0){
        if (start){
            *next_state = 1;
            printf("FC_Pixel_Ptr: %x\n", PS.S1_PIXEL_PTR);
            printf("FC_Output_Ptr: %x\n", PS.S1_OUTPUT_PTR);
            printf("FC_Weight_Ptr: %x\n", PS.S1_WEIGHT_PTR);
            fc_pxl_ptr = PS.S1_PIXEL_PTR;
            fc_output_ptr = PS.S1_OUTPUT_PTR;
            fc_weight_ptr = PS.S1_WEIGHT_PTR;
        } else {
            *next_state = 0;
        }
    }

    else if (state == 1){
        fc_size = PS.S1_CHN_AMNT * PS.S1_COLS * PS.S1_COLS;
        dpe_val = 0;
        printf("FC_Size: %d\n", fc_size);
        fc_index = 0;
        *next_state = 2;
    }

    else if (state == 2){
        dcache_access(fc_pxl_ptr + fc_index, &fc_temp_data, 0, &dcache_r, 4);
        printf("FC_Temp_Data: %x\n", fc_temp_data);
        *next_state = 3;
    }

    else if (state == 3){
        dcache_access(fc_weight_ptr + fc_index, &fc_temp_weight, 0, &dcache_r, 4);
        printf("FC_Temp_Weight: %x\n", fc_temp_weight);
        *next_state = 4;
    }

    else if (state == 4){
        int8_t temp_data_arr[4];
        temp_data_arr[0] = (fc_temp_data >> 24) & 0x000000FF;
        temp_data_arr[1] = (fc_temp_data >> 16) & 0x000000FF;
        temp_data_arr[2] = (fc_temp_data >> 8) & 0x000000FF;
        temp_data_arr[3] = (fc_temp_data) & 0x000000FF;

        int8_t temp_weight_arr[4];
        temp_weight_arr[0] = (fc_temp_weight >> 24) & 0x000000FF;
        temp_weight_arr[1] = (fc_temp_weight >> 16) & 0x000000FF;
        temp_weight_arr[2] = (fc_temp_weight >> 8) & 0x000000FF;
        temp_weight_arr[3] = (fc_temp_weight) & 0x000000FF;

        dpe_val += (temp_data_arr[0] * temp_weight_arr[0]) + (temp_data_arr[1] * temp_weight_arr[1]) + (temp_data_arr[2] * temp_weight_arr[2]) + (temp_data_arr[3] * temp_weight_arr[3]);
        printf("DPE_Val: %x\n", dpe_val);
        fc_index += 4;
        *next_state = 5;
    }

    else if (state == 5){
        if (fc_index < fc_size){
            *next_state = 2;
        } else {
            *next_state = 6;   
        }
    }

    else if (state == 6){
        dcache_access(fc_output_ptr, &dcache_r, dpe_val, &dcache_r, 7);
        ex_stall = 0;
        *next_state = 0;
    }
}

void bias_add(uint32_t start, uint32_t state, uint32_t* next_state){
    int dcache_r = 0;
    if (state == 0){
        if (start == 1){
            *next_state = 1;
            printf("Bias_Ptr: %x\n", PS.S1_BIAS_PTR);
            printf("Output_Ptr: %x\n", PS.S1_OUTPUT_PTR);
            bias_ptr = PS.S1_BIAS_PTR;
            sum_ptr = PS.S1_OUTPUT_PTR;
            bias_pxl_ptr = PS.S1_PIXEL_PTR;
        } else {
            *next_state = 0;
        }
    }

    else if (state == 1){
        cnv_size = PS.S1_CHN_AMNT * PS.S1_COLS * PS.S1_COLS;
        printf("Cnv_Size: %d\n", cnv_size);
        bias_index = 0;
        *next_state = 2;
    }

    else if (state == 2){
        dcache_access(bias_pxl_ptr + bias_index, &temp_data, 0, &dcache_r, 4);
        printf("Temp_Data: %x\n", temp_data);
        *next_state = 3;
    }

    else if (state == 3){
        dcache_access(bias_ptr + bias_index, &bias, 0, &dcache_r, 4);
        printf("Bias: %x\n", bias);
        *next_state = 4;
    }

    else if (state == 4){
        uint32_t sum_arr[4];
        sum_arr[0] = ((temp_data & 0x000000FF) + (bias & 0x000000FF)) & 0x000000FF;
        printf("Temp_data: %x, Bias_data: %x, Sum_Arr[0]: %x\n", temp_data & 0x000000FF, bias & 0x000000FF, sum_arr[0]);
        sum_arr[1] = (((temp_data & 0x0000FF00) >> 8) + ((bias & 0x0000FF00) >> 8)) & 0x000000FF;
        printf("Temp_data: %x, Bias_data: %x, Sum_Arr[1]: %x\n", temp_data & 0x0000FF00, bias & 0x0000FF00, sum_arr[1]);
        sum_arr[2] = (((temp_data & 0x00FF0000) >> 16) + ((bias & 0x00FF0000) >> 16)) & 0x000000FF;
        printf("Temp_data: %x, Bias_data: %x, Sum_Arr[2]: %x\n", temp_data & 0x00FF0000, bias & 0x00FF0000, sum_arr[2]);
        sum_arr[3] = (((temp_data & 0xFF000000) >> 24) + ((bias & 0xFF000000) >> 24)) & 0x000000FF;
        printf("Temp_data: %x, Bias_data: %x, Sum_Arr[3]: %x\n", temp_data & 0xFF000000, bias & 0xFF000000, sum_arr[3]);
        sum = (sum_arr[0] & 0x000000FF) + ((sum_arr[1] << 8) & 0x0000FF00) + ((sum_arr[2] << 16) & 0x00FF0000) + ((sum_arr[3] << 24) & 0xFF000000);
        printf("Sum: %x\n", sum);
        *next_state = 5;
    }

    else if (state == 5){
        dcache_access(sum_ptr + bias_index, &dcache_r, sum, &dcache_r, 7);
        bias_index += 4;
        *next_state = 6;
    }

    else if (state == 6){
        if (bias_index < cnv_size){
            *next_state = 2;
        } else {
            *next_state = 0;
            ex_stall = 0;
        }
    }
}

void size_extract(uint32_t start, uint32_t state, uint32_t* next_state, int is_fc){
    int dcache_r = 0;
    // State 0
    if (state == 0) {
        size_block_done = 0;
        kern_ready = 0;
        if (start == 1) {
            *next_state = 1;
            output_ptr = PS.ID_RS2;
            ex_stall = 1;
        } else {
            *next_state = 0;
        }
    
    // State 1
    } else if (state == 1) {
        dcache_access(PS.ID_RS3, &chn_amnt, 0, &dcache_r, 4);
        printf("Chn_Amnt: %d\n", chn_amnt);
        *next_state = 2;
    // State 2
    } else if (state == 2) {
        dcache_access(PS.ID_RS3 + 4, &cols, 0, &dcache_r, 4);
        printf("Cols: %d\n", cols);
        *next_state = 3;

    // State 3
    } else if (state == 3) {
        dcache_access(PS.ID_RS3 + 8, &height, 0, &dcache_r, 4);
        printf("Height: %d\n", height);
        if (is_fc){
            *next_state = 4;
        } else {
            *next_state = 5;
        }
    
    // State 4
    } else if (state == 4) {
        size = chn_amnt*cols*height;
        pixel_ptr = PS.ID_RS3 + 12;
        *next_state = 0;
        size_block_done = 1;
    
    //State 5
    }  else if (state == 5) {
        lat_shifts = cols - 3;
        vert_shifts = height - 3;
        pixel_ptr = PS.ID_RS3 + 12;
        kern_ready = 1;
        *next_state = 0;
    }
}

void kern_extract(uint32_t ready, uint32_t state, uint32_t* next_state){
    int dcache_r = 0;
    if (state == 0) {
        if (ready == 1) {
            *next_state = 1;
            
        } else {
            *next_state = 0;
            kern_block_done = 0;
        }
    
    // State 1
    } else if (state == 1){
        dcache_access(PS.ID_RS1, &kern_size, 0, &dcache_r, 4);
        printf("Kern_Size: %d\n", kern_size);
        *next_state = 2;
    }

    // State 2
    else if (state == 2){
        kern_ptr = PS.ID_RS1 + 4;
        *next_state = 0;
        kern_block_done = 1;
    }
}

void dot_product(uint32_t start, uint32_t state, uint32_t* next_state){
    int dcache_r = 0;
    if (state == 0){
        if (start == 1){
            *next_state = 1;
            printf("Pixel_Ptr: %x\n", PS.S1_PIXEL_PTR);
            printf("Size: %d\n", PS.S1_SIZE);
            printf("Cols: %d\n", PS.S1_COLS);
            printf("Lat_Shifts: %d\n", PS.S1_LAT_SHIFTS);
            printf("Vert_Shifts: %d\n", PS.S1_VERT_SHIFTS);
            printf("Chn_Amnt: %d\n", PS.S1_CHN_AMNT);
            printf("Kern_Size: %d\n", PS.S1_KERN_SIZE);
            printf("Kern_Ptr: %x\n", PS.S1_KERN_PTR);
        } else {
            *next_state = 0;
        }
    }

    // State 1
    else if (state == 1){
        kern_ch = 0;
        vert = 0;
        lat = 0;
        *next_state = 2;
    }

    // State 2
    else if (state == 2){
        uint32_t address = PS.S1_KERN_PTR + (4*kern_ch);
        dcache_access(address, &kern_buf[kern_ch], 0, &dcache_r, 4);
        printf("Kern_Ch: %d, Address: %x, Value: %x\n", kern_ch, address, kern_buf[kern_ch]);
        kern_ch += 1;
        *next_state = 3;
    }

    //Stage 3
    else if (state == 3){
        if (kern_ch == PS.S1_CHN_AMNT){
            *next_state = 4;
        } else {
            *next_state = 2;
        }
    }

    //State 4
    else if (state == 4){
        printf("Kern_buf: %x %x %x %x\n", kern_buf[0], kern_buf[1], kern_buf[2], kern_buf[3]);
        printf("Kern_buf: %x %x %x %x\n", kern_buf[4], kern_buf[5], kern_buf[6], kern_buf[7]);
        printf("Kern_buf: %x %x %x %x\n", kern_buf[8], kern_buf[9], kern_buf[10], kern_buf[11]);
        printf("Kern_buf: %x %x %x %x\n", kern_buf[12], kern_buf[13], kern_buf[14], kern_buf[15]);
        chn = 0;
        row0 = (vert * cols) + lat;
        row1 = (vert + 1) * cols + lat;
        row2 = (vert + 2) * cols + lat;
        row3 = (vert + 3) * cols + lat;
        *next_state = 5;
    }

    // State 5
    else if (state == 5){
        dcache_access(row0 + PS.S1_PIXEL_PTR + (chn * PS.S1_SIZE), &buff[4 * chn], 0, &dcache_r, 4);
            printf("Row0 Address: %x\n", row0 + PS.S1_PIXEL_PTR + (chn * PS.S1_SIZE));
            printf("Row0 Value: %x\n", buff[4 * chn]);
        *next_state = 6;
    }

    //State 6
    else if (state == 6){
        dcache_access(row1 + PS.S1_PIXEL_PTR + (chn * PS.S1_SIZE), &buff[4 * chn + 1], 0, &dcache_r, 4);
            printf("Row1 Address: %x\n", row1 + PS.S1_PIXEL_PTR + (chn * PS.S1_SIZE));
            printf("Row1 Value: %x\n", buff[4 * chn + 1]);
        *next_state = 7;
    }

    // State 7
    else if (state == 7){
        dcache_access(row2 + PS.S1_PIXEL_PTR + (chn * PS.S1_SIZE), &buff[4 * chn + 2], 0, &dcache_r, 4);
            printf("Row2 Address: %x\n", row2 + PS.S1_PIXEL_PTR + (chn * PS.S1_SIZE));
            printf("Row2 Value: %x\n", buff[4 * chn + 2]);
        *next_state = 8;
    }

    //State 8
    else if (state == 8){
        dcache_access(row3 + PS.S1_PIXEL_PTR + (chn * PS.S1_SIZE), &buff[4 * chn + 3], 0, &dcache_r, 4);
            printf("Row3 Address: %x\n", row3 + PS.S1_PIXEL_PTR + (chn * PS.S1_SIZE));
            printf("Row3 Value: %x\n", buff[4 * chn + 3]);
        chn = chn + 1;
        *next_state = 9;
    }

    // State 9
    else if (state == 9){
        printf("Row0: %x, Row1: %x, Row2: %x, Row3: %x\n", buff[0], buff[1], buff[2], buff[3]);
        if (chn == PS.S1_CHN_AMNT){
            *next_state = 10;
        } else {
            *next_state = 5;
        }
    }

    // State 10 (dot product)
    else if (state == 10){
        chn = 0;
        uint8_t out_l0[9];
        uint8_t out_l1[9];
        uint8_t out_l2[9];
        uint8_t out_l3[9];
        uint8_t out_l4[9];
        uint8_t out_l5[9];
        uint8_t out_l6[9];
        uint8_t out_l7[9];

        uint8_t out_l8[9];
        uint8_t out_l9[9];
        uint8_t out_l10[9];
        uint8_t out_l11[9];
        uint8_t out_l12[9];
        uint8_t out_l13[9];
        uint8_t out_l14[9];
        uint8_t out_l15[9];

        uint32_t buff_l0[4] = {buff[0], buff[1], buff[2], buff[3]};
        uint32_t buff_l1[4] = {buff[4], buff[5], buff[6], buff[7]};
        uint32_t buff_l2[4] = {buff[8], buff[9], buff[10], buff[11]};
        uint32_t buff_l3[4] = {buff[12], buff[13], buff[14], buff[15]};
        uint32_t buff_l4[4] = {buff[16], buff[17], buff[18], buff[19]};
        uint32_t buff_l5[4] = {buff[20], buff[21], buff[22], buff[23]};
        uint32_t buff_l6[4] = {buff[24], buff[25], buff[26], buff[27]};
        uint32_t buff_l7[4] = {buff[28], buff[29], buff[30], buff[31]};

        uint32_t buff_l8[4] = {buff[32], buff[33], buff[34], buff[35]};
        uint32_t buff_l9[4] = {buff[36], buff[37], buff[38], buff[39]};
        uint32_t buff_l10[4] = {buff[40], buff[41], buff[42], buff[43]};
        uint32_t buff_l11[4] = {buff[44], buff[45], buff[46], buff[47]};
        uint32_t buff_l12[4] = {buff[48], buff[49], buff[50], buff[51]};
        uint32_t buff_l13[4] = {buff[52], buff[53], buff[54], buff[55]};
        uint32_t buff_l14[4] = {buff[56], buff[57], buff[58], buff[59]};
        uint32_t buff_l15[4] = {buff[60], buff[61], buff[62], buff[63]};

        dpe(kern_buf[0], buff_l0, out_l0);
        dpe(kern_buf[1], buff_l1, out_l1);
        dpe(kern_buf[2], buff_l2, out_l2);
        dpe(kern_buf[3], buff_l3, out_l3);
        dpe(kern_buf[4], buff_l4, out_l4);
        dpe(kern_buf[5], buff_l5, out_l5);
        dpe(kern_buf[6], buff_l6, out_l6);
        dpe(kern_buf[7], buff_l7, out_l7);
        dpe(kern_buf[8], buff_l8, out_l8);
        dpe(kern_buf[9], buff_l9, out_l9);
        dpe(kern_buf[10], buff_l10, out_l10);
        dpe(kern_buf[11], buff_l11, out_l11);
        dpe(kern_buf[12], buff_l12, out_l12);
        dpe(kern_buf[13], buff_l13, out_l13);
        dpe(kern_buf[14], buff_l14, out_l14);
        dpe(kern_buf[15], buff_l15, out_l15);

        out_layers[0] = out_l0[0] + out_l1[0] + out_l2[0] + out_l3[0] + out_l4[0] + out_l5[0] + out_l6[0] + out_l7[0] + 
                        out_l8[0] + out_l9[0] + out_l10[0] + out_l11[0] + out_l12[0] + out_l13[0] + out_l14[0] + out_l15[0];

        out_layers[1] = out_l0[1] + out_l1[1] + out_l2[1] + out_l3[1] + out_l4[1] + out_l5[1] + out_l6[1] + out_l7[1] + 
                        out_l8[1] + out_l9[1] + out_l10[1] + out_l11[1] + out_l12[1] + out_l13[1] + out_l14[1] + out_l15[1];

        out_layers[2] = out_l0[2] + out_l1[2] + out_l2[2] + out_l3[2] + out_l4[2] + out_l5[2] + out_l6[2] + out_l7[2] + 
                        out_l8[2] + out_l9[2] + out_l10[2] + out_l11[2] + out_l12[2] + out_l13[2] + out_l14[2] + out_l15[2];
        
        out_layers[3] = out_l0[3] + out_l1[3] + out_l2[3] + out_l3[3] + out_l4[3] + out_l5[3] + out_l6[3] + out_l7[3] + 
                        out_l8[3] + out_l9[3] + out_l10[3] + out_l11[3] + out_l12[3] + out_l13[3] + out_l14[3] + out_l15[3];

        out_layers[4] = out_l0[4] + out_l1[4] + out_l2[4] + out_l3[4] + out_l4[4] + out_l5[4] + out_l6[4] + out_l7[4] + 
                        out_l8[4] + out_l9[4] + out_l10[4] + out_l11[4] + out_l12[4] + out_l13[4] + out_l14[4] + out_l15[4];

        out_layers[5] = out_l0[5] + out_l1[5] + out_l2[5] + out_l3[5] + out_l4[5] + out_l5[5] + out_l6[5] + out_l7[5] + 
                        out_l8[5] + out_l9[5] + out_l10[5] + out_l11[5] + out_l12[5] + out_l13[5] + out_l14[5] + out_l15[5];

        out_layers[6] = out_l0[6] + out_l1[6] + out_l2[6] + out_l3[6] + out_l4[6] + out_l5[6] + out_l6[6] + out_l7[6] + 
                        out_l8[6] + out_l9[6] + out_l10[6] + out_l11[6] + out_l12[6] + out_l13[6] + out_l14[6] + out_l15[6];

        out_layers[7] = out_l0[7] + out_l1[7] + out_l2[7] + out_l3[7] + out_l4[7] + out_l5[7] + out_l6[7] + out_l7[7] + 
                        out_l8[7] + out_l9[7] + out_l10[7] + out_l11[7] + out_l12[7] + out_l13[7] + out_l14[7] + out_l15[7];

        out_layers[8] = out_l0[8] + out_l1[8] + out_l2[8] + out_l3[8] + out_l4[8] + out_l5[8] + out_l6[8] + out_l7[8] + 
                        out_l8[8] + out_l9[8] + out_l10[8] + out_l11[8] + out_l12[8] + out_l13[8] + out_l14[8] + out_l15[8];
        
        printf("Out_Layers: %d %d %d %d %d %d %d %d %d\n", out_layers[0], out_layers[1], out_layers[2], out_layers[3], out_layers[4], out_layers[5], out_layers[6], out_layers[7], out_layers[8]);

        *next_state = 11;
    }

    else if (state == 11){
        uint32_t addr = PS.S1_OUTPUT_PTR + ((PS.S1_COLS - 1) * vert) + lat;
        dcache_access(addr, &dcache_r, out_layers[0], &dcache_r, 5);
        *next_state = 12;
    }

    else if (state == 12){
        uint32_t addr = PS.S1_OUTPUT_PTR + ((PS.S1_COLS - 1) * vert) + lat + 1;
        dcache_access(addr, &dcache_r, out_layers[1], &dcache_r, 5);
        *next_state = 13;
    }

    else if (state == 13){
        uint32_t addr = PS.S1_OUTPUT_PTR + ((PS.S1_COLS - 1) * vert) + lat + 2;
        dcache_access(addr, &dcache_r, out_layers[2], &dcache_r, 5);
        *next_state = 14;
    }

    else if (state == 14){
        uint32_t addr = PS.S1_OUTPUT_PTR + ((PS.S1_COLS - 1) * (vert + 1)) + lat;
        dcache_access(addr, &dcache_r, out_layers[3], &dcache_r, 5);
        *next_state = 15;
    }

    else if (state == 15){
        uint32_t addr = PS.S1_OUTPUT_PTR + ((PS.S1_COLS - 1) * (vert + 1)) + lat + 1;
        dcache_access(addr, &dcache_r, out_layers[4], &dcache_r, 5);
        *next_state = 16;
    }

    else if (state == 16){
        uint32_t addr = PS.S1_OUTPUT_PTR + ((PS.S1_COLS - 1) * (vert + 1)) + lat + 2;
        dcache_access(addr, &dcache_r, out_layers[5], &dcache_r, 5);
        *next_state = 17;
    }

    else if (state == 17){
        uint32_t addr = PS.S1_OUTPUT_PTR + ((PS.S1_COLS - 1) * (vert + 2)) + lat;
        dcache_access(addr, &dcache_r, out_layers[6], &dcache_r, 5);
        *next_state = 18;
    }

    else if (state == 18){
        uint32_t addr = PS.S1_OUTPUT_PTR + ((PS.S1_COLS - 1) * (vert + 2)) + lat + 1;
        dcache_access(addr, &dcache_r, out_layers[7], &dcache_r, 5);
        *next_state = 19;
    }

    else if (state == 19){
        uint32_t addr = PS.S1_OUTPUT_PTR + ((PS.S1_COLS - 1) * (vert + 2)) + lat + 2;
        dcache_access(addr, &dcache_r, out_layers[8], &dcache_r, 5);
        *next_state = 20;
    }

    else if (state == 20) {
        lat += 1;
        *next_state = 21;
    }

    else if (state == 21) {
        if (lat == PS.S1_LAT_SHIFTS){
            *next_state = 22;
        } else {
            *next_state = 4;
        }
    }

    else if (state == 22) {
        lat = 0;
        vert += 1;
        *next_state = 23;
    }

    else if (state == 23) {
        if (vert == PS.S1_VERT_SHIFTS){ 
            *next_state = 0;
            ex_stall = 0;
        } else {
            *next_state = 4;
        }
    }
}


void pixel_decoding(uint32_t start, uint32_t state, uint32_t* next_state){
    int dcache_r = 0; 
    // State 0
    if (state == 0) {
        if (start == 1) {
            *next_state         = 1;
            ex_stall            = 1;
            inter_cycle_amnt   = PS.S1_CYCLE_AMNT;
            inter_output_ptrA  = PS.S1_OUTPUT_PTR_A;
            inter_output_ptrB  = PS.S1_OUTPUT_PTR_B;
            inter_output_ptrC  = PS.S1_OUTPUT_PTR_C;
            inter_pixel_ptr    = PS.S1_PIXEL_PTR;
            
            printf("Inside Func Next_state: %d\n", *next_state);
            printf("Output A: %08x\n", inter_output_ptrA);
            printf("Output B: %08x\n", inter_output_ptrB);
            printf("Output C: %08x\n", inter_output_ptrC);

        } else {
            *next_state = 0;
        }
    
    // State 1
    } else if (state == 1) {
        ex_stall = 1;
        dcache_access(inter_pixel_ptr, &one, 0, &dcache_r, 4);
        printf("one: %08x\n", one);
        printf("Cycle Amnt: %d\n", inter_cycle_amnt);
        *next_state = 2;
    // State 2
    } else if (state == 2) {
        ex_stall = 1;
        dcache_access(inter_pixel_ptr + 4, &two, 0, &dcache_r, 4);
        printf("two: %08x\n", two);
        *next_state = 3;
    // State 3
    } else if (state == 3) {
        ex_stall = 1;
        dcache_access(inter_pixel_ptr + 8, &thr, 0, &dcache_r, 4);
        printf("thr: %08x\n", thr);
        *next_state = 4;
    
    // State 4
    } else if (state == 4) {
        ex_stall = 1;
        blu = ((one & 0x0FF000000) >> 16) + (one & 0x00FF) + (two & 0x00FF0000) + ((thr & 0x0000FF00) << 16);
        grn = ((one & 0x0FF00) >> 8) + ((two & 0x000FF) << 8) + ((two & 0xFF000000) >> 8) + ((thr & 0x0FF0000) << 8);
        red = ((one & 0x00FF0000) >> 16) + (two & 0x0FF00) + (thr & 0xFF000000) + ((thr & 0x000FF) << 16);
        *next_state = 5;
    
    //State 5
    }  else if (state == 5) {
        ex_stall = 1;
        dcache_access(inter_output_ptrA, &dcache_r, blu, &dcache_r, 7);
        inter_output_ptrA = inter_output_ptrA + 4;
        *next_state = 6;

    //State 6
    }  else if (state == 6) {
        ex_stall = 1;
        dcache_access(inter_output_ptrB, &dcache_r, grn, &dcache_r, 7);
        inter_output_ptrB = inter_output_ptrB + 4;
        *next_state = 7;
    }

    //State 7
    else if (state == 7) {
        ex_stall = 1;
        dcache_access(inter_output_ptrC, &dcache_r, red, &dcache_r, 7);
        inter_output_ptrC = inter_output_ptrC + 4;
        *next_state = 8;
        inter_cycle_amnt = inter_cycle_amnt - 1;
    }

    //State 8
    else if (state == 8) {
        inter_pixel_ptr = inter_pixel_ptr + 12;
        if (inter_cycle_amnt == 1) {
            *next_state = 0;
            ex_stall = 0;
        } else {
            ex_stall = 1;
            *next_state = 1;
        }
    }
}

void metadata_storage(uint32_t start,  uint32_t state, uint32_t* next_state) {
    //State 0
    if (state == 0) {
        meta_block_done = 0;
        
        if (start == 1) {            
            *next_state = 1;
            ex_stall = 1;
        } else {
            *next_state = 0;
        }
    
    //State 1
    } else if (state == 1) {
        uint32_t width_address = PS.ID_RS1 + 18;
        channels = 3;
        ex_stall = 1;
        dcache_access(width_address, &width, 0, &dcache_r, 4);
        printf("width: %d\n", width);
        *next_state = 2;
    // State 2
    } else if (state == 2) {
        uint32_t height_address = PS.ID_RS1 + 22;
        dcache_access(height_address, &height, 0, &dcache_r, 4);
        printf("height: %d\n", height);
        ex_stall = 1;
        *next_state = 3;
    //State 3
    } else if (state == 3) {
        uint32_t out_address = PS.ID_RS2;
        dcache_access(out_address, &dcache_r, channels, &dcache_r, 7);
        size = width * height;
        ex_stall = 1;
        *next_state = 4;
    //State 4
    } else if (state == 4) {
        dblSize = size * 2;
        uint32_t out_address = PS.ID_RS2 + 4;
        dcache_access(out_address, &dcache_r, height, &dcache_r, 7);
        ex_stall = 1;
        *next_state = 5;
    //State 5
    } else if (state == 5) {
        dblSize = size * 2;
        uint32_t out_address = PS.ID_RS2 + 8;
        dcache_access(out_address, &dcache_r, width, &dcache_r, 7);
        ex_stall = 1;
        *next_state = 6;
    //State 6
    } else if (state == 6) {
        output_ptr = PS.ID_RS2;
        output_ptrA = PS.ID_RS2 + 12;
        output_ptrB = PS.ID_RS2 + 12 + size;
        output_ptrC = PS.ID_RS2 + 12 + dblSize;
        cycle_amnt = size/4;
        pixel_ptr = PS.ID_RS1 + 54;
        *next_state = 0;
        meta_block_done = 1;
        ex_stall = 1;
    }
}

/* Signals generated by EX stage and needed by previous stages */
int v_ex_ld_reg,
    v_ex_df,
    ex_dr,
    ex_data,
    jmp_pc;

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
    uint32_t srcA = Low32bits(PS.ID_RS1);
    uint32_t srcB = Low32bits((PS.ID_CS[CS_ALU_MUX]) ? PS.ID_IMM : PS.ID_RS2);

    idump_aug0 = 0;

    uint32_t aug1_start = ((meta_block_done == 1) || (kern_block_done == 1) || (size_block_done == 1));

    if (PS.ID_CS[CS_PIXEL_PROCESS]) {
        printf("EXSTALL: %d\n", ex_stall);
        aug0_start = 1;
        if (((metadata_storage_next_state == 0) && (metadata_storage_state != 0)) || (ex_stall == 1)){
            aug0_start = 0;
        }
        idump_aug0 = aug0_start;
        metadata_storage(aug0_start, metadata_storage_state, &metadata_storage_next_state);
        printf("Start: %d\n", PS.S1_START);
        pixel_decoding(PS.S1_START, pixel_block_state, &pixel_block_next_state);
    }

    if (PS.ID_CS[CS_NEEDS_SIZE]) {
        aug0_start = 1;
        if (ex_stall == 1){
            aug0_start = 0;
        }
        idump_aug0 = aug0_start;
        size_extract(aug0_start, size_extract_state, &size_extract_next_state, PS.ID_CS[CS_IS_FC]);
        kern_extract(kern_ready, kern_size_state, &kern_size_next_state);
    }

    if (PS.ID_CS[CS_DP_BLOCK]){
        printf("Start: %d\n", PS.S1_START);
        printf("kern_block_done: %d\n", kern_block_done);
        dot_product(PS.S1_START, dot_product_state, &dot_product_next_state);
    }

    if (PS.ID_CS[CS_BIAS_ADD]){
        printf("Bias Add - Start: %d\n", PS.S1_START);
        bias_add(PS.S1_START, bias_add_state, &bias_add_next_state);
    }

    if (PS.ID_CS[CS_FC]){
        printf("FC - Start: %d\n", PS.S1_START);
        fully_connected(PS.S1_START, fc_proc_state, &fc_proc_next_state);
    }

    idump_metadata_storage_state = metadata_storage_state;
    idump_metadata_storage_next_state = metadata_storage_next_state;
    idump_pxl_block_state = pixel_block_state;
    idump_pxl_block_next_state = pixel_block_next_state;
    metadata_storage_state = metadata_storage_next_state;
    pixel_block_state = pixel_block_next_state;

    idump_size_extract_state = size_extract_state;
    idump_size_extract_next_state = size_extract_next_state;
    idump_kern_size_state = kern_size_state;
    idump_kern_size_next_state = kern_size_next_state;
    size_extract_state = size_extract_next_state;
    kern_size_state = kern_size_next_state;

    idump_dp_block_state = dot_product_state;
    idump_dp_block_next_state = dot_product_next_state;
    dot_product_state = dot_product_next_state;

    idump_bias_add_state = bias_add_state;
    idump_bias_add_next_state = bias_add_next_state;
    bias_add_state = bias_add_next_state;

    idump_fc_state = fc_proc_state;
    idump_fc_next_state = fc_proc_next_state;
    fc_proc_state = fc_proc_next_state;

    printf("aug1_start: %d\n", aug1_start);
    NEW_PS.S1_START = aug1_start;
    NEW_PS.S1_PIXEL_PTR = pixel_ptr;
    NEW_PS.S1_OUTPUT_PTR = output_ptr;
    NEW_PS.S1_OUTPUT_PTR_A = output_ptrA;
    NEW_PS.S1_OUTPUT_PTR_B = output_ptrB;
    NEW_PS.S1_OUTPUT_PTR_C = output_ptrC;
    NEW_PS.S1_CYCLE_AMNT = cycle_amnt;
    NEW_PS.S1_COLS = cols;
    NEW_PS.S1_LAT_SHIFTS = lat_shifts;
    NEW_PS.S1_VERT_SHIFTS = vert_shifts;
    NEW_PS.S1_CHN_AMNT = chn_amnt;
    NEW_PS.S1_KERN_SIZE = kern_size;
    NEW_PS.S1_KERN_PTR = kern_ptr;
    NEW_PS.S1_BIAS_PTR = PS.ID_RS1;
    NEW_PS.S1_SIZE = size;
    NEW_PS.S1_WEIGHT_PTR = PS.ID_RS1;

    // ALU
    switch (alu_op) {
        case 0: result = srcA + srcB; break; // ADD/ADDI
        case 1: result = srcA - srcB; break; // SUB
        case 4: result = srcA >> (srcB & 0x1F); break; // SRL/SRLI
        case 5: result = (int32_t)srcA >> (srcB & 0x1F); break; // SRA/SRAI
        case 6: result = srcA << (srcB & 0x1F); break; // SLL/SLLI
        case 8: result = ((int32_t) srcA < (int32_t) srcB); break; // SLT/SLTI
        case 9: result = ((uint32_t) srcA < (uint32_t) srcB); break; // SLTU/SLTUI
        case 12: result = srcA | srcB; break; // OR/ORI
        case 13: result = srcA & srcB; break; // AND/ANDI
        case 14: result = srcA ^ srcB; break; // XOR/XORI
        case 16: result = (int32_t)srcA * (int32_t)srcB; break; // MUL
        case 17: result = (int64_t)((int32_t)srcA * (int32_t)srcB) >> 32; break; // MULH
        case 18: result = (int64_t)((int32_t)srcA * (uint32_t)srcB) >> 32; break; // MULHSU
        case 19: result = (uint64_t)((uint32_t)srcA * (uint32_t)srcB) >> 32; break; // MULHU
        case 20: if(srcB != 0) {result = ((int32_t)srcA/(int32_t)srcB);} break; // DIV
        case 21: if(srcB != 0) {result = ((uint32_t)srcA/(uint32_t)srcB);} break; // DIVU
        case 22: if(srcB != 0) {result = ((int32_t)srcA%(int32_t)srcB);} break; // REM
        case 23: if(srcB != 0) {result = ((uint32_t)srcA%(uint32_t)srcB);} break; // REMU
        case 31: result = srcB; // PASS THROUGH FOR STORES, LUI
    }
    result = Low32bits(result);

    // COMPARATOR
    switch (comp_op) { 
        case 0: comp_result = 0; break;
        case 1: comp_result = ((int32_t) srcA == (int32_t) PS.ID_RS2); break;
        case 2: comp_result = ((int32_t) srcA != (int32_t) PS.ID_RS2); break;
        case 3: comp_result = ((int32_t) srcA < (int32_t) PS.ID_RS2); break;
        case 4: comp_result = ((int32_t) srcA >= (int32_t) PS.ID_RS2); break;
        case 5: comp_result = ((uint32_t) srcA < (uint32_t) PS.ID_RS2); break;
        case 6: comp_result = ((uint32_t) srcA >= (uint32_t) PS.ID_RS2); break;
        case 7: comp_result = 1;
    }

    // TA ADDER
    ta = PS.ID_CS[CS_TA_MUX] ? PS.ID_RS1 : PS.ID_PC;
    ta = Low32bits(ta + PS.ID_IMM); 

    if(comp_op != 0){branchPredictionUpdate(PS.ID_PC, ta, comp_result);}
    jmp_pc = comp_result ? ta : PS.ID_PC + 4;

    jmp_pcmux = (comp_result ^ PS.ID_TAKEN) & PS.ID_V;

    int LD_MEM = 0;
    if((mem_stall == 0) && (ex_stall == 0)) {LD_MEM = 1;}

    v_ex_df = v_ex_ld_reg && !PS.ID_CS[CS_TA_MUX];
    switch ((PS.ID_CS[CS_WB_MUX1] << 1) + PS.ID_CS[CS_WB_MUX0]) {
        case 0: // PC + 4
            ex_data = Low32bits(PS.ID_PC + 4);
            break;
        case 1: // Memory result
            v_ex_df = 0;
            break;
        case 2: // ALU result
            ex_data = Low32bits(PS.ID_CS[CS_ALU_RESULT_MUX] ? ta : result);
            break;
        case 3:
            ex_data = 0;
            break;
    }

    if(LD_MEM) {
        NEW_PS.EX_ALU_RESULT = PS.ID_CS[CS_ALU_RESULT_MUX] ? ta: result;
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
    int IR30 = (IR & 0x40000000) >> 30;
    int IR5 = (IR & 0x00000020) >> 5;
    int IR3 = (IR & 0x00000008) >> 3;
    int opcode = (IR & 0x0000007F);
    int funct3 = (IR & 0x00007000) >> 12;
    int aug = (IR & 0x00000078) >> 3;
    int IR2 = (IR & 0x03);

    uint32_t ALU_Row = (8*IR5) + funct3;
    uint32_t ld_aug0 = 0;
    if((opcode == 51) && (funct3 == 0)) {ALU_Row = ALU_Row + (16*IR30);}
    if((opcode == 51) && (funct3 == 5)) {ALU_Row = ALU_Row + (16*IR30);}
    if((opcode == 19) && (funct3 == 5)) {ALU_Row = ALU_Row + (16*IR30);}

    uint32_t MULT_Row = funct3;
    uint32_t LDST_Row =(8*IR5) + funct3;
    uint32_t BR_Row = funct3;
    uint32_t ADDCONST_Row = IR5;
    uint32_t JMP_Row = IR3;
    uint32_t AUG_Row = IR2;
    uint32_t Temp_CS[NUM_CONTROL_SIGNALS];
    flag = 0;
    if (((IR >> 0x02) & 0x01) > 0) {
        if (((IR >> 0x04) & 0x01) > 0) {
            memcpy(Temp_CS, CONTROL_STORE_ADDCONST[ADDCONST_Row], sizeof(int) * NUM_CONTROL_SIGNALS);
        } else {
            memcpy(Temp_CS, CONTROL_STORE_JMP[JMP_Row], sizeof(int) * NUM_CONTROL_SIGNALS);
        }
    } 
    else {
        if ((((IR >> 0x02) & 0x01) > 0) || (((IR >> 0x03) & 0x01) > 0) || (((IR >> 0x04) & 0x01) > 0)) {
            // printf("IR: %08x\n", IR);
            if (((IR >> 0x19) & 0x01) && (IR >> 0x05) & 0x01){ 
                memcpy(Temp_CS, CONTROL_STORE_MULT[MULT_Row], sizeof(int) * NUM_CONTROL_SIGNALS);
            } else if (((IR >> 0x03) & 0x01) && ((IR >> 0x04) & 0x01) && ((IR >> 0x04) & 0x05) && ((IR >> 0x04) & 0x06)) {
                memcpy(Temp_CS, CONTROL_STORE_AUG[AUG_Row], sizeof(int) * NUM_CONTROL_SIGNALS);
                // printf("AUG\n");
            }   else {
                memcpy(Temp_CS, CONTROL_STORE_ALU[ALU_Row], sizeof(int) * NUM_CONTROL_SIGNALS);            }
        } 
        else {
            if (((IR >> 0x06) & 0x01) > 0) { 
                memcpy(Temp_CS, CONTROL_STORE_BR[BR_Row], sizeof(int) * NUM_CONTROL_SIGNALS);
            } else { 
                memcpy(Temp_CS, CONTROL_STORE_LDST[LDST_Row], sizeof(int) * NUM_CONTROL_SIGNALS);
            }
        }
    }
    
    //id_br_stall = Temp_CS[CS_BR_STALL] & PS.IF_V;

    int rs1 = (IR >> 15) & 0x1F;
    idump_rs1 = rs1;
    int srd_data;

    int rs2 = (IR >> 20) & 0x1F;
    int rs3 = (IR >> 20) & 0x1F;
    // printf("RS3: %d\n", rs3);
    int rd  = (IR >> 7) & 0x1F;
    

    int sr1_data = REGS[rs1];
    int sr2_data = REGS[rs2];
    int sr3_data = REGS[rs3];
    // printf("CS_AUG_SR2: %d\n", Temp_CS[CS_AUG_SR2]);
    if (Temp_CS[CS_AUG_SR2] == 1) {
        rs2 = (IR >> 7) & 0x1F;
    }

    
    // printf("RS2: %d\n", rs2);


    uint32_t imm = 0;
    int iv = (Temp_CS[CS_IV2] * 4) + (Temp_CS[CS_IV1] * 2) + Temp_CS[CS_IV0];

    switch (iv) {
        case 1: imm = sext((IR >> 20), 12); break;                  // I-type 
        case 2: imm = sext(((IR >> 25) << 5) | ((IR >> 7) & 0x1F), 12); break; // S-type 
        case 3: imm = sext(((IR >> 31) << 12) | (((IR >> 7) & 0x01) << 11)
                        | (((IR >> 25) & 0x3F) << 5) | (((IR >> 8) & 0xF) << 1), 13); break; // B-type 
        case 4: imm = (IR & 0xFFFFF000); break;                     // U-type 
        case 5: imm = sext(((IR >> 31) << 20) | (((IR >> 12) & 0xFF) << 12) 
                        | (((IR >> 20) & 0x01) << 11) | (((IR >> 21) & 0x3FF) << 1), 21); break;  // J-type 
    }
    imm = Low32bits(imm);

    

    if(PS.IF_V == 0) {dep_stall = 0;}
    if(PS.IF_V == 1) {
        // Feed Forward / Data Forwarding
        dep_stall = 0;
        if((Temp_CS[CS_SR1_NEEDED] == 1) && (v_ex_ld_reg == 1) && (rs1 == ex_dr)) {
            if (v_ex_df == 1){
               sr1_data = ex_data;
            } else {dep_stall = 1;}
        } else if((Temp_CS[CS_SR1_NEEDED] == 1) && (v_mem_ld_reg == 1) && (rs1 == mem_dr)) {
            if (v_mem_df == 1){
               sr1_data = fb_mem_data;
            } else {dep_stall = 1;}
        } else if((Temp_CS[CS_SR1_NEEDED] == 1) && (v_wb_ld_reg == 1) && (rs1 == wb_dr)) {
            if (v_wb_df == 1){
               sr1_data = wb_data;
            } else {dep_stall = 1;}
        }

        if((Temp_CS[CS_SR2_NEEDED] == 1) && (v_ex_ld_reg == 1) && (rs2 == ex_dr)) {
            if (v_ex_df == 1){
               sr2_data = ex_data;
            } else {dep_stall = 1;}
        } else if((Temp_CS[CS_SR2_NEEDED] == 1) && (v_mem_ld_reg == 1) && (rs2 == mem_dr)) {
            if (v_mem_df == 1){
               sr2_data = fb_mem_data;
            } else {dep_stall = 1;}
        } else if((Temp_CS[CS_SR2_NEEDED] == 1) && (v_wb_ld_reg == 1) && (rs2 == wb_dr)) {
            if (v_wb_df == 1){
               sr2_data = wb_data;
            } else {dep_stall = 1;}
        }

        if((Temp_CS[CS_SR3_NEEDED] == 1) && (v_ex_ld_reg == 1) && (rs3 == ex_dr)) {
            if (v_ex_df == 1){
               sr3_data = ex_data;
            } else {dep_stall = 1;}
        } else if((Temp_CS[CS_SR3_NEEDED] == 1) && (v_mem_ld_reg == 1) && (rs3 == mem_dr)) {
            if (v_mem_df == 1){
               sr3_data = fb_mem_data;
            } else {dep_stall = 1;}
        } else if((Temp_CS[CS_SR3_NEEDED] == 1) && (v_wb_ld_reg == 1) && (rs3 == wb_dr)) {
            if (v_wb_df == 1){
               sr3_data = wb_data;
            } else {dep_stall = 1;}
        }
    }

    
    
    if (v_wb_ld_reg) {REGS[wb_dr] = wb_data;}
    int LD_EX = 1;
    int LD_AUG0 = 0;
    if(ex_stall == 1) {LD_EX = 0;}
    if(mem_stall == 1) {LD_EX = 0;}

    
    if(LD_EX) {
        NEW_PS.ID_PC = PS.IF_PC;
        NEW_PS.ID_TAKEN = PS.IF_TAKEN;
        NEW_PS.ID_IR = IR;
        NEW_PS.ID_RS1 = sr1_data;
        NEW_PS.ID_RS2 = sr2_data;
        NEW_PS.ID_RS3 = sr3_data;
        NEW_PS.ID_IMM = imm;
        NEW_PS.ID_RD = rd;
        memcpy(NEW_PS.ID_CS, Temp_CS, sizeof(int) * NUM_CONTROL_SIGNALS);
        NEW_PS.ID_V = 0;
        if((PS.IF_V == 1) && (dep_stall == 0) && (jmp_pcmux == 0)) {NEW_PS.ID_V = 1;}
    }

}

/***************************************************************/
/* Pipeline Stage: IF                                          */
/***************************************************************/
void IF_stage(void) {
    
    int icache_r = 0;
    uint32_t instr = 0;

    icache_access(PC, &instr, &icache_r);
    // assuming that instruction cache will never stall

    int taken = branchPredictionEval(PC); // to determine whether we are branching correctly

    int LD_ID = 1;
    if(dep_stall == 1) {LD_ID = 0;}
    if(ex_stall == 1) {LD_ID = 0;}
    if(mem_stall == 1) {LD_ID = 0;}

    if(LD_ID) {
        NEW_PS.IF_PC = PC;
        NEW_PS.IF_IR = Low32bits(instr);
        NEW_PS.IF_V = 0;
        NEW_PS.IF_TAKEN = taken;
        //if((id_br_stall == 0) && (ex_br_stall == 0) && (jmp_pcmux == 0)) {NEW_PS.IF_V = 1;}
        if ((jmp_pcmux == 0)) {NEW_PS.IF_V = 1;}
    }

    int ld_pc = 0;
    //if((id_br_stall == 0) && (ex_br_stall == 0) && (jmp_pcmux == 0) && (LD_ID == 1)) {ld_pc = 1;}
    if((jmp_pcmux == 1) || ((jmp_pcmux == 0) && (LD_ID == 1))) {ld_pc = 1;}

    int predPC;
    predPC = taken ? branchPredictionTarget(PC) : PC + 4;

    if(ld_pc == 1) {
        PC = jmp_pcmux ? Low32bits(jmp_pc) : Low32bits(predPC);
    }
    
}

/* ========== initialization, load program, main ========== */

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
