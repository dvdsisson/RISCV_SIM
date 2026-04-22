module FSMController (
    input isFC, isConv, clk, start,
    input [31:0] max_x, max_y, size, cols, pxl_ptr, ker_ptr, bias_ptr, weight_ptr, out_ptr, max_ch, 
    output reg reset, 
    output fc_write, 
    output reg r3write, conv_compute,
    output reg [31:0] mem_ptr,
    output reg [1:0] banksel, colsel, regsel,
    output reg done, mem_wr,
    output reg write_byte, convreset
);

    reg [4:0] state;
    wire [31:0] max;

    assign max = max_x * max_y;

    reg [31:0] x, y;
    
    //assign x = x_reg;

    reg [3:0] ch;

    reg [1:0] index;

    reg [31:0] good_data;

    reg write_allowed;

    assign fc_write = write_allowed;


    initial begin
        state = 0;
    end


    always @(posedge clk) begin
        
        case (state)
            0: begin
                done <= 5'b0;
                if (start) begin
                    regsel <= 0;
                    colsel <= 0;
                    reset <= 0;
                    r3write <=0;
                    banksel <= 0;
                    convreset <= 0;
                    if (isFC) begin
                        
                        state <= 5'b01100;
                        write_byte <= 0;
                        // vert <= max_x;
                        // hor <= 1;
                        x <= 0;
                        y <= 0;
                    end else if (isConv) begin
                        x <= 0;
                        y <= 0;
                        conv_compute <= 0;
                        write_byte <= 1;
                        state <= 5'b11111;
                        mem_wr <= 0;
                        ch <= 0;
                        
                    end else begin
                        // bias add
                        state <= 5'b00100;
                        write_byte <= 0;
                        // vert <= 1;
                        x <= 0;
                        y <= 0;
                        // hor <= 4;

                        // mem_ptr <= pxl_ptr + x + regsel;
                        // mem_wr <= 0;
                        // write_allowed <= 1;
                    end
                end else reset <= 1;
            end

            // Bias Addition
            5'b00100: begin
                mem_ptr <= pxl_ptr + x + regsel;
                mem_wr <= 0;
                write_allowed <= 1;

                // mem_ptr <= bias_ptr + x + regsel;
                // regsel <= regsel+1;

                //regsel <= regsel+1;
                // if (regsel == 3 || (regsel+x+1) >= size>>2) begin //increment y
                state = 5'b00101;
                //regsel <= 0; // May have issues with regsel overflow
                //if (x >= size) state = 5'b01100; // incrememnt y
                // end //else fc_write <= 0;
            end
            5'b00101: begin
                mem_ptr <= weight_ptr + x + regsel;
                //regsel <= regsel+1;
                banksel <= 1; 
                //r3write <= 1;

                
                // mem_ptr <= out_ptr + x + regsel;
                // write_allowed <= 0;
                // mem_wr <= 1;


                
                //if (regsel == 3 || (regsel+x+1) >= size>>2) begin //increment y
                state = 5'b00110;
                //regsel <= 0; // May have issues with regsel overflow
                //end
            end
            5'b00110: begin
                mem_ptr <= out_ptr + x + regsel;
                write_allowed <= 0;
                mem_wr <= 1;
                //r3write <= 0;
                //regsel <= regsel+1;
                if (x+1 == size>>2) begin
                    done <= 1;
                    state <= 5'b00000;
                end else begin
                    x <= x+1;
                    state <= 5'b00100;
                end
            end




            // FC
            5'b01100: begin
                mem_ptr <= pxl_ptr + x + regsel;
                banksel <= 0;
                mem_wr <= 0;
                write_allowed <= 1;
                r3write <= 1;

                // mem_ptr <= bias_ptr + x + regsel;
                // regsel <= regsel+1;

                //regsel <= regsel+1;
                // if (regsel == 3 || (regsel+x+1) >= size>>2) begin //increment y
                state = 5'b01101;
                //regsel <= 0; // May have issues with regsel overflow
                //if (x >= size) state = 5'b01100; // incrememnt y
                // end //else fc_write <= 0;
            end
            5'b01101: begin
                mem_ptr <= bias_ptr + x + regsel;
                //regsel <= regsel+1;
                banksel <= 1; 
                r3write <= 0;                

                
                // mem_ptr <= out_ptr + x + regsel;
                // write_allowed <= 0;
                // mem_wr <= 1;


                
                //if (regsel == 3 || (regsel+x+1) >= size>>2) begin //increment y
                // state = 5'b01110;
                if (x+1 == size>>2) begin
                    state <= 5'b01110;
                end else begin
                    x <= x+1;
                    state <= 5'b01100;
                end
                //regsel <= 0; // May have issues with regsel overflow
                //end
            end
            5'b01110: begin
                mem_ptr <= out_ptr + x + regsel;
                r3write <= 0;
                write_allowed <= 0;
                mem_wr <= 1;
                //regsel <= regsel+1;
                done <= 1;
                state <= 5'b0;
            end











            // // MV Mult
            // 5'b01100: begin
            //     mem_ptr <= pxl_ptr + x;
            //     mem_wr <= 0;
            //     write_allowed <= 1;
            //     r3write <= 0;
            //     banksel <= 1;
            //     state <= 5'b01101;
            //     // if (x+1 == max_x) begin
            //     //     x <= 0;
            //     //     y <= y+4;
            //     //     if (y >= max_y) state = 2;
            //     // end
            // end
            // 5'b01101: begin
            //     mem_ptr <= weight_ptr + max_x * (y + regsel) + x;
            //     regsel <= regsel+1;
            //     // fc_write <= 1;
            //     r3write <= 1;
            //     banksel <= 1;
            //     if (x >= max_x) begin //increment y
            //         state <= 5'b01110;
            //         regsel <= 0; // May have issues with regsel overflow
            //     end else if (regsel == 3) begin
            //         x <= x+1;
            //         regsel <= 0;
            //         state <= 5'b01100;
            //         banksel <= 0;
            //     end
            // end
            // 5'b01110: begin
            //     mem_ptr <= out_ptr + x + regsel;
            //     // fc_write <= 0;
            //     r3write <= 0;
            //     regsel <= regsel+1;
            //     mem_wr <= 1;
            //     // if (x >= max_x && (y+regsel) >= max_y) begin
            //     //     done <= 1;
            //     //     mem_req <= 0;
            //     //     state <= 5'b00000;
            //     //     r3write <= 0;
            //     // end else if (x >= max_x) begin
            //     //     state <= 5'b01100;
            //     //     regsel <= 0; 
            //     //     x <= 0;
            //     //     y <= y + 4;
            //     //     r3write <= 0;
            //     // end else 
            //     if (regsel == 3) begin //increment y
            //         state <= 5'b01100;
            //         regsel <= 0; 
            //         x <= 0;
            //         y <= y + 4; // May have issues with regsel overflow
            //     end
            // end


















            // Convolution
            5'b10000: begin
                mem_ptr <= ker_ptr + 4 * ch;
                mem_wr <= 0;
                banksel <= 0;
                regsel <= 0;
                conv_compute <= 0;
                write_allowed <= 1;
                convreset <=0;
                state = 5'b10001;
                // if (x+1 == max_x) begin
                //     x <= 0;
                //     y <= y+4;
                //     if (y >= max_y) state = 2;
                // end
                // banksel <= 0;
                // regsel <= 0;
                // mem_wr <= 0;
                // write_allowed <= 1;
                
            end

            5'b10001: begin
                mem_ptr <= pxl_ptr + cols * (y + regsel) + x;
                regsel <= regsel+1;
                banksel <= 1;

                // fc_write <= 1;
                if (regsel+1 == 4) begin //increment y
                    state = 5'b10010;
                     // May hav     e issues with regsel overflow
                end
            end


            5'b10010: begin
                conv_compute <= 1;
                write_allowed <= 0;
                regsel <= 0;
                if (ch+1 < max_ch) begin
                    ch <= ch+1;
                    state = 5'b10000;
                end else begin
                    state <= 5'b10011;
                    regsel <= 0;
                end
            end
            5'b10011: begin
                conv_compute <=0;
                mem_wr <= 1;
                if (regsel+1 >= 3 && colsel+1 >= 3) begin
                    regsel <= 0;
                    colsel <= 0;
                    mem_ptr <= out_ptr + (cols-1) * (y + colsel) + x + regsel;
                    state <= 5'b10100;
                end else if (regsel+1 >= 3) begin
                    colsel <= colsel+1;
                    regsel <= 0;
                end else begin
                    regsel <= regsel + 1;
                end
                mem_ptr <= out_ptr + (cols-1) * (y + colsel) + x + regsel;
            end
            5'b10100: begin
                convreset <= 1;
                mem_wr <= 0;
                ch <= 0;
                if (x+1 >= max_x && y+1 >= max_y) begin
                    state <= 5'b00000;
                end else if (x+1 >= max_x) begin
                    x <= 0;
                    y <= y + 1;
                    state <= 5'b10000;
                end else begin
                    x <= x + 1;
                    state <= 5'b10000;
                end

            end
            5'b11110: begin
                state <= 5'b11111;
                mem_ptr <= ker_ptr + 4 * ch;
            end
            5'b11111: begin
                state <= 5'b10000;
                mem_ptr <= ker_ptr + 4 * ch;
            end

        endcase

    end

endmodule