`timescale 1ns / 1ps

// =============================================================================
// kern_size_extraction_block.v 
// =============================================================================
// Reads the first metadata word from kernel_ptr ,
// then outputs kern_ptr = kernel_ptr + 4 pointing past that word.
//
// Kernel tensor layout at kernel_ptr:
//   [+0]  kern_size  (uint32)   <-- read here
//   [+4]  weight data           <-- kern_ptr output points here
//
// FSM states (lower 2 bits of 32-bit counter):
//   S0 (00) idle   -- wait for ready
//   S1 (01) read   -- mem_rd at kernel_ptr; wait for mem_ready; latch kern_size
//   S2 (10) done   -- latch kern_ptr = kernel_ptr + 4; assert done; return to S0
//
// S2 is a 1-cycle auto-advance state (same pattern as S4 in size_extraction).
// It returns to S0 via the next-state MUX.
//
// =============================================================================

module kern_size_extraction_block (
    input  wire        clock,
    input  wire        reset,
    input  wire        ready,          // start pulse

    input  wire [31:0] kernel_ptr,     // base address of kernel tensor

    // Memory interface (read-only, connects to memory.v KSE port)
    output wire [15:0] mem_addr,
    input  wire [31:0] mem_rdata,   // KSEoutputvalue

    // Outputs 
    output wire [31:0] kern_size,      // value read from kernel_ptr + 0
    output wire [31:0] kern_ptr_out,   // kernel_ptr + 4
    output wire        done
);

    // =========================================================================
    // 1. State counter with next-state MUX
    //    Normal: state + 1
    //    S2 override: return to S0 
    // =========================================================================
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

    wire s2;

    mux2_32bit u_next_mux (
        .inputzero  (state_inc),   // S0, S1: normal increment
        .inputone   (32'd0),       // S2: return to S0
        .select     (s2),
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
    // 2. 2-to-3 on state_q[1:0]
    // =========================================================================
    wire ns1, ns0;
    not(ns1, state_q[1]);
    not(ns0, state_q[0]);

    wire s0, s1;
    and(s0, ns1,        ns0        );  // 00  idle
    and(s1, ns1,        state_q[0] );  // 01  read
    and(s2, state_q[1], ns0        );  // 10  done

    // =========================================================================
    // 3. req_active register
    // =========================================================================
    wire not_advance_w;
    wire req_active_next_w;
    wire req_active_q;

    not(not_advance_w,     state_advance);
    and(req_active_next_w, s1, not_advance_w);

    dff_en_reset u_req_active (
        .datainput  (req_active_next_w),
        .clock      (clock),
        .enable     (1'b1),
        .reset      (reset),
        .resetvalue (1'b0),
        .dataoutput (req_active_q)
    );

    // =========================================================================
    // 4. state_advance
    //    S0: advance on ready
    //    S1: advance when req_active & mem_ready
    //    S2: advance unconditionally 
    // =========================================================================
    wire adv_idle_w, rdy_w, adv_rd_w;

    and(adv_idle_w, s0, ready);
    assign rdy_w = req_active_q;   // mem_ready always 1 (MEM_STALL=0)
    and(adv_rd_w,   s1, rdy_w);
    or (state_advance, adv_idle_w, adv_rd_w, s2);

    // =========================================================================
    // 5. Memory control
    // =========================================================================
    assign mem_addr = kernel_ptr[15:0];

    // =========================================================================
    // 6. kern_size register
    //    Latches mem_rdata
    // =========================================================================
    wire ld_ks;
    and(ld_ks, s1, rdy_w);

    reg32_en u_kern_size_reg (
        .datainput  (mem_rdata),
        .clock      (clock),
        .enable     (ld_ks),
        .dataoutput (kern_size)
    );

    // =========================================================================
    // 7. kern_ptr adder and output register
    //    kern_ptr_out = kernel_ptr + 4  
    // =========================================================================
    wire [31:0] kern_ptr_sum;
    wire        co_kp;

    adder u_kern_ptr_adder (
        .A   (kernel_ptr),
        .B   (32'd4),
        .Cin (1'b0),
        .S   (kern_ptr_sum),
        .Cout(co_kp)
    );

    reg32_en u_kern_ptr_reg (
        .datainput  (kern_ptr_sum),
        .clock      (clock),
        .enable     (s2),
        .dataoutput (kern_ptr_out)
    );

    // =========================================================================
    // 8. done output
    //    Registered one cycle after S2 fires, aligning with stable outputs.
    // =========================================================================
    dff_en_reset u_done_dff (
        .datainput  (s2),
        .clock      (clock),
        .enable     (1'b1),
        .reset      (reset),
        .resetvalue (1'b0),
        .dataoutput (done)
    );

endmodule