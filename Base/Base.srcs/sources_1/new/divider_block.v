module divider_block(
    input clk, rst, start,
    input [31:0] numerator, denominator,
    input is_signed,
    output reg [31:0] remainder,
    output reg [31:0] quotient,
    output reg done
);

reg [2:0] state, next_state;
reg [5:0] ctr;
reg [31:0] num_buff;
reg quotient_buf;

// sign handling
reg sign_a, sign_b;
reg [31:0] abs_num, abs_den;

// compute next remainder (shift in next bit)
wire [31:0] next_remainder = {remainder[30:0], num_buff[31]};

always @(*) begin
    case (state) 
        3'b000: next_state = (start) ? 3'b001 : 3'b000;
        3'b001: next_state = (next_remainder >= abs_den) ? 3'b011 : 3'b010;
        3'b010: next_state = 3'b100;
        3'b011: next_state = 3'b100;
        3'b100: next_state = (ctr > 0) ? 3'b001 : 3'b101;
        3'b101: next_state = 3'b000;
        default: next_state = 3'b000;
    endcase
end

always @(posedge clk) begin
    if (rst) begin
        remainder <= 0;
        quotient <= 0;
        state <= 0;
        ctr <= 32;
        done <= 1'b0;
    end else begin
        state <= next_state;

        case (next_state)

            // INIT
            3'b000: begin
                remainder <= 0;
                quotient <= 0;
                ctr <= 32;
                done <= 1'b0;

                if (is_signed) begin
                    sign_a <= numerator[31];
                    sign_b <= denominator[31];

                    abs_num <= numerator[31] ? -numerator : numerator;
                    abs_den <= denominator[31] ? -denominator : denominator;

                    num_buff <= numerator[31] ? -numerator : numerator;
                end else begin
                    sign_a <= 1'b0;
                    sign_b <= 1'b0;

                    abs_num <= numerator;
                    abs_den <= denominator;

                    num_buff <= numerator;
                end
            end

            // ITERATION START
            3'b001: begin
                ctr <= ctr - 1;
                quotient_buf <= 1'b0;
            end

            // NO SUBTRACT
            3'b010: begin
                remainder <= next_remainder;
            end

            // SUBTRACT
            3'b011: begin
                quotient_buf <= 1'b1;
                remainder <= next_remainder - abs_den;
            end

            // WRITE QUOTIENT + SHIFT
            3'b100: begin 
                quotient <= {quotient[30:0], quotient_buf}; 
                num_buff <= num_buff << 1;
            end

            // DONE
            3'b101: begin
                if (is_signed) begin
                    // fix quotient sign
                    if (sign_a ^ sign_b)
                        quotient <= -quotient;

                    // remainder follows numerator sign
                    if (sign_a)
                        remainder <= -remainder;
                end
                done <= 1'b1;
            end

        endcase
    end
end

endmodule