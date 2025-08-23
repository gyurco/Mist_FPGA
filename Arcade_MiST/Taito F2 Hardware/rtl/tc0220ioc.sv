module TC0220IOC(
    input clk,

    input             RES_CLK_IN,
    input             RES_INn,
    output            RES_OUTn,

    input       [3:0] A,
    input             WEn,
    input             CSn,
    input             OEn,

    input       [7:0] Din,
    output reg  [7:0] Dout,

    output reg        COIN_LOCK_A,
    output reg        COIN_LOCK_B,
    output reg        COINMETER_A,
    output reg        COINMETER_B,

    input       [7:0] INB,
    input      [31:0] IN,

    input             rotary_inc,
    input             rotary_abs,
    input       [7:0] rotary_a,
    input       [7:0] rotary_b
);

// TODO reset, watchdog
//
// Real hardware just resets to zero while the zero flags are set
// We can't do that because we might miss a large delta update, so
// we track just the edge of the zero and don't drop any input data
reg zero_a, zero_b, zero_a_prev, zero_b_prev;
wire zero_a_edge = zero_a & ~zero_a_prev;
wire zero_b_edge = zero_b & ~zero_b_prev;
reg [15:0] paddle_a, paddle_b;
always_ff @(posedge clk) begin
    zero_a_prev <= zero_a;
    zero_b_prev <= zero_b;

    if (rotary_abs) begin
        paddle_a <= { {8{rotary_a[7]}}, rotary_a[7:0] };
        paddle_b <= { {8{rotary_b[7]}}, rotary_b[7:0] };
    end else if (rotary_inc) begin
        paddle_a <= (zero_a_edge ? 16'd0 : paddle_a) + { {8{rotary_a[7]}}, rotary_a[7:0] };
        paddle_b <= (zero_b_edge ? 16'd0 : paddle_b) + { {8{rotary_b[7]}}, rotary_b[7:0] };
    end else begin
        if (zero_a_edge) begin
            paddle_a <= 16'd0;
        end

        if (zero_b_edge) begin
            paddle_b <= 16'd0;
        end
    end

    if (~CSn) begin
        if (WEn) begin
            case(A)
                0: Dout <= IN[7:0];
                1: Dout <= IN[15:8];
                2: Dout <= IN[23:16];
                3: Dout <= IN[31:24];
                4: Dout <= { zero_b, zero_a, 2'b0, COINMETER_B, COINMETER_A, COIN_LOCK_B, COIN_LOCK_A };
                7: Dout <= INB;
                12: Dout <= zero_a ? 8'd0 : paddle_a[7:0];
                13: Dout <= zero_a ? 8'd0 : paddle_a[15:8];
                14: Dout <= zero_b ? 8'd0 : paddle_b[7:0];
                15: Dout <= zero_b ? 8'd0 : paddle_b[15:8];
                default: Dout <= 8'b0;
            endcase
        end else begin
            case(A)
                4: { zero_b, zero_a, COINMETER_B, COINMETER_A, COIN_LOCK_B, COIN_LOCK_A } <= { Din[7:6], Din[3:0] };
                default: begin end
            endcase
        end
    end
end

endmodule


