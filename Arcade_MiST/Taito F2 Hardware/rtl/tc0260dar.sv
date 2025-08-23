module TC0260DAR(
    input clk,
    input ce_pixel,
    input ce_double,

    // RGB555 vs RGB444
    input bpp15,
    // LSB color in [3:1]
    input bppmix,

    // CPU Interface
    input [15:0] MDin,
    output reg [15:0] MDout,

    input        CS,
    input [13:0] MA,
    input RWn,
    input UDSn,
    input LDSn,

    output DTACKn,

    input ACCMODE,

    // Video Input
    input HBLANKn,
    input VBLANKn,

    output OHBLANKn,
    output OVBLANKn,

    input [13:0] IM,
    output reg [7:0] VIDEOR,
    output reg [7:0] VIDEOG,
    output reg [7:0] VIDEOB,

    // RAM Interface
    // Real hardware uses and 8-bit interface and is clocked at double the
    // pixel clock. I'm using a 16-bit interface to remain compatible with the
    // TC0100PR usage of block ram
    output [13:0] RA,
    input [15:0] RDin,
    output [15:0] RDout,
    output reg RWELn,
    output reg RWEHn
);

reg hb1, hb2, hb3, vb1, vb2, vb3;

wire busy = ~ACCMODE ? (HBLANKn & VBLANKn & hb1 & hb2 & hb3 & vb1 & vb2 & vb3) : 0;
reg cpu_access;

assign MDout = RDin;
assign RDout = MDin;
assign RA = cpu_access ? MA : IM;
assign RWELn = cpu_access ? (RWn | LDSn) : 1;
assign RWEHn = cpu_access ? (RWn | UDSn) : 1;
assign DTACKn = CS ? ~cpu_access : 0;
assign OHBLANKn = hb3;
assign OVBLANKn = vb3;


always_ff @(posedge clk) begin
    if (ce_double) begin
        cpu_access <= CS & (~busy | cpu_access);
    end

    if (ce_pixel) begin
        hb1 <= HBLANKn; hb2 <= hb1; hb3 <= hb2;
        vb1 <= VBLANKn; vb2 <= vb1; vb3 <= vb2;

        if (hb2 & vb2 & ~cpu_access) begin
            if (bpp15 & bppmix) begin
                VIDEOR <= { RDin[15:12], RDin[3], RDin[15:13] };
                VIDEOG <= { RDin[11:8], RDin[2], RDin[11:9] };
                VIDEOB <= { RDin[7:4], RDin[1], RDin[7:5] };
            end else if (bpp15) begin
                VIDEOR <= { RDin[14:10], RDin[14:12] };
                VIDEOG <= { RDin[9:5], RDin[9:7] };
                VIDEOB <= { RDin[4:0], RDin[4:2] };
            end else begin
                VIDEOR <= { RDin[15:12], RDin[15:12] };
                VIDEOG <= { RDin[11:8], RDin[11:8] };
                VIDEOB <= { RDin[7:4], RDin[7:4] };
            end
        end else begin
            VIDEOR <= 8'd0;
            VIDEOG <= 8'd0;
            VIDEOB <= 8'd0;
        end
    end
end

endmodule



