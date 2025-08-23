// TMP82C265 IO expander implementation
// Does not implement modes other than mode 0
// Does not implement the hardware selected output mode

module TMP82C265_Block(
    input clk,

    input             RESET,

    input       [1:0] A,
    input             RDn,
    input             WRn,
    input             CSn,

    input       [7:0] DBin,
    output reg  [7:0] DBout,

    input       [7:0] PAin,
    input       [7:0] PBin,
    input       [7:0] PCin,

    output reg  [7:0] PAout,
    output reg  [7:0] PBout,
    output reg  [7:0] PCout
);

reg [6:0] ctrl;
wire CLdir = ctrl[0];
wire Bdir = ctrl[1];
wire Bmode = ctrl[2];
wire CHdir = ctrl[3];
wire Adir = ctrl[4];
wire [1:0] Amode = ctrl[6:5];

always_ff @(posedge clk) begin
    if (RESET) begin
        ctrl <= 7'b0011011;
        PAout <= 0;
        PBout <= 0;
        PCout <= 0;
    end else begin
        if (~CSn) begin
            if (~RDn) begin
                case(A)
                    0: DBout <= PAin;
                    1: DBout <= PBin;
                    2: DBout <= PCin;
                    default: DBout <= 8'b0;
                endcase
            end

            if (~WRn) begin
                case(A)
                    0: PAout <= DBin;
                    1: PBout <= DBin;
                    2: PCout <= DBin;
                    3: begin
                        if (DBin[7]) begin
                            ctrl <= DBin[6:0];
                        end else begin
                            PCout[DBin[3:1]] <= DBin[0];
                        end
                    end
                endcase
            end
        end
    end
end

endmodule

module TMP82C265(
    input             clk,

    input             RESET,

    input       [1:0] A,
    input             RDn,
    input             WRn,
    input             CS0n,
    input             CS1n,

    input       [7:0] DBin,
    output      [7:0] DBout,

    input       [15:0] PAin,
    input       [15:0] PBin,
    input       [15:0] PCin,

    output      [15:0] PAout,
    output      [15:0] PBout,
    output      [15:0] PCout
);

wire [7:0] DBout_low, DBout_high;

assign DBout = ~CS0n ? DBout_low : DBout_high;

TMP82C265_Block low_block(
    .clk(clk),
    .RESET(RESET),
    .A(A),
    .RDn(RDn),
    .WRn(WRn),
    .CSn(CS0n),
    .DBin(DBin),
    .DBout(DBout_low),
    .PAin(PAin[7:0]),
    .PBin(PBin[7:0]),
    .PCin(PCin[7:0]),
    .PAout(PAout[7:0]),
    .PBout(PBout[7:0]),
    .PCout(PCout[7:0])
);

TMP82C265_Block high_block(
    .clk(clk),
    .RESET(RESET),
    .A(A),
    .RDn(RDn),
    .WRn(WRn),
    .CSn(CS1n),
    .DBin(DBin),
    .DBout(DBout_high),
    .PAin(PAin[15:8]),
    .PBin(PBin[15:8]),
    .PCin(PCin[15:8]),
    .PAout(PAout[15:8]),
    .PBout(PBout[15:8]),
    .PCout(PCout[15:8])
);

endmodule


