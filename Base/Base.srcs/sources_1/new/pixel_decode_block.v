`timescale 1ns / 1ps

// =============================================================================
// pixel_decode_block.v
// =============================================================================
// Reads raw 24-bit BGR pixel data from the BMP image (via pixel_ptr),
// extracts R, G, B byte lanes for 4 pixels at a time, and writes the
// packed channel words to the three separate output regions (ptrA/B/C).
//
// Each iteration:
//   1. Load 3 consecutive 32-bit words from pix_ptr (12 bytes = 4 BGR pixels)
//   2. Wire-route bytes into R_word, G_word, B_word (zero gates)
//   3. Store R_word at ptrA, G_word at ptrB, B_word at ptrC
//   4. Advance pix_ptr += 12, ptrA/B/C += 4, cyc_ctr -= 1
//   5. If cyc_ctr_next == 0: done.  Else: loop back to step 1.
//
// Byte layout in BMP memory (little-endian 32-bit words):
//   one = ldw(pix_ptr+0):  [7:0]=B0  [15:8]=G0  [23:16]=R0  [31:24]=B1
//   two = ldw(pix_ptr+4):  [7:0]=G1  [15:8]=R1  [23:16]=B2  [31:24]=G2
//   thr = ldw(pix_ptr+8):  [7:0]=R2  [15:8]=B3  [23:16]=G3  [31:24]=R3
//
// Packed output words:
//   R_word = { thr[31:24], thr[7:0],   two[15:8],  one[23:16] }
//   G_word = { thr[23:16], two[31:24], two[7:0],   one[15:8]  }
//   B_word = { thr[15:8],  two[23:16], one[31:24], one[7:0]   }
//
// FSM state encoding (lower 4 bits of 32-bit state counter):
//   S0 = idle              S5 = store R
//   S1 = read word one     S6 = store G
//   S2 = read word two     S7 = store B
//   S3 = read word three   S8 = update + branch
//   S4 = extract (1 cycle)
// =============================================================================


module pixel_decode_fsm (
    input  wire        clock,
    input  wire        reset,
    input  wire        start,
    input  wire        cyc_zero,      // high when cyc_ctr - 1 == 0

    // Pointer/counter register controls
    output wire        ld_init,       // latch initial values (S0)
    output wire        ld_update,     // latch updated values (S8)

    // Word register load enables
    output wire        ld_one,        // S1 handshake complete
    output wire        ld_two,        // S2 handshake complete
    output wire        ld_thr,        // S3 handshake complete

    // Datapath MUX selects
    output wire [1:0]  rd_sel,        // read offset: 00=0, 01=4, 10=8
    output wire [1:0]  st_data_sel,   // store data:  00=R, 01=G, 10=B
    output wire [1:0]  st_addr_sel,   // store addr:  00=ptrA, 01=ptrB, 10=ptrC
    output wire        ldst_sel,      // 0=read addr, 1=write addr

    // Memory control
    output wire        mem_wr,     // PDW: 1=write, 0=read

    // Status
    output wire        done
);

    // -----------------------------------------------------------------
    // State counter 
    // -----------------------------------------------------------------
    wire [31:0] state_q;
    wire [31:0] state_inc;
    wire [31:0] next_state;
    wire        state_advance;
    wire        cout_state;

    adder u_state_inc (
        .A   (state_q),
        .B   (32'd1),
        .Cin (1'b0),
        .S   (state_inc),
        .Cout(cout_state)
    );

    // S8 branch: cyc_zero==1 -> go to S0 (done), else -> go to S1 (loop)

    wire [31:0] s8_target;

    mux2_32bit u_s8_branch (
        .inputzero  (32'd1),       // cyc_zero=0: loop back to S1
        .inputone   (32'd0),       // cyc_zero=1: terminate at S0
        .select     (cyc_zero),
        .finaloutput(s8_target)
    );

    // Next-state MUX: normal (state+1) vs. S8 branch target
    wire s8;   // forward-used; decoded below

    mux2_32bit u_next_state_mux (
        .inputzero  (state_inc),   // not S8: advance normally
        .inputone   (s8_target),   // S8: branch
        .select     (s8),
        .finaloutput(next_state)
    );

    reg32_en_reset u_state_reg (
        .datainput  (next_state),
        .clock      (clock),
        .enable     (state_advance),
        .reset      (reset),
        .resetvalue (32'd0),
        .dataoutput (state_q)
    );

    // -----------------------------------------------------------------
    // state decode (4-to-9 for states 0-8)
    // -----------------------------------------------------------------
    wire ns3, ns2, ns1, ns0;
    not(ns3, state_q[3]);
    not(ns2, state_q[2]);
    not(ns1, state_q[1]);
    not(ns0, state_q[0]);

    wire s0, s1, s2, s3, s4, s5, s6, s7;
    // s8 already declared above 
    and(s0, ns3, ns2,        ns1,        ns0        );  // 0000  idle
    and(s1, ns3, ns2,        ns1,        state_q[0] );  // 0001  rd1
    and(s2, ns3, ns2,        state_q[1], ns0        );  // 0010  rd2
    and(s3, ns3, ns2,        state_q[1], state_q[0] );  // 0011  rd3
    and(s4, ns3, state_q[2], ns1,        ns0        );  // 0100  extract
    and(s5, ns3, state_q[2], ns1,        state_q[0] );  // 0101  wr R
    and(s6, ns3, state_q[2], state_q[1], ns0        );  // 0110  wr G
    and(s7, ns3, state_q[2], state_q[1], state_q[0] );  // 0111  wr B
    and(s8, state_q[3], ns2, ns1,        ns0        );  // 1000  update

    // -----------------------------------------------------------------
    // req_active register
    // Prevents false advance if mem_ready was already high from a prior state.
    // Goes high one cycle after the FSM enters a memory state, cleared when state_advance fires.
    // -----------------------------------------------------------------
    wire mem_state_w;
    wire not_advance_w;
    wire req_active_next_w;
    wire req_active_q;

    or (mem_state_w,       s1, s2, s3, s5, s6, s7);
    not(not_advance_w,     state_advance);
    and(req_active_next_w, mem_state_w, not_advance_w);

    dff_en_reset u_req_active (
        .datainput  (req_active_next_w),
        .clock      (clock),
        .enable     (1'b1),
        .reset      (reset),
        .resetvalue (1'b0),
        .dataoutput (req_active_q)
    );

    // -----------------------------------------------------------------
    // state_advance logic
    //   S0        : advance on start
    //   S1-S3, S5-S7 : advance when req_active & mem_ready
    //   S4, S8    : advance unconditionally (1-cycle states)
    // -----------------------------------------------------------------
    wire adv_idle_w;
    wire rdy_w;
    wire adv_mem_w;
    wire adv_auto_w;

    and(adv_idle_w, s0, start);
    assign rdy_w = req_active_q;   // mem_ready always 1 (MEM_STALL=0)
    and(adv_mem_w,  mem_state_w, rdy_w);
    or (adv_auto_w, s4, s8);
    or (state_advance, adv_idle_w, adv_mem_w, adv_auto_w);

    // -----------------------------------------------------------------
    // Memory control outputs
    // -----------------------------------------------------------------
    wire mem_wr_w;
    or(mem_wr_w, s5, s6, s7);
    assign mem_wr = mem_wr_w;

    // -----------------------------------------------------------------
    // MUX select outputs
    //   rd_sel     = {s3, s2}  -> 00=offset 0 (S1), 01=4 (S2), 10=8 (S3)
    //   st_data_sel = {s7, s6} -> 00=R (S5), 01=G (S6), 10=B (S7)
    //   st_addr_sel = {s7, s6} -> 00=ptrA, 01=ptrB, 10=ptrC  (same signal)
    //   ldst_sel   = mem_wr    -> 0=read addr, 1=write addr
    // -----------------------------------------------------------------
    assign rd_sel      = {s3, s2};
    assign st_data_sel = {s7, s6};
    assign st_addr_sel = {s7, s6};
    assign ldst_sel    = mem_wr_w;

    // -----------------------------------------------------------------
    // Register load enables
    // -----------------------------------------------------------------
    and(ld_one, s1, rdy_w);
    and(ld_two, s2, rdy_w);
    and(ld_thr, s3, rdy_w);
    and(ld_init, s0, start);
    assign ld_update = s8;

    // -----------------------------------------------------------------
    // done output
    // Registered one cycle after S8 fires with cyc_zero=1, so the calling
    // block sees done=1 only after the final pointer updates have settled.
    // -----------------------------------------------------------------
    wire done_comb;
    and(done_comb, s8, cyc_zero);

    dff_en_reset u_done_dff (
        .datainput  (done_comb),
        .clock      (clock),
        .enable     (1'b1),
        .reset      (reset),
        .resetvalue (1'b0),
        .dataoutput (done)
    );

endmodule


module pixel_decode_block (
    input  wire        clock,
    input  wire        reset,
    input  wire        start,

    // Initial values from metadata_storage_block outputs
    input  wire [31:0] pixel_ptr_in,
    input  wire [31:0] output_ptrA_in,
    input  wire [31:0] output_ptrB_in,
    input  wire [31:0] output_ptrC_in,
    input  wire [31:0] cycle_cnt_in,

    // Memory interface (connects to memory.v PD port)
    output wire [15:0] mem_addr,
    output wire [31:0] mem_wdata,
    output wire        mem_wr,      // PDW: 1=write, 0=read
    input  wire [31:0] mem_rdata,   // PDoutputvalue

    // Status
    output wire        done
);

    // =====================================================================
    // FSM control signals
    // =====================================================================
    wire        ld_init, ld_update;
    wire        ld_one, ld_two, ld_thr;
    wire [1:0]  rd_sel, st_data_sel, st_addr_sel;
    wire        ldst_sel;
    wire        cyc_zero;

    // =====================================================================
    // Pointer / counter register outputs
    // =====================================================================
    wire [31:0] pix_ptr_q, ptrA_q, ptrB_q, ptrC_q, cyc_ctr_q;

    // =====================================================================
    // Loop-update adder outputs 
    // =====================================================================
    wire [31:0] pix_ptr_next, ptrA_next, ptrB_next, ptrC_next, cyc_ctr_next;
    wire        co_pp, co_pA, co_pB, co_pC, co_cc;

    // =====================================================================
    // Pointer register enable: asserted on ld_init OR ld_update
    // =====================================================================
    wire ptr_reg_en;
    or(ptr_reg_en, ld_init, ld_update);

    // =====================================================================
    // FSM instantiation
    // =====================================================================
    pixel_decode_fsm u_fsm (
        .clock       (clock),
        .reset       (reset),
        .start       (start),
        .cyc_zero    (cyc_zero),
        .ld_init     (ld_init),
        .ld_update   (ld_update),
        .ld_one      (ld_one),
        .ld_two      (ld_two),
        .ld_thr      (ld_thr),
        .rd_sel      (rd_sel),
        .st_data_sel (st_data_sel),
        .st_addr_sel (st_addr_sel),
        .ldst_sel    (ldst_sel),
        .mem_wr      (mem_wr),
        .done        (done)
    );

    // =====================================================================
    // 1. PIX_PTR register  
    //    ld_init selects pixel_ptr_in; normal path selects pix_ptr_next.
    // =====================================================================
    wire [31:0] pix_ptr_mux;

    mux2_32bit u_pixptr_mux (
        .inputzero  (pix_ptr_next),
        .inputone   (pixel_ptr_in),
        .select     (ld_init),
        .finaloutput(pix_ptr_mux)
    );

    reg32_en u_pixptr_reg (
        .datainput  (pix_ptr_mux),
        .clock      (clock),
        .enable     (ptr_reg_en),
        .dataoutput (pix_ptr_q)
    );

    adder u_pixptr_adder (
        .A   (pix_ptr_q),
        .B   (32'd12),
        .Cin (1'b0),
        .S   (pix_ptr_next),
        .Cout(co_pp)
    );

    // =====================================================================
    // 2. PTRA register  (+4 per iteration, R-channel write pointer)
    // =====================================================================
    wire [31:0] ptrA_mux;

    mux2_32bit u_ptrA_mux (
        .inputzero  (ptrA_next),
        .inputone   (output_ptrA_in),
        .select     (ld_init),
        .finaloutput(ptrA_mux)
    );

    reg32_en u_ptrA_reg (
        .datainput  (ptrA_mux),
        .clock      (clock),
        .enable     (ptr_reg_en),
        .dataoutput (ptrA_q)
    );

    adder u_ptrA_adder (
        .A   (ptrA_q),
        .B   (32'd4),
        .Cin (1'b0),
        .S   (ptrA_next),
        .Cout(co_pA)
    );

    // =====================================================================
    // 3. PTRB register  (+4 per iteration, G-channel write pointer)
    // =====================================================================
    wire [31:0] ptrB_mux;

    mux2_32bit u_ptrB_mux (
        .inputzero  (ptrB_next),
        .inputone   (output_ptrB_in),
        .select     (ld_init),
        .finaloutput(ptrB_mux)
    );

    reg32_en u_ptrB_reg (
        .datainput  (ptrB_mux),
        .clock      (clock),
        .enable     (ptr_reg_en),
        .dataoutput (ptrB_q)
    );

    adder u_ptrB_adder (
        .A   (ptrB_q),
        .B   (32'd4),
        .Cin (1'b0),
        .S   (ptrB_next),
        .Cout(co_pB)
    );

    // =====================================================================
    // 4. PTRC register  (+4 per iteration, B-channel write pointer)
    // =====================================================================
    wire [31:0] ptrC_mux;

    mux2_32bit u_ptrC_mux (
        .inputzero  (ptrC_next),
        .inputone   (output_ptrC_in),
        .select     (ld_init),
        .finaloutput(ptrC_mux)
    );

    reg32_en u_ptrC_reg (
        .datainput  (ptrC_mux),
        .clock      (clock),
        .enable     (ptr_reg_en),
        .dataoutput (ptrC_q)
    );

    adder u_ptrC_adder (
        .A   (ptrC_q),
        .B   (32'd4),
        .Cin (1'b0),
        .S   (ptrC_next),
        .Cout(co_pC)
    );

    // =====================================================================
    // 5. CYC_CTR register  (-1 per iteration, loop termination counter)
    //    Subtract 1 by adding 0xFFFFFFFF (two's complement).
    // =====================================================================
    wire [31:0] cyc_ctr_mux;

    mux2_32bit u_cycctr_mux (
        .inputzero  (cyc_ctr_next),
        .inputone   (cycle_cnt_in),
        .select     (ld_init),
        .finaloutput(cyc_ctr_mux)
    );

    reg32_en u_cycctr_reg (
        .datainput  (cyc_ctr_mux),
        .clock      (clock),
        .enable     (ptr_reg_en),
        .dataoutput (cyc_ctr_q)
    );

    adder u_cycctr_adder (
        .A   (cyc_ctr_q),
        .B   (32'hFFFFFFFF),
        .Cin (1'b0),
        .S   (cyc_ctr_next),
        .Cout(co_cc)
    );

    // =====================================================================
    // 6. Zero comparator for cyc_ctr_next  (structural gate tree)
    //    cyc_zero = 1  if  cyc_ctr_next == 32'd0
    //
    //    Strategy: invert all 32 bits, then AND in groups.
    //      32x NOT -> 8x AND4 (groups of 4) -> 2x AND4 -> 1x AND2
    // =====================================================================
    wire [31:0] czn;   // inverted bits of cyc_ctr_next

    not(czn[0],  cyc_ctr_next[0]);   not(czn[1],  cyc_ctr_next[1]);
    not(czn[2],  cyc_ctr_next[2]);   not(czn[3],  cyc_ctr_next[3]);
    not(czn[4],  cyc_ctr_next[4]);   not(czn[5],  cyc_ctr_next[5]);
    not(czn[6],  cyc_ctr_next[6]);   not(czn[7],  cyc_ctr_next[7]);
    not(czn[8],  cyc_ctr_next[8]);   not(czn[9],  cyc_ctr_next[9]);
    not(czn[10], cyc_ctr_next[10]);  not(czn[11], cyc_ctr_next[11]);
    not(czn[12], cyc_ctr_next[12]);  not(czn[13], cyc_ctr_next[13]);
    not(czn[14], cyc_ctr_next[14]);  not(czn[15], cyc_ctr_next[15]);
    not(czn[16], cyc_ctr_next[16]);  not(czn[17], cyc_ctr_next[17]);
    not(czn[18], cyc_ctr_next[18]);  not(czn[19], cyc_ctr_next[19]);
    not(czn[20], cyc_ctr_next[20]);  not(czn[21], cyc_ctr_next[21]);
    not(czn[22], cyc_ctr_next[22]);  not(czn[23], cyc_ctr_next[23]);
    not(czn[24], cyc_ctr_next[24]);  not(czn[25], cyc_ctr_next[25]);
    not(czn[26], cyc_ctr_next[26]);  not(czn[27], cyc_ctr_next[27]);
    not(czn[28], cyc_ctr_next[28]);  not(czn[29], cyc_ctr_next[29]);
    not(czn[30], cyc_ctr_next[30]);  not(czn[31], cyc_ctr_next[31]);

    wire [7:0] czg;   // group AND results (8 groups of 4 bits each)
    and(czg[0], czn[0],  czn[1],  czn[2],  czn[3]);
    and(czg[1], czn[4],  czn[5],  czn[6],  czn[7]);
    and(czg[2], czn[8],  czn[9],  czn[10], czn[11]);
    and(czg[3], czn[12], czn[13], czn[14], czn[15]);
    and(czg[4], czn[16], czn[17], czn[18], czn[19]);
    and(czg[5], czn[20], czn[21], czn[22], czn[23]);
    and(czg[6], czn[24], czn[25], czn[26], czn[27]);
    and(czg[7], czn[28], czn[29], czn[30], czn[31]);

    wire czm0, czm1;
    and(czm0, czg[0], czg[1], czg[2], czg[3]);
    and(czm1, czg[4], czg[5], czg[6], czg[7]);
    and(cyc_zero, czm0, czm1);

    // =====================================================================
    // 7. Read address path
    //    rd_offset MUX: 00->0, 01->4, 10->8 (maps to S1/S2/S3)
    //    Read adder: pix_ptr_q + rd_offset
    // =====================================================================
    wire [31:0] rd_offset;
    wire [31:0] rd_addr;
    wire        co_rd;

    mux4_32bit u_rd_offset_mux (
        .inputzero  (32'd0),
        .inputone   (32'd4),
        .inputtwo   (32'd8),
        .inputthree (32'd0),     // rd_sel=11 never asserted
        .select     (rd_sel),
        .finaloutput(rd_offset)
    );

    adder u_rd_adder (
        .A   (pix_ptr_q),
        .B   (rd_offset),
        .Cin (1'b0),
        .S   (rd_addr),
        .Cout(co_rd)
    );

    // =====================================================================
    // 8. capture mem_rdata on each successful read
    // =====================================================================
    wire [31:0] one_q, two_q, thr_q;

    reg32_en u_one_reg (
        .datainput  (mem_rdata),
        .clock      (clock),
        .enable     (ld_one),
        .dataoutput (one_q)
    );

    reg32_en u_two_reg (
        .datainput  (mem_rdata),
        .clock      (clock),
        .enable     (ld_two),
        .dataoutput (two_q)
    );

    reg32_en u_thr_reg (
        .datainput  (mem_rdata),
        .clock      (clock),
        .enable     (ld_thr),
        .dataoutput (thr_q)
    );

    // =====================================================================
    // 9. Byte extraction -- pure wire routing, zero gates
    //
    //    Memory layout (little-endian, 4 pixels = 12 bytes):
    //      one: B0 G0 R0 B1  (bytes at pix_ptr+0..3)
    //      two: G1 R1 B2 G2  (bytes at pix_ptr+4..7)
    //      thr: R2 B3 G3 R3  (bytes at pix_ptr+8..11)
    //
    //    R_word packs R0..R3, G_word packs G0..G3, B_word packs B0..B3.
    //    Each packed word: pixel 0 in [7:0], pixel 1 in [15:8],
    //                      pixel 2 in [23:16], pixel 3 in [31:24].
    // =====================================================================
    wire [31:0] R_word, G_word, B_word;

    assign R_word = { thr_q[31:24], thr_q[7:0],   two_q[15:8],  one_q[23:16] };
    assign G_word = { thr_q[23:16], two_q[31:24], two_q[7:0],   one_q[15:8]  };
    assign B_word = { thr_q[15:8],  two_q[23:16], one_q[31:24], one_q[7:0]   };

    // =====================================================================
    // 10. Store data MUX  -- selects R_word / G_word / B_word
    //     st_data_sel:  00=R (S5),  01=G (S6),  10=B (S7)
    // =====================================================================
    mux4_32bit u_st_data_mux (
        .inputzero  (R_word),
        .inputone   (G_word),
        .inputtwo   (B_word),
        .inputthree (32'd0),     // st_data_sel=11 never asserted
        .select     (st_data_sel),
        .finaloutput(mem_wdata)
    );

    // =====================================================================
    // 11. Store address MUX  -- selects ptrA_q / ptrB_q / ptrC_q
    //     st_addr_sel:  00=ptrA (S5),  01=ptrB (S6),  10=ptrC (S7)
    // =====================================================================
    wire [31:0] wr_addr;

    mux4_32bit u_st_addr_mux (
        .inputzero  (ptrA_q),
        .inputone   (ptrB_q),
        .inputtwo   (ptrC_q),
        .inputthree (32'd0),     // st_addr_sel=11 never asserted
        .select     (st_addr_sel),
        .finaloutput(wr_addr)
    );

    // =====================================================================
    // 12. LD/ST address MUX  -- final memory address sent to cache
    //     ldst_sel = mem_wr:  0=rd_addr (S1-S3),  1=wr_addr (S5-S7)
    // =====================================================================
    wire [31:0] mem_addr_full;

    mux2_32bit u_ldst_mux (
        .inputzero  (rd_addr),
        .inputone   (wr_addr),
        .select     (ldst_sel),
        .finaloutput(mem_addr_full)
    );

    assign mem_addr = mem_addr_full[15:0];

endmodule