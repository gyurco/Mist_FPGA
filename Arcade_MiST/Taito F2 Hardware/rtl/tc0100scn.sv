module tc0100scn_shifter #(
    parameter TILE_WIDTH=8,
    parameter LENGTH=4
    )
(
    input                                         clk,
    input                                         ce,

    input                                         load,
    input [$clog2(LENGTH)-1:0]                    load_index,
    input [7:0]                                   load_color,
    input [(TILE_WIDTH*4)-1:0]                    load_data,
    input                                         load_flip,

    input [$clog2(LENGTH)+$clog2(TILE_WIDTH)-1:0] tap,
    output reg [11:0]                             dot_out
);

reg [7:0] color_buf[LENGTH];
reg [(TILE_WIDTH*4)-1:0] pixel_buf[LENGTH];

wire [$clog2(LENGTH)-1:0] tap_index = tap[$left(tap):$clog2(TILE_WIDTH)];
wire [$clog2(TILE_WIDTH)-1:0] tap_pixel = tap[$clog2(TILE_WIDTH)-1:0];

always_ff @(posedge clk) begin
    if (load) begin

        color_buf[load_index] <= load_color;
        if (~load_flip) begin
            int i;
            for( i = 0; i < TILE_WIDTH; i = i + 1 ) begin
                pixel_buf[load_index][(4 * ((TILE_WIDTH-1) - i)) +: 4] <= load_data[(4 * i) +: 4];
            end
        end else begin
            pixel_buf[load_index] <= load_data;
        end
    end

    if (ce) begin
        dot_out <= { color_buf[tap_index], pixel_buf[tap_index][(4 * tap_pixel) +: 4] };
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
    FG0_ATTRIB_EX,
    BG1_ROW_SCROLL,
    BG1_ATTRIB1_EX,
    FG0_GFX_EX,
    CPU_ACCESS_EX,

    BG0_ATTRIB0,
    BG0_ATTRIB1,
    BG1_COL_SCROLL,
    FG0_ATTRIB,
    BG1_ATTRIB0,
    BG1_ATTRIB1,
    FG0_GFX,
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
wire [15:0] fg0_x = flip ? (ctrl[2] - 15'd7) : ctrl[2];
wire [15:0] bg0_y = ctrl[3];
wire [15:0] bg1_y = ctrl[4] + bg1_colscroll[15:0];
wire [15:0] fg0_y = ctrl[5];
wire bg0_en = ~ctrl[6][0];
wire bg1_en = ~ctrl[6][1];
wire fg0_en = ~ctrl[6][2];
wire bg0_prio = ctrl[6][3];
wire wide = ctrl[6][4];
wire flip = ctrl[7][0];

wire [8:0] vcnt = flip ? { 9'd255 - vcnt_actual } : vcnt_actual;
wire [8:0] hcnt = flip ? { 9'd351 - hcnt_actual } : hcnt_actual;

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
            hcnt_actual <= 504;
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
wire [11:0] bg0_dot, bg1_dot, fg0_dot;
reg [15:0] bg0_rowscroll, bg1_rowscroll;
reg [15:0] bg1_colscroll;
reg [15:0] bg0_code, bg1_code;
reg [15:0] bg0_attrib, bg1_attrib;
reg [15:0] fg0_code, fg0_gfx;

reg bg0_load, bg1_load;
reg bg0_rom_req, bg1_rom_req;
reg [20:0] bg0_rom_address, bg1_rom_address;

reg [1:0] rom_req_ch;

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

wire [8:0] bg0_draw_hcnt = (hcnt - bg0_hofs);
wire [8:0] bg1_draw_hcnt = (hcnt - bg1_hofs);
wire [8:0] fg0_draw_hcnt = (hcnt - fg0_x[8:0]);

reg [1:0] bg0_load_index, bg1_load_index;
reg [8:0] bg0_load_hcnt, bg1_load_hcnt, fg0_load_hcnt;

tc0100scn_shifter bg0_shift(
    .clk, .ce(ce_pixel),
    .tap(bg0_draw_hcnt[4:0]),
    .load_index(bg0_load_index),
    .load_data({rom_data[15:8], rom_data[7:0], rom_data[31:24], rom_data[23:16]}),
    .load_color(bg0_attrib[7:0]),
    .load_flip(bg0_flipx),
    .dot_out(bg0_dot),
    .load(bg0_load)
);

tc0100scn_shifter bg1_shift(
    .clk, .ce(ce_pixel),
    .tap(bg1_draw_hcnt[4:0]),
    .load_index(bg1_load_index),
    .load_data({rom_data[15:8], rom_data[7:0], rom_data[31:24], rom_data[23:16]}),
    .load_color(bg1_attrib[7:0]),
    .load_flip(bg1_flipx),
    .dot_out(bg1_dot),
    .load(bg1_load)
);

tc0100scn_shifter fg0_shift(
    .clk, .ce(ce_pixel),
    .tap(fg0_draw_hcnt[4:0]),
    .load_index(fg0_load_hcnt[4:3]),
    .load_data(fg0_gfx_swizzle),
    .load_color({2'b0, fg0_code[13:8]}),
    .load_flip(fg0_flipx),
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

    v = 0;

    if (access_cycle == 15) begin
        next_access_cycle = 8;
    end else begin
        next_access_cycle = access_cycle + 4'd1;
    end

    unique case(access_cycle)
        BG0_ATTRIB0: begin
            v = vcnt - bg0_y[8:0];
            ram_addr = bg0_addr + { 3'b0, v[8:3], bg0_load_hcnt[8:3], 2'b00 };
        end

        BG0_ATTRIB1_EX,
        BG0_ATTRIB1: begin
            v = vcnt - bg0_y[8:0];
            ram_addr = bg0_addr + { 3'b0, v[8:3], bg0_load_hcnt[8:3], 2'b10 };
        end

        BG1_ATTRIB0: begin
            v = vcnt - bg1_y[8:0];
            ram_addr = bg1_addr + { 3'b0, v[8:3], bg1_load_hcnt[8:3], 2'b00 };
        end

        BG1_ATTRIB1_EX,
        BG1_ATTRIB1: begin
            v = vcnt - bg1_y[8:0];
            ram_addr = bg1_addr + { 3'b0, v[8:3], bg1_load_hcnt[8:3], 2'b10 };
        end

        BG1_COL_SCROLL_EX,
        BG1_COL_SCROLL: begin
            ram_addr = bg1_col_scroll_addr + { 10'b0, bg1_load_hcnt[8:3], 1'b0 };
        end

        FG0_ATTRIB_EX,
        FG0_ATTRIB: begin
            v = vcnt - fg0_y[8:0];
            ram_addr = fg0_addr + { 4'b0, v[8:3], fg0_load_hcnt[8:3], 1'b0 };
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
            bg0_load <= 0;
            bg1_load <= 0;
            unique case(access_cycle)
                BG0_ROW_SCROLL: bg0_rowscroll <= SDin;
                BG0_ATTRIB0: bg0_attrib <= SDin;
                BG0_ATTRIB1_EX,
                BG0_ATTRIB1: begin
                    bg0_code <= SDin;
                    v = vcnt - bg0_y[8:0];
                    bg0_rom_address <= { SDin, bg0_flipy ? ~v[2:0] : v[2:0], 2'b0 };
                    bg0_load_index <= bg0_load_hcnt[4:3];
                    bg0_rom_req <= 1;
                end

                BG1_ROW_SCROLL: bg1_rowscroll <= SDin;
                BG1_ATTRIB0: bg1_attrib <= SDin;
                BG1_ATTRIB1_EX,
                BG1_ATTRIB1: begin
                    bg1_code <= SDin;
                    v = vcnt - bg1_y[8:0];
                    bg1_rom_address <= { SDin, bg1_flipy ? ~v[2:0] : v[2:0], 2'b0 };
                    bg1_load_index <= bg1_load_hcnt[4:3];
                    bg1_rom_req <= 1;
                end

                BG1_COL_SCROLL_EX,
                BG1_COL_SCROLL: begin
                    bg1_colscroll <= SDin;
                end

                FG0_ATTRIB_EX,
                FG0_ATTRIB: fg0_code <= SDin;

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

                    BG0_ATTRIB0: begin
                        bg0_load_hcnt <= flip ? ((hcnt - 9'd16) - bg0_hofs) : ((hcnt + 9'd16) - bg0_hofs);
                        bg1_load_hcnt <= flip ? ((hcnt - 9'd16) - bg1_hofs) : ((hcnt + 9'd16) - bg1_hofs);
                        fg0_load_hcnt <= flip ? ((hcnt - 9'd16) - fg0_x[8:0]) : ((hcnt + 9'd16) - fg0_x[8:0]);
                    end

                    default: begin
                    end
                endcase
            end
        end // ce_pixel

        if (rom_req == rom_ack) begin
            if (rom_req_ch == 1) begin
                bg0_load <= 1;
                rom_req_ch <= 0;
            end else if (rom_req_ch == 2) begin
                bg1_load <= 1;
                rom_req_ch <= 0;
            end else begin
                if (bg0_rom_req) begin
                    rom_address <= bg0_rom_address;
                    rom_req <= ~rom_req;
                    rom_req_ch <= 1;
                    bg0_rom_req <= 0;
                end else if (bg1_rom_req) begin
                    rom_address <= bg1_rom_address;
                    rom_req <= ~rom_req;
                    rom_req_ch <= 2;
                    bg1_rom_req <= 0;
                end
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

