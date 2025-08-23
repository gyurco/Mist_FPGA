module tc0100scn_shifter #(
    parameter PALETTE_WIDTH=8,
    parameter PIXEL_WIDTH=4)
(
    input clk,
    input ce_pixel,
    input load,

    input [2:0] tap,
    input [(PIXEL_WIDTH * 8) - 1:0] gfx_in,
    input [PALETTE_WIDTH - 1:0] palette_in,
    input flip_x,
    output [PIXEL_WIDTH + PALETTE_WIDTH - 1:0] dot_out
);

localparam DOT_WIDTH = (PALETTE_WIDTH + PIXEL_WIDTH);
localparam SHIFT_END = (DOT_WIDTH * 16) - 1;

reg [SHIFT_END:0] shift;

assign dot_out = shift[(SHIFT_END - (DOT_WIDTH * tap)) -: DOT_WIDTH];

always_ff @(posedge clk) begin
    if (ce_pixel) begin
        shift[SHIFT_END:DOT_WIDTH] <= shift[SHIFT_END-DOT_WIDTH:0];
        if (load) begin
            int i;
            if (flip_x) begin
                for( i = 0; i < 8; i = i + 1 ) begin
                    shift[(DOT_WIDTH * (7 - i)) +: DOT_WIDTH] <= { palette_in, gfx_in[(PIXEL_WIDTH * i) +: PIXEL_WIDTH] };
                end
            end else begin
                for( i = 0; i < 8; i = i + 1 ) begin
                    shift[(DOT_WIDTH * i) +: DOT_WIDTH] <= { palette_in, gfx_in[(PIXEL_WIDTH * i) +: PIXEL_WIDTH] };
                end
            end
        end
    end
end

endmodule

module TC0100SCN #(parameter SS_IDX=-1) (
    input clk,
    input ce_13m,
    input ce_pixel, // TODO - does this generate it?

    input reset,

    // CPU interface
    input [17:0] VA,
    input [15:0] Din,
    output reg [15:0] Dout,
    input LDSn,
    input UDSn,
    input SCCSn,
    input RW,
    output DACKn,

    // RAM interface
    output     [14:0] SA,
    input      [15:0] SDin,
    output     [15:0] SDout,
    output reg        WEUPn,
    output reg        WELOn,
    output            SCE0n,
    output            SCE1n,

    // ROM interface
    output reg [20:0] rom_address,
    input      [31:0] rom_data,
    output reg        rom_req,
    input             rom_ack,


    // Video interface
    output [14:0] SC,
    output HSYNn,
    output HBLOn,
    output VSYNn,
    output VBLOn,
    output OLDH,
    output OLDV,
    input IHLD, // FIXME - confirm inputs
    input IVLD,

    ssbus_if.slave ssbus
);

typedef enum bit [3:0]
{
    BG0_ROW_SCROLL = 4'd0,
    BG0_ATTRIB1_EX,
    BG1_COL_SCROLL_EX,
    FG0_GFX_EX,
    BG1_ROW_SCROLL,
    BG1_ATTRIB1_EX,
    FG0_ATTRIB_EX,
    CPU_ACCESS_EX,

    BG0_ATTRIB0,
    BG0_ATTRIB1,
    BG1_COL_SCROLL,
    FG0_GFX,
    BG1_ATTRIB0,
    BG1_ATTRIB1,
    FG0_ATTRIB,
    CPU_ACCESS
} access_state_t;


reg dtack_n;
reg prev_cs_n;

reg ram_pending = 0;
reg ram_access = 0;
reg [16:0] ram_addr;


reg [8:0] hcnt_actual, vcnt_actual;

reg [15:0] ctrl[8];

wire [15:0] bg0_x = ctrl[0];
wire [15:0] bg1_x = ctrl[1];
wire [15:0] fg0_x = ctrl[2];
wire [15:0] bg0_y = ctrl[3];
wire [15:0] bg1_y = ctrl[4];
wire [15:0] fg0_y = ctrl[5];
wire bg0_en = ~ctrl[6][0];
wire bg1_en = ~ctrl[6][1];
wire fg0_en = ~ctrl[6][2];
wire bg0_prio = ctrl[6][3];
wire wide = ctrl[6][4];
wire flip = ctrl[7][0];

wire [8:0] vcnt = flip ? { 9'd255 - vcnt_actual } : vcnt_actual;
wire [8:0] hcnt = flip ? { 9'd343 - hcnt_actual } : hcnt_actual;

assign DACKn = SCCSn ? 0 : dtack_n;
assign SA = ram_addr[15:1];
assign SCE0n = ram_addr[16];
assign SCE1n = ~ram_addr[16];
assign SDout = Din;

assign HSYNn = flip ? (hcnt_actual >= 24 && hcnt_actual < 344) : (hcnt_actual >= 25 && hcnt_actual < 345);
assign HBLOn = HSYNn;
assign VSYNn = vcnt_actual >= 2 && vcnt_actual < 226;
assign VBLOn = VSYNn;

// FIXME, are the MSB correct?
//
assign SC = (fg0_en & |fg0_dot[3:0]) ? { 3'b010, fg0_dot } :
            (~bg0_prio & bg1_en & |bg1_dot[3:0]) ? { 3'b110, bg1_dot } :
            (bg0_en & |bg0_dot[3:0]) ? { 3'b100, bg0_dot } :
            (bg0_prio & bg1_en & |bg1_dot[3:0]) ? { 3'b110, bg1_dot } :
            { 3'b100, 12'd0 };

reg [3:0] state;

reg prev_ihld;

always @(posedge clk) begin
    bit [8:0] h, v;
    if (reset) begin
        hcnt_actual <= 0;
        vcnt_actual <= 0;
    end else if (ce_pixel) begin
        prev_ihld <= IHLD;
        hcnt_actual <= hcnt_actual + 1;

        if (IHLD & ~prev_ihld) begin /* 424 * 2 - 1 */
            hcnt_actual <= 0;
            vcnt_actual <= vcnt_actual + 1;
            if (IVLD) begin
                vcnt_actual <= 0;
            end
        end
    end
end

reg [3:0] access_cycle;
logic [3:0] next_access_cycle;


wire [8:0] bg0_hofs = bg0_x[8:0] + bg0_rowscroll[8:0];
wire [8:0] bg1_hofs = bg1_x[8:0] + bg1_rowscroll[8:0];
reg [31:0] bg0_gfx;
wire [31:0] bg1_gfx = rom_data;
wire [11:0] bg0_dot, bg1_dot, fg0_dot;
reg [15:0] bg0_rowscroll, bg1_rowscroll;
reg [15:0] bg1_colscroll;
reg [15:0] bg0_code, bg1_code;
reg [15:0] bg0_attrib, bg1_attrib;
reg [15:0] fg0_code, fg0_gfx, fg0_code_next;

wire bg0_flipx = bg0_attrib[14];
wire bg0_flipy = bg0_attrib[15];
wire bg1_flipx = bg1_attrib[14];
wire bg1_flipy = bg1_attrib[15];
wire fg0_flipx = fg0_code[14];
wire fg0_flipy = fg0_code[15];



wire [31:0] fg0_gfx_swizzle = { 2'b0, fg0_gfx[15], fg0_gfx[7],
                                2'b0, fg0_gfx[14], fg0_gfx[6],
                                2'b0, fg0_gfx[13], fg0_gfx[5],
                                2'b0, fg0_gfx[12], fg0_gfx[4],
                                2'b0, fg0_gfx[11], fg0_gfx[3],
                                2'b0, fg0_gfx[10], fg0_gfx[2],
                                2'b0, fg0_gfx[ 9], fg0_gfx[1],
                                2'b0, fg0_gfx[ 8], fg0_gfx[0] };

tc0100scn_shifter bg0_shift(
    .clk, .ce_pixel,
    .tap(flip ? bg0_hofs[2:0] : ~bg0_hofs[2:0]),
    .gfx_in({bg0_gfx[15:8], bg0_gfx[7:0], bg0_gfx[31:24], bg0_gfx[23:16]}),
    .palette_in(bg0_attrib[7:0]),
    .flip_x(bg0_flipx ^ flip),
    .dot_out(bg0_dot),
    .load(&access_cycle[2:0])
);

tc0100scn_shifter bg1_shift(
    .clk, .ce_pixel,
    .tap(flip ? bg1_hofs[2:0] : ~bg1_hofs[2:0]),
    .gfx_in({bg1_gfx[15:8], bg1_gfx[7:0], bg1_gfx[31:24], bg1_gfx[23:16]}),
    .palette_in(bg1_attrib[7:0]),
    .flip_x(bg1_flipx ^ flip),
    .dot_out(bg1_dot),
    .load(&access_cycle[2:0])
);

tc0100scn_shifter fg0_shift(
    .clk, .ce_pixel,
    .tap(flip ? fg0_x[2:0] : ~fg0_x[2:0]),
    .gfx_in(fg0_gfx_swizzle),
    .palette_in({2'b0, fg0_code[13:8]}),
    .flip_x(fg0_flipx ^ flip),
    .dot_out(fg0_dot),
    .load(&access_cycle[2:0])
);

wire [16:0] bg0_addr             = wide ? 17'h00000 : 17'h00000;
wire [16:0] bg1_addr             = wide ? 17'h08000 : 17'h08000;
wire [16:0] bg0_row_scroll_addr  = wide ? 17'h10000 : 17'h0c000;
wire [16:0] bg1_row_scroll_addr  = wide ? 17'h10400 : 17'h0c400;
wire [16:0] bg1_col_scroll_addr  = wide ? 17'h10800 : 17'h0e000;
wire [16:0] fg0_addr             = wide ? 17'h11000 : 17'h04000;
wire [16:0] fg0_gfx_addr         = wide ? 17'h12000 : 17'h06000;

always_comb begin
    bit [5:0] h;
    bit [8:0] v;

    ram_addr = 17'd0;
    WEUPn = 1;
    WELOn = 1;

    h = 0;
    v = 0;

    if (access_cycle == 15) begin
        next_access_cycle = 8;
    end else begin
        next_access_cycle = access_cycle + 4'd1;
    end

    unique case(access_cycle)
        BG0_ATTRIB0: begin
            h = hcnt[8:3] - bg0_hofs[8:3];
            v = vcnt - bg0_y[8:0];
            ram_addr = bg0_addr + { 3'b0, v[8:3], h, 2'b00 };
        end

        BG0_ATTRIB1_EX,
        BG0_ATTRIB1: begin
            h = hcnt[8:3] - bg0_hofs[8:3];
            v = vcnt - bg0_y[8:0];
            ram_addr = bg0_addr + { 3'b0, v[8:3], h, 2'b10 };
        end

        BG1_ATTRIB0: begin
            h = hcnt[8:3] - bg1_hofs[8:3];
            v = vcnt - bg1_y[8:0];
            ram_addr = bg1_addr + { 3'b0, v[8:3], h, 2'b00 };
        end

        BG1_ATTRIB1_EX,
        BG1_ATTRIB1: begin
            h = hcnt[8:3] - bg1_hofs[8:3];
            v = vcnt - bg1_y[8:0];
            ram_addr = bg1_addr + { 3'b0, v[8:3], h, 2'b10 };
        end

        BG1_COL_SCROLL_EX,
        BG1_COL_SCROLL: begin
            ram_addr = bg1_col_scroll_addr + { 10'b0, hcnt[8:3], 1'b0 };
        end

        FG0_ATTRIB_EX,
        FG0_ATTRIB: begin
            h = hcnt[8:3] - fg0_x[8:3];
            v = vcnt - fg0_y[8:0];
            ram_addr = fg0_addr + { 4'b0, v[8:3], h + (flip ? 6'd0 : 6'd1), 1'b0 };
        end

        FG0_GFX_EX,
        FG0_GFX: begin
            v = vcnt - fg0_y[8:0];
            ram_addr = fg0_gfx_addr + { 5'b0, fg0_code[7:0], fg0_flipy ? ~v[2:0] : v[2:0], 1'b0 };
        end

        BG0_ROW_SCROLL: begin
            ram_addr = bg0_row_scroll_addr + { 8'b0, vcnt[7:0], 1'b0 };
        end

        BG1_ROW_SCROLL: begin
            ram_addr = bg1_row_scroll_addr + { 8'b0, vcnt[7:0], 1'b0 };
        end

        CPU_ACCESS_EX,
        CPU_ACCESS: begin
            ram_addr = VA[16:0];
            WELOn = ~ram_access | LDSn | RW;
            WEUPn = ~ram_access | UDSn | RW;
        end

    endcase
end


always @(posedge clk) begin
    bit [8:0] v;
    bit [5:0] h;

    if (reset) begin
        dtack_n <= 1;
        ram_pending <= 0;
        ram_access <= 0;
    end begin
        // CPu interface handling
        prev_cs_n <= SCCSn;
        if (~SCCSn & prev_cs_n) begin // CS edge
            if (VA[17]) begin // control access
                if (RW) begin
                    Dout <= ctrl[VA[3:1]];
                end else begin
                    if (~UDSn) ctrl[VA[3:1]][15:8] <= Din[15:8];
                    if (~LDSn) ctrl[VA[3:1]][7:0]  <= Din[7:0];
                end
                dtack_n <= 0;
            end else begin // ram access
                ram_pending <= 1;
            end
        end else if (SCCSn) begin
            dtack_n <= 1;
        end

        if (ce_pixel) begin
            unique case(access_cycle)
                BG0_ROW_SCROLL: bg0_rowscroll <= SDin;
                BG0_ATTRIB0: bg0_attrib <= SDin;
                BG0_ATTRIB1_EX,
                BG0_ATTRIB1: begin
                    bg0_code <= SDin;
                    v = vcnt - bg0_y[8:0];
                    rom_address <= { SDin, bg0_flipy ? ~v[2:0] : v[2:0], 2'b0 };
                    rom_req <= ~rom_req;
                end

                BG1_ROW_SCROLL: bg1_rowscroll <= SDin;
                BG1_ATTRIB0: bg1_attrib <= SDin;
                BG1_ATTRIB1_EX,
                BG1_ATTRIB1: begin
                    bg0_gfx <= rom_data;
                    bg1_code <= SDin;
                    v = vcnt - bg1_y[8:0];
                    rom_address <= { SDin, bg1_flipy ? ~v[2:0] : v[2:0], 2'b0 };
                    rom_req <= ~rom_req;
                end

                BG1_COL_SCROLL_EX,
                BG1_COL_SCROLL: begin
                    bg1_colscroll <= SDin;
                    fg0_code <= fg0_code_next;
                end

                FG0_ATTRIB_EX,
                FG0_ATTRIB: fg0_code_next <= SDin;

                FG0_GFX_EX,
                FG0_GFX: fg0_gfx <= SDin;

                CPU_ACCESS_EX,
                CPU_ACCESS: begin
                    if (ram_access) begin
                        ram_access <= 0;
                        ram_pending <= 0;
                        dtack_n <= 0;
                        Dout <= SDin;
                    end
                end
            endcase

            if (prev_ihld & ~IHLD) begin
                access_cycle <= 0;
            end else begin
                access_cycle <= next_access_cycle;
                case(next_access_cycle)
                    CPU_ACCESS_EX,
                    CPU_ACCESS: begin
                        ram_access <= ram_pending;
                    end

                    default: begin
                    end
                endcase
            end
        end
    end

    ssbus.setup(SS_IDX, 8, 1);
    if (ssbus.access(SS_IDX)) begin
        if (ssbus.write) begin
            ctrl[ssbus.addr[2:0]] <= ssbus.data[15:0];
            ssbus.write_ack(SS_IDX);
        end else if (ssbus.read) begin
            ssbus.read_response(SS_IDX, { 48'b0, ctrl[ssbus.addr[2:0]] });
        end
    end
end

endmodule

