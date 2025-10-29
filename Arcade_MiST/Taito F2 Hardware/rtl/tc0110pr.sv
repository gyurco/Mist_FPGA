module TC0110PR(
    input clk,
    input ce_pixel,

    // CPU Interface
    input [15:0] Din,
    output reg [15:0] Dout,

    input [1:0] VA,
    input RWn,
    input UDSn,
    input LDSn,

    input SCEn,
    output DACKn,

    // Video Input
    input HSYn,
    input VSYn,

    input [14:0] SC,
    input [14:0] OB,

    // RAM Interface
    output [12:0] CA,
    input [15:0] CDin,
    output [15:0] CDout,
    output reg WELn,
    output reg WEHn
);

reg cpu_mode = 0;
reg end_cpu_mode = 0;
reg [12:0] cpu_addr;
reg dtack_n;
reg [12:0] color_addr;
reg prev_sce_n;

assign CDout = Din;
assign CA = cpu_mode ? cpu_addr : color_addr;
assign DACKn = SCEn ? 0 : dtack_n;

always_ff @(posedge clk) begin
    prev_sce_n <= SCEn;
    WELn <= 1;
    WEHn <= 1;
    if (~SCEn & prev_sce_n) begin
        if (RWn) begin
            case(VA)
                2'b00: begin
                    Dout[12:0] <= cpu_addr;
                    dtack_n <= 0;
                    cpu_mode <= 1;
                end
                2'b01: begin
                    Dout <= CDin;
                    dtack_n <= 0;
                    cpu_mode <= 1;
                end
                default: begin
                    dtack_n <= 0;
                end
            endcase
        end else begin
            case(VA)
                2'b00: begin
                    if (~UDSn) cpu_addr[12:8] <= Din[12:8];
                    if (~LDSn) cpu_addr[7:0] <= Din[7:0];
                    dtack_n <= 0;
                    cpu_mode <= 1;
                end
                2'b01: begin
                    WELn <= LDSn;
                    WEHn <= UDSn;
                    dtack_n <= 0;
                    cpu_mode <= 1;
                    end_cpu_mode <= 1;
                end
                2'b10: begin
                    dtack_n <= 0;
                    end_cpu_mode <= 1;
                end
                default: begin
                    dtack_n <= 0;
                end
            endcase
        end
    end

    if (SCEn) begin
        if (end_cpu_mode) begin
            end_cpu_mode <= 0;
            cpu_mode <= 0;
        end
        dtack_n <= 1;
    end

    if (ce_pixel) begin
        if (~SC[14])
            color_addr <= {SC[11:0], 1'b0};
        else if (|OB[5:0])
            color_addr <= {OB[11:0], 1'b0};
        else
            color_addr <= {SC[11:0], 1'b0};
    end
end

endmodule



