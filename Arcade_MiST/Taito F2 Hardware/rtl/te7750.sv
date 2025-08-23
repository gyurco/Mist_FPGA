module TE7750(
    input            clk,

    input            RESETn,

    input            CSn,
    input            RWn,
    input      [3:0] A,
    input      [7:0] Din,
    output reg [7:0] Dout,

    input      [7:0] P1in,
    input      [7:0] P2in,
    input      [7:0] P3in,
    input      [7:0] P4in,
    input      [7:0] P5in,
    input      [7:0] P6in,
    input      [7:0] P7in,
    input      [7:0] P8in,
    input      [7:0] P9in,

    output     [7:0] P1out,
    output     [7:0] P2out,
    output     [7:0] P3out,
    output     [7:0] P4out,
    output     [7:0] P5out,
    output     [7:0] P6out,
    output     [7:0] P7out,
    output     [7:0] P8out,
    output     [7:0] P9out
);

reg [7:0] CR0;
reg [7:0] CR1;
reg [7:0] CR2;
reg [7:0] CR3;

reg [7:0] latch[9];

// 1 = input
wire [7:0] dir1 = {8{CR1[4]}};
wire [7:0] dir2 = { {4{CR1[3]}}, {4{CR1[0]}} };
wire [7:0] dir3 = {8{CR1[1]}};
wire [7:0] dir4 = {8{CR2[4]}};
wire [7:0] dir5 = { {4{CR2[3]}}, {4{CR2[0]}} };
wire [7:0] dir6 = {8{CR2[1]}};
wire [7:0] dir7 = {8{CR3[4]}};
wire [7:0] dir8 = CR0;
wire [7:0] dir9 = {8{CR3[1]}};


assign P1out = latch[0] & ~dir1;
assign P2out = latch[1] & ~dir2;
assign P3out = latch[2] & ~dir3;
assign P4out = latch[3] & ~dir4;
assign P5out = latch[4] & ~dir5;
assign P6out = latch[5] & ~dir6;
assign P7out = latch[6] & ~dir7;
assign P8out = latch[7] & ~dir8;
assign P9out = latch[8] & ~dir9;

always_ff @(posedge clk) begin
    if (~RESETn) begin
        CR0 <= 8'hff;
        CR1 <= 8'hff;
        CR2 <= 8'hff;
        CR3 <= 8'hff;
        for ( int i = 0; i < 9; i = i + 1 ) begin
            latch[i] <= 8'h00;
        end
    end else begin
        if (~CSn) begin
            if (~RWn) begin
                case(A)
                    4'd9:  CR0 <= Din;
                    4'd10: CR1 <= Din;
                    4'd11: CR2 <= Din;
                    4'd12: CR3 <= Din;
                    default: begin
                        if (A < 4'd9) begin
                            latch[A] <= Din;
                        end
                    end
                endcase
            end else begin
                case(A)
                    4'd0: Dout <= (latch[0] & ~dir1) | (P1in & dir1);
                    4'd1: Dout <= (latch[1] & ~dir2) | (P2in & dir2);
                    4'd2: Dout <= (latch[2] & ~dir3) | (P3in & dir3);
                    4'd3: Dout <= (latch[3] & ~dir4) | (P4in & dir4);
                    4'd4: Dout <= (latch[4] & ~dir5) | (P5in & dir5);
                    4'd5: Dout <= (latch[5] & ~dir6) | (P6in & dir6);
                    4'd6: Dout <= (latch[6] & ~dir7) | (P7in & dir7);
                    4'd7: Dout <= (latch[7] & ~dir8) | (P8in & dir8);
                    4'd8: Dout <= (latch[8] & ~dir9) | (P9in & dir9);
                    4'd9:  Dout <= CR0;
                    4'd10: Dout <= CR1;
                    4'd11: Dout <= CR2;
                    4'd12: Dout <= CR3;
                    default: Dout <= 8'hff;
                endcase
            end
        end
    end
end




endmodule




