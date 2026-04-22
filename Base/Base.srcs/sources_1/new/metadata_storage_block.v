`timescale 1ns / 1ps

// =============================================================================
// metadata_storage_block.v
// =============================================================================
// Reads width and height from a BMP file header, writes metadata (width,
// height, channel count) into the destination buffer, and computes the
// channel-base output pointers that convolution blocks need.
//
// Destination buffer layout (out_ptr):
//   +0  : width   (32-bit)
//   +4  : height  (32-bit)
//   +8  : channels = 3  (32-bit)
//   +12 : R-channel pixel data  (output_ptrA)
//   +12 + W*H   : G-channel pixel data  (output_ptrB)
//   +12 + 2*W*H : B-channel pixel data  (output_ptrC)
//
// BMP header offsets used:
//   img_ptr + 18 : image width 
//   img_ptr + 22 : image height
//   img_ptr + 54 : first pixel byte 
//
// FSM state encoding (lower 3 bits of the 32-bit state counter):
//   S0 = 3'd0  idle            -- wait for start
//   S1 = 3'd1  read width      -- mem_rd, addr = img_ptr + 18
//   S2 = 3'd2  read height     -- mem_rd, addr = img_ptr + 22
//   S3 = 3'd3  store width     -- mem_wr, addr = out_ptr +  0, data = width
//   S4 = 3'd4  store height    -- mem_wr, addr = out_ptr +  4, data = height
//   S5 = 3'd5  store channels  -- mem_wr, addr = out_ptr +  8, data = 3
//   S6 = 3'd6  done            -- latch output pointers, raise done
// =============================================================================

module metadata_storage_block (
    input  wire        clock,
    input  wire        reset,
    input  wire        start,

    // Pointers from the register file
    input  wire [31:0] img_ptr,   // base address of source BMP image
    input  wire [31:0] out_ptr,   // base address of destination metadata buffer

    // Memory interface (connects to memory.v MS port)
    output wire [15:0] mem_addr,
    output wire [31:0] mem_wdata,
    output wire        mem_wr,      // MSW: 0=read, 1=write
    input  wire [31:0] mem_rdata,   // MSoutputvalue

    // Outputs stable from the cycle after done first goes high
    output wire [31:0] pixel_ptr,    // img_ptr + 54
    output wire [31:0] output_ptrA,  // out_ptr + 12
    output wire [31:0] output_ptrB,  // out_ptr + 12 + W*H
    output wire [31:0] output_ptrC,  // out_ptr + 12 + 2*W*H
    output wire [31:0] cycle_cnt,    // W*H / 4
    output wire        done          
);

    // =========================================================================
    // 1.  State counter
    //     reg32_en_reset holds the current state; adder provides state+1.
    //     The counter advances when state_advance is asserted and resets to 0.
    // =========================================================================
    wire [31:0] state_q;
    wire [31:0] state_inc;
    wire [31:0] next_state;
    wire        state_advance;
    wire        cout_state;     // unused
    wire        s6;             // forward declaration: used in next-state mux below

    adder u_state_adder (
        .A   (state_q),
        .B   (32'd1),
        .Cin (1'b0),
        .S   (state_inc),
        .Cout(cout_state)
    );

    // S6 is a 1-cycle auto-advance state: wrap back to S0
    mux2_32bit u_next_mux (
        .inputzero  (state_inc),
        .inputone   (32'd0),
        .select     (s6),
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

    // =========================================================================
    // 2. 3-to-8 decoder on state_q[2:0]
    // =========================================================================
    wire ns2, ns1, ns0;
    not(ns2, state_q[2]);
    not(ns1, state_q[1]);
    not(ns0, state_q[0]);

    wire s0, s1, s2, s3, s4, s5;   // s6 forward-declared above
    and(s0, ns2,         ns1,         ns0        );  // 000  idle
    and(s1, ns2,         ns1,         state_q[0] );  // 001  read width
    and(s2, ns2,         state_q[1],  ns0        );  // 010  read height
    and(s3, ns2,         state_q[1],  state_q[0] );  // 011  store width
    and(s4, state_q[2],  ns1,         ns0        );  // 100  store height
    and(s5, state_q[2],  ns1,         state_q[0] );  // 101  store channels
    and(s6, state_q[2],  state_q[1],  ns0        );  // 110  done

    // =========================================================================
    // 3.  req_active register
    //     Goes high ONE cycle after the FSM enters a memory-access state (S1-S5)
    //     so that a mem_ready that was already asserted from the previous state
    //     does not cause a false early advance.
    //
    //     req_active_next = mem_state & ~state_advance
    //     Cleared (0) when state_advance fires (we are leaving the current state)
    //     Set  (1) on the next cycle after arrival (state_advance was 0)
    // =========================================================================
    wire mem_state_w;       // true in any of S1-S5
    wire not_advance_w;
    wire req_active_next_w;
    wire req_active_q;

    or (mem_state_w,       s1, s2, s3, s4, s5);
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

    // =========================================================================
    // 4.  state_advance  -- when does the FSM move to the next state?
    //       S0      : advance on start
    //       S1-S5   : advance when req_active=1 AND mem_ready=1
    //       S6      : auto-advance (1-cycle), returns to S0
    // =========================================================================
    wire adv_idle_w;    // S0 advance condition
    wire rdy_w;         // req_active (mem_ready always 1)
    wire adv_mem_w;     // S1-S5 advance condition

    and(adv_idle_w,  s0,          start);
    assign rdy_w = req_active_q;
    and(adv_mem_w,   mem_state_w, rdy_w);
    or (state_advance, adv_idle_w, adv_mem_w, s6);

    // =========================================================================
    // 5.  Memory control outputs
    //       mem_rd : asserted in S1 and S2
    //       mem_wr : asserted in S3, S4, S5
    // =========================================================================
    wire mem_wr_w;

    or(mem_wr_w, s3, s4, s5);

    assign mem_wr = mem_wr_w;

    // =========================================================================
    // 6.  Register load enables
    //       ld_width  : fires when S1 read handshake completes
    //       ld_height : fires when S2 read handshake completes
    //       ld_out    : asserted continuously in S6 
    // =========================================================================
    wire ld_width_w, ld_height_w, ld_out_w;

    and(ld_width_w,  s1, rdy_w);
    and(ld_height_w, s2, rdy_w);
    assign ld_out_w = s6;

    // =========================================================================
    // 7.  done output
    //     Registered one cycle after entering S6 so that when done goes high
    //     the output registers already hold their final stable values.
    // =========================================================================
    dff_en_reset u_done_dff (
        .datainput  (s6),
        .clock      (clock),
        .enable     (1'b1),
        .reset      (reset),
        .resetvalue (1'b0),
        .dataoutput (done)
    );

    // =========================================================================
    // 8.  MUX A  --  read-address offset
    //     a_sel = s2 :  0 -> 32'd18 (width field at BMP +18)
    //                   1 -> 32'd22 (height field at BMP +22)
    // =========================================================================
    wire [31:0] mux_a_out;
    wire [31:0] load_addr;
    wire        cout_ld;

    mux2_32bit u_mux_a (
        .inputzero  (32'd18),
        .inputone   (32'd22),
        .select     (s2),
        .finaloutput(mux_a_out)
    );

    adder u_load_adder (
        .A   (img_ptr),
        .B   (mux_a_out),
        .Cin (1'b0),
        .S   (load_addr),
        .Cout(cout_ld)
    );

    // =========================================================================
    // 9.  MUX B  --  write-address offset
    //     b_sel = {s5, s4} :  2'b00 -> 32'd0   (store width   at out_ptr+0)
    //                         2'b01 -> 32'd4   (store height  at out_ptr+4)
    //                         2'b10 -> 32'd8   (store chnl    at out_ptr+8)
    // =========================================================================
    wire [1:0]  b_sel_w;
    wire [31:0] mux_b_out;
    wire [31:0] store_addr;
    wire        cout_st;

    assign b_sel_w = {s5, s4};

    mux4_32bit u_mux_b (
        .inputzero  (32'd8),
        .inputone   (32'd4),
        .inputtwo   (32'd0),
        .inputthree (32'd0),     // b_sel=11 never asserted
        .select     (b_sel_w),
        .finaloutput(mux_b_out)
    );

    adder u_store_adder (
        .A   (out_ptr),
        .B   (mux_b_out),
        .Cin (1'b0),
        .S   (store_addr),
        .Cout(cout_st)
    );

    // =========================================================================
    // 10. Memory address MUX
    //     select = mem_wr_w : 0 -> load_addr (S1/S2)
    //                         1 -> store_addr (S3/S4/S5)
    // =========================================================================
    wire [31:0] mem_addr_full;

    mux2_32bit u_ldst_mux (
        .inputzero  (load_addr),
        .inputone   (store_addr),
        .select     (mem_wr_w),
        .finaloutput(mem_addr_full)
    );

    assign mem_addr = mem_addr_full[15:0];

    // =========================================================================
    // 11. Width and height registers
    //     Each loads mem_rdata when its state's read handshake completes.
    // =========================================================================
    wire [31:0] width_q, height_q;

    reg32_en u_width_reg (
        .datainput  (mem_rdata),
        .clock      (clock),
        .enable     (ld_width_w),
        .dataoutput (width_q)
    );

    reg32_en u_height_reg (
        .datainput  (mem_rdata),
        .clock      (clock),
        .enable     (ld_height_w),
        .dataoutput (height_q)
    );

    // =========================================================================
    // 12. Store-data MUX
    //     st_sel = {s5, s4} :  2'b00 -> width_q
    //                          2'b01 -> height_q
    //                          2'b10 -> 32'd3  
    // =========================================================================
    wire [1:0] st_sel_w;
    assign st_sel_w = {s5, s4};

    mux4_32bit u_st_mux (
        .inputzero  (width_q),
        .inputone   (height_q),
        .inputtwo   (32'd3),
        .inputthree (32'd0),     // st_sel=11 never asserted
        .select     (st_sel_w),
        .finaloutput(mem_wdata)
    );

    // =========================================================================
    // 13. Multiplier:  pixel_cnt = width * height
    //
    //     Width_q and height_q are stable from states S3 onward, so the
    //     product and all derived wires are valid well before S6.
    //
    //     chn_bytes_wire = pixel_cnt << 2   (bytes per channel: 4 B/pixel)
    //     cycle_cnt_wire = pixel_cnt >> 2   (4 pixels processed per cycle)
    // =========================================================================
    wire [31:0] pixel_cnt_w;
    wire [31:0] mul_unused_h, mul_unused_hsu, mul_unused_hu;
    wire [31:0] chn_bytes_wire;
    wire [31:0] cycle_cnt_wire;

    multiplier u_mult (
        .A           (width_q),
        .B           (height_q),
        .MULoutput   (pixel_cnt_w),
        .MULHoutput  (mul_unused_h),
        .MULHSUoutput(mul_unused_hsu),
        .MULHUoutput (mul_unused_hu)
    );

    // Bit-shifts are zero-gate routing only
  
    assign chn_bytes_wire = width_q*height_q;                  // 1 byte per pixel per channel
    assign cycle_cnt_wire = {2'b00, chn_bytes_wire[31:2]};  // >> 2: pixel_decode does 4 pixels/iter

    // =========================================================================
    // 14. Output pointer combinational adder chain
    //     All adders run continuously; their results are registered at S6.
    //     ptrB and ptrC use chn_bytes_wire (combinational from multiplier)
    //     so that the correct values are ready to latch in the first S6 cycle.
    // =========================================================================
    wire [31:0] ptrA_sum, ptrB_sum, ptrC_sum, pixptr_sum;
    wire        cout_pA, cout_pB, cout_pC, cout_px;

    adder u_ptrA_adder (
        .A   (out_ptr),
        .B   (32'd12),
        .Cin (1'b0),
        .S   (ptrA_sum),
        .Cout(cout_pA)
    );

    adder u_ptrB_adder (
        .A   (ptrA_sum),
        .B   (chn_bytes_wire),
        .Cin (1'b0),
        .S   (ptrB_sum),
        .Cout(cout_pB)
    );

    adder u_ptrC_adder (
        .A   (ptrB_sum),
        .B   (chn_bytes_wire),
        .Cin (1'b0),
        .S   (ptrC_sum),
        .Cout(cout_pC)
    );

    adder u_pixptr_adder (
        .A   (img_ptr),
        .B   (32'd54),
        .Cin (1'b0),
        .S   (pixptr_sum),
        .Cout(cout_px)
    );

    // =========================================================================
    // 15. Output registers
    //     All latched on the first rising edge in S6 (ld_out_w = s6 = 1).
    //     They remain loaded each cycle in S6.  done goes high one cycle later (registered s6), so the
    //     processor sees done=1 only when these registers already hold final
    //     values.
    // =========================================================================
    reg32_en u_ptrA_reg (
        .datainput  (ptrA_sum),
        .clock      (clock),
        .enable     (ld_out_w),
        .dataoutput (output_ptrA)
    );

    reg32_en u_ptrB_reg (
        .datainput  (ptrB_sum),
        .clock      (clock),
        .enable     (ld_out_w),
        .dataoutput (output_ptrB)
    );

    reg32_en u_ptrC_reg (
        .datainput  (ptrC_sum),
        .clock      (clock),
        .enable     (ld_out_w),
        .dataoutput (output_ptrC)
    );

    reg32_en u_pixptr_reg (
        .datainput  (pixptr_sum),
        .clock      (clock),
        .enable     (ld_out_w),
        .dataoutput (pixel_ptr)
    );

    reg32_en u_cyccnt_reg (
        .datainput  (cycle_cnt_wire),
        .clock      (clock),
        .enable     (ld_out_w),
        .dataoutput (cycle_cnt)
    );

endmodule