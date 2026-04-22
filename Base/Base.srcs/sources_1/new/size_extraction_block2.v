`timescale 1ns / 1ps

// =============================================================================
// size_extraction_block2.v
// =============================================================================
// Branching FSM version of size_extraction_block.
//
// FSM states (lower 3 bits of 32-bit counter):
//   S0 (000) idle
//   S1 (001) read chn_amnt   addr = img_ptr + 0
//   S2 (010) read cols       addr = img_ptr + 4
//   S3 (011) read height     addr = img_ptr + 8
//   S4 (100) CONV done       latch lat_shifts, vert_shifts, pixel_ptr; kern_ready=1 -> S0
//   S5 (101) FC   done       latch size, pixel_ptr -> S0
//
// After S3, branch on is_fc:
//   is_fc=0  -> S4  (state_inc = 3+1 = 4, normal path)
//   is_fc=1  -> S5  (mux overrides state_inc to 5)
//
// kern_ready is combinational s4 — one clock cycle wide.
// Connect kern_ready -> kern_size_extraction_block.ready.
// done is registered (s4 | s5), fires one cycle after the terminal state.
// =============================================================================


// =============================================================================
// size_extraction_fsm2
// =============================================================================
module size_extraction_fsm2 (
    input  wire        clock,
    input  wire        reset,
    input  wire        start,
    input  wire        is_fc,       // 0=CONV, 1=FC; used for S3 branch

    // Data register load enables
    output wire        ld_chn,
    output wire        ld_cols,
    output wire        ld_ht,

    // Read address offset select: {s3,s2} -> 00=0, 01=4, 10=8
    output wire [1:0]  a_sel,

    // Terminal-state latch pulses
    output wire        ld_conv,     // S4: latch CONV outputs (lat/vert/pixptr)
    output wire        ld_fc,       // S5: latch FC  outputs (size/pixptr)

    // kern_size_extraction start pulse (connect to .ready)
    output wire        kern_ready,

    // done: registered one cycle after S4 or S5
    output wire        done
);

    // -----------------------------------------------------------------
    // State counter
    // -----------------------------------------------------------------
    wire [31:0] state_q;
    wire [31:0] state_inc;
    wire        state_advance;
    wire        cout_state;

    adder u_state_inc (
        .A   (state_q),
        .B   (32'd1),
        .Cin (1'b0),
        .S   (state_inc),
        .Cout(cout_state)
    );

    // Forward-declared wires used in next-state MUXes before gate decoding
    wire s4, s5;

    // MUX 1: S3 FC branch — when in S3 with is_fc=1, go to S5 instead of S4
    wire        s3_fc_w;        // s3 & is_fc
    wire [31:0] branch_out;

    mux2_32bit u_s3_branch_mux (
        .inputzero  (state_inc),   // is_fc=0: state+1 = S4
        .inputone   (32'd5),       // is_fc=1: jump to S5
        .select     (s3_fc_w),
        .finaloutput(branch_out)
    );

    // MUX 2: terminal states S4/S5 — wrap back to S0
    wire        terminal_w;     // s4 | s5
    wire [31:0] next_state;

    mux2_32bit u_terminal_mux (
        .inputzero  (branch_out),
        .inputone   (32'd0),
        .select     (terminal_w),
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
    // State decode: lower 3 bits, states 0-5
    // -----------------------------------------------------------------
    wire ns2, ns1, ns0;
    not(ns2, state_q[2]);
    not(ns1, state_q[1]);
    not(ns0, state_q[0]);

    wire s0, s1, s2, s3;
    and(s0, ns2,        ns1,        ns0        );  // 000  idle
    and(s1, ns2,        ns1,        state_q[0] );  // 001  read chn_amnt
    and(s2, ns2,        state_q[1], ns0        );  // 010  read cols
    and(s3, ns2,        state_q[1], state_q[0] );  // 011  read height
    and(s4, state_q[2], ns1,        ns0        );  // 100  CONV done
    and(s5, state_q[2], ns1,        state_q[0] );  // 101  FC   done

    // Branch and terminal signals (now fully driven)
    and(s3_fc_w,  s3, is_fc);
    or (terminal_w, s4, s5);

    // -----------------------------------------------------------------
    // req_active register
    // -----------------------------------------------------------------
    wire mem_state_w;
    wire not_advance_w;
    wire req_active_next_w;
    wire req_active_q;

    or (mem_state_w,       s1, s2, s3);
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
    // state_advance
    //   S0:       on start
    //   S1-S3:    req_active (mem_ready always 1)
    //   S4, S5:   always (1-cycle terminal states)
    // -----------------------------------------------------------------
    wire adv_idle_w, rdy_w, adv_mem_w;

    and(adv_idle_w, s0,          start);
    assign rdy_w = req_active_q;
    and(adv_mem_w,  mem_state_w, rdy_w);
    or (state_advance, adv_idle_w, adv_mem_w, terminal_w);

    // -----------------------------------------------------------------
    // Outputs
    // -----------------------------------------------------------------
    assign a_sel = {s3, s2};

    and(ld_chn,  s1, rdy_w);
    and(ld_cols, s2, rdy_w);
    and(ld_ht,   s3, rdy_w);

    assign ld_conv    = s4;
    assign ld_fc      = s5;
    assign kern_ready = s4;   // combinational 1-cycle pulse

    // done only fires on the FC path (S5).
    // For CONV, kern_ready starts kern_size_extraction and its done is used instead.
    dff_en_reset u_done_dff (
        .datainput  (s5),
        .clock      (clock),
        .enable     (1'b1),
        .reset      (reset),
        .resetvalue (1'b0),
        .dataoutput (done)
    );

endmodule


// =============================================================================
// size_extraction_block2
// =============================================================================
module size_extraction_block2 (
    input  wire        clock,
    input  wire        reset,
    input  wire        start,

    input  wire [31:0] img_ptr,
    input  wire        is_fc,      // 0 = CONV path, 1 = FC path

    // Memory interface (read-only, connects to memory.v SE port)
    output wire [15:0] mem_addr,
    input  wire [31:0] mem_rdata,  // SEoutputvalue

    // Outputs (stable when done = 1)
    output wire [31:0] pixel_ptr_output,
    output wire [31:0] chn_amnt_output,
    output wire [31:0] cols_output,
    output wire [31:0] lat_shifts_output,   // CONV: cols - 3
    output wire [31:0] vert_shifts_output,  // CONV: height - 3
    output wire [31:0] size_output,         // FC:   chn_amnt * cols * height
    output wire        kern_ready,          // CONV: start pulse for kern_size_extraction_block
    output wire        done
);

    // =====================================================================
    // FSM
    // =====================================================================
    wire        ld_chn, ld_cols, ld_ht;
    wire        ld_conv, ld_fc;
    wire [1:0]  a_sel;

    size_extraction_fsm2 u_fsm (
        .clock     (clock),
        .reset     (reset),
        .start     (start),
        .is_fc     (is_fc),
        .ld_chn    (ld_chn),
        .ld_cols   (ld_cols),
        .ld_ht     (ld_ht),
        .a_sel     (a_sel),
        .ld_conv   (ld_conv),
        .ld_fc     (ld_fc),
        .kern_ready(kern_ready),
        .done      (done)
    );

    // =====================================================================
    // 1. Read address: img_ptr + offset
    //    a_sel: 00->0 (S1), 01->4 (S2), 10->8 (S3)
    // =====================================================================
    wire [31:0] rd_offset;
    wire [31:0] mem_addr_full;
    wire        cout_rd;

    mux4_32bit u_mux_a (
        .inputzero  (32'd0),
        .inputone   (32'd4),
        .inputtwo   (32'd8),
        .inputthree (32'd0),
        .select     (a_sel),
        .finaloutput(rd_offset)
    );

    adder u_rd_adder (
        .A   (img_ptr),
        .B   (rd_offset),
        .Cin (1'b0),
        .S   (mem_addr_full),
        .Cout(cout_rd)
    );

    assign mem_addr = mem_addr_full[15:0];

    // =====================================================================
    // 2. Data registers: chn_amnt, cols, height
    // =====================================================================
    wire [31:0] chn_amnt_q, cols_q, height_q;

    reg32_en u_chn_reg (
        .datainput  (mem_rdata),
        .clock      (clock),
        .enable     (ld_chn),
        .dataoutput (chn_amnt_q)
    );

    reg32_en u_cols_reg (
        .datainput  (mem_rdata),
        .clock      (clock),
        .enable     (ld_cols),
        .dataoutput (cols_q)
    );

    reg32_en u_height_reg (
        .datainput  (mem_rdata),
        .clock      (clock),
        .enable     (ld_ht),
        .dataoutput (height_q)
    );

    assign chn_amnt_output = chn_amnt_q;
    assign cols_output     = cols_q;

    // =====================================================================
    // 3. FC path: chained combinational multipliers (chn * cols * height)
    // =====================================================================
    wire [31:0] partial_wire, size_wire;
    wire [31:0] m1_h, m1_hsu, m1_hu;
    wire [31:0] m2_h, m2_hsu, m2_hu;

    multiplier u_mult1 (
        .A           (chn_amnt_q),
        .B           (cols_q),
        .MULoutput   (partial_wire),
        .MULHoutput  (m1_h),
        .MULHSUoutput(m1_hsu),
        .MULHUoutput (m1_hu)
    );

    multiplier u_mult2 (
        .A           (partial_wire),
        .B           (height_q),
        .MULoutput   (size_wire),
        .MULHoutput  (m2_h),
        .MULHSUoutput(m2_hsu),
        .MULHUoutput (m2_hu)
    );

    wire [31:0] size_q;

    reg32_en u_size_reg (
        .datainput  (size_wire),
        .clock      (clock),
        .enable     (ld_fc),
        .dataoutput (size_q)
    );

    assign size_output = chn_amnt_q*height_q*cols_q;

    // =====================================================================
    // 4. CONV path: combinational subtractors (cols-3, height-3)
    //    Subtract 3: add 0xFFFFFFFD (two's complement)
    // =====================================================================
    wire [31:0] lat_wire, vert_wire;
    wire        cout_lat, cout_vert;

    adder u_lat_sub (
        .A   (cols_q),
        .B   (32'hFFFFFFFD),
        .Cin (1'b0),
        .S   (lat_wire),
        .Cout(cout_lat)
    );

    adder u_vert_sub (
        .A   (height_q),
        .B   (32'hFFFFFFFD),
        .Cin (1'b0),
        .S   (vert_wire),
        .Cout(cout_vert)
    );

    wire [31:0] lat_q, vert_q;

    reg32_en u_lat_reg (
        .datainput  (lat_wire),
        .clock      (clock),
        .enable     (ld_conv),
        .dataoutput (lat_q)
    );

    reg32_en u_vert_reg (
        .datainput  (vert_wire),
        .clock      (clock),
        .enable     (ld_conv),
        .dataoutput (vert_q)
    );

    assign lat_shifts_output  = lat_q;
    assign vert_shifts_output = vert_q;

    // =====================================================================
    // 5. Pixel pointer: img_ptr + 12 (latched in both S4 and S5)
    // =====================================================================
    wire [31:0] pixptr_wire, pixptr_q;
    wire        cout_px, ld_pixptr;

    adder u_pixptr_adder (
        .A   (img_ptr),
        .B   (32'd12),
        .Cin (1'b0),
        .S   (pixptr_wire),
        .Cout(cout_px)
    );

    or(ld_pixptr, ld_conv, ld_fc);

    reg32_en u_pixptr_reg (
        .datainput  (pixptr_wire),
        .clock      (clock),
        .enable     (ld_pixptr),
        .dataoutput (pixptr_q)
    );

    assign pixel_ptr_output = pixptr_q;

endmodule