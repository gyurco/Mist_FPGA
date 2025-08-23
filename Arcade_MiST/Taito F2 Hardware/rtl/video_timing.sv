module video_timing(
    input clk,
    input ce_13m,

    input sync_fix,

    output ce_pixel,

    output reg [8:0] hcnt,
    output reg [8:0] vcnt,

    output reg hsync,
    output reg vsync,
    output reg hblank,
    output reg vblank
);

wire [8:0] H_START = 0;
wire [8:0] H_END = 424 - 1;
wire [8:0] HS_START = 340;
wire [8:0] HS_END = sync_fix ? (372 - 1) : (404 - 1);
wire [8:0] HB_START = 320;
wire [8:0] HB_END = H_END;

wire [8:0] V_START = 0;
wire [8:0] V_END = 262 - 1;
wire [8:0] VS_START = 240;
wire [8:0] VS_END = sync_fix ? (244 - 1) : (246 - 1);
wire [8:0] VB_START = 224;
wire [8:0] VB_END = V_END;

reg ce_div;

assign ce_pixel = ce_13m & ce_div;

always_ff @(posedge clk) begin
    if (ce_13m) ce_div <= ~ce_div;

    if (ce_pixel) begin
        hcnt <= hcnt + 1;
        if (hcnt == H_END) begin
            hcnt <= H_START;
            vcnt <= vcnt + 1;

            if (vcnt == V_END) begin
                vcnt <= V_START;
            end
        end

        hsync <= (hcnt >= HS_START && hcnt <= HS_END);
        hblank <= (hcnt >= HB_START && hcnt <= HB_END);
        vsync <= (vcnt >= VS_START && vcnt <= VS_END);
        vblank <= (vcnt >= VB_START && vcnt <= VB_END);
    end
end

endmodule
