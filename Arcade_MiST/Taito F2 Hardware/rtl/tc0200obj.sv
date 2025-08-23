module TC0200OBJ #(parameter SS_IDX=-1) (
    input clk,

    input ce_13m,
    input ce_pixel,

    input pause,
    output reg paused,

    output [14:0] RA,
    input [15:0] Din,
    output reg [15:0] Dout,

    input RESET,
    output reg ERCSn, // TODO - what generates this
    output reg EBUSY,
    output reg RDWEn,

    output reg EDMAn, // TODO - is dma started by vblank?

    output [11:0] DOT,

    input EXHBLn,
    input EXVBLn,

    output reg HSYNCn,
    output reg VSYNCn,
    output reg HBLn,
    output reg VBLn,

    // Make the sync more compatible with consumer CRTs
    input sync_fix,

    // bank switching and extension support
    output reg code_modify_req,
    output [12:0] code_original,
    input [18:0] code_modified,

    input [12:0] debug_idx,

    ddr_if.to_host ddr,

    ssbus_if.slave ssbus
);

ddr_if ddr_obj(), ddr_fb();

ddr_mux ddr_mux(
    .clk,
    .x(ddr),
    .a(ddr_obj),
    .b(ddr_fb)
);


// 256 cycles per sprite (13mhz)
// 213760 cycles total, 835 sprites
// 222176 cycles entire frame


// DDR Framebuffer Layout
// 512x512x16bpp x 2
// 10 bits of column address
// 8 bits of row address
// 1 bit of framebuffer address
// B_RRRRRRRR_CCCCCCCCCC
// 0x00000 - 0x7ffff
//

// horizontal video: htotal=424, hfp=20, hs=64, vbp=20
// vertical video:   vtotal=262, vfp=16, vs=6,  vbp=16

reg [15:0] work_buffer[8];
wire [12:0] inst_tile_code       =  work_buffer[0][12:0];
wire [7:0]  inst_x_zoom          =  work_buffer[1][7:0];
wire [7:0]  inst_y_zoom          =  work_buffer[1][15:8];
wire [11:0] inst_x_coord         =  work_buffer[6][11:0];
wire        inst_latch_extra     =  work_buffer[6][12];
wire        inst_latch_master    =  work_buffer[6][13];
wire        inst_use_extra       = ~work_buffer[6][14];
wire        inst_use_scroll      = ~work_buffer[6][15];
wire [11:0] inst_y_coord         =  work_buffer[7][11:0];
wire        inst_is_cmd          =  work_buffer[7][15];
wire [2:0]  inst_unk1            =  work_buffer[7][14:12];
wire [7:0]  inst_color           =  work_buffer[4][7:0];
wire        inst_x_flip          =  work_buffer[4][8];
wire        inst_y_flip          =  work_buffer[4][9];
wire        inst_reuse_color     =  work_buffer[4][10];
wire        inst_next_seq        =  work_buffer[4][11];
wire        inst_use_latch_y     =  work_buffer[4][12];
wire        inst_inc_y           =  work_buffer[4][13];
wire        inst_use_latch_x     =  work_buffer[4][14];
wire        inst_inc_x           =  work_buffer[4][15];
wire [15:0] inst_cmd             =  work_buffer[5];
reg         inst_debug;

assign code_original = inst_tile_code;
wire [18:0] tile_code = code_modified;

reg [15:0] cmd_ctrl;
wire ctrl_disable = cmd_ctrl[12];
wire ctrl_flipscreen = cmd_ctrl[13];
wire ctrl_6bpp = cmd_ctrl[8];
wire ctrl_a14 = cmd_ctrl[0];
wire ctrl_a13 = cmd_ctrl[10];

reg [12:0] obj_addr;

reg is_cmd;
// device always reads from the lowest bank when access the cmd data from the
// first instance
reg zero_bank;
assign RA = zero_bank ? { 2'b00, obj_addr } : {ctrl_a14, ctrl_a13, obj_addr};


typedef enum
{
    ST_IDLE = 0,
    ST_PAUSE_INIT,
    ST_PAUSE,
    ST_DMA_INIT,
    ST_PRE_DMA,
    ST_DMA,
    ST_DRAW_INIT,
    ST_READ_START,
    ST_PRE_READ,
    ST_READ,
    ST_EVAL0,
    ST_EVAL1,
    ST_EVAL2,
    ST_EVAL_WAIT,
    ST_EVAL3,
    ST_CHECK_BOUNDS,
    ST_READ_TILE,
    ST_READ_TILE_WAIT,
    ST_DRAW_TILE1,
    ST_DRAW_TILE2,
    ST_DRAW_TILE3,
    ST_DRAW_END
} draw_state_t;

draw_state_t obj_state = ST_IDLE;


reg [12:0] dma_cycle;
wire [12:0] dma_addr = {dma_cycle[12:3], 3'b000};

reg scanout_buffer = 0;
wire draw_buffer = ~scanout_buffer;

wire fb_dirty_scan, fb_dirty_is_set;
reg fb_dirty_scan_clear;
reg [15:0] fb_dirty_scan_addr;
wire [15:0] fb_dirty_draw_addr = { draw_buffer, shifter_addr };

reg fb_dirty_set;
reg [15:0] fb_dirty_set_addr;

dualport_ram_unreg #(.WIDTH(1), .WIDTHAD(16)) fb_dirty_buffer
(
    // Port A
    .clock_a(clk),
    .wren_a(fb_dirty_scan_clear),
    .address_a(fb_dirty_scan_addr),
    .data_a(0),
    .q_a(fb_dirty_scan),

    // Port B
    .clock_b(clk),
    .wren_b(fb_dirty_set),
    .address_b(fb_dirty_set ? fb_dirty_set_addr : fb_dirty_draw_addr),
    .data_b(1),
    .q_b(fb_dirty_is_set)
);

reg [11:0] master_x, master_y, extra_x, extra_y;
reg [11:0] latch_x, latch_y;
reg [7:0]  latch_color;
reg prev_vbl_n, vbl_edge;

reg [8:0] zoom_dx, zoom_dy;

reg [31:0] draw_addr;
reg [3:0] draw_row;
reg [1:0] draw_col;

reg [(6 * 16)-1:0] tile_row[16];
reg [4:0] tile_burst;

wire [7:0] read_tile_burstcnt;
wire read_tile_complete;
wire [63:0] shifter_data;
wire [7:0] shifter_be;
wire [14:0] shifter_addr;
wire shifter_ready, shifter_done;
reg shifter_read;

wire [11:0] flip_x_origin /* verilator public_flat */ = 496;
wire [11:0] flip_y_origin /* verilator public_flat */ = 240;

tc0200obj_data_shifter shifter(
    .clk,
    .reset(obj_state == ST_EVAL2),
    .bpp6(ctrl_6bpp),
    .burstcnt(read_tile_burstcnt),
    .load_complete(read_tile_complete),

    .x(ctrl_flipscreen ? (flip_x_origin - latch_x) : latch_x),
    .y(ctrl_flipscreen ? (flip_y_origin - latch_y) : latch_y),
    .flip_x(inst_x_flip ^ ctrl_flipscreen),
    .flip_y(inst_y_flip ^ ctrl_flipscreen),
    .color(latch_color),

    .row_valid,
    .row_index,

    .col_valid,
    .col_index,


    .out_data(shifter_data),
    .out_be(shifter_be),
    .out_ready(shifter_ready),
    .out_read(shifter_read),
    .out_addr(shifter_addr),
    .out_done(shifter_done),

    .din(inst_debug ? 64'hffffffffffffffff : ddr_obj.rdata),
    .load(ddr_obj.rdata_ready && (obj_state == ST_READ_TILE_WAIT))
);

reg row_calc_start, col_calc_start;
wire row_calc_ready, col_calc_ready;
wire [4:0] row_count, col_count;
wire [15:0] row_valid, col_valid;
wire [(16 * 4)-1:0] row_index, col_index;

tc0200obj_zoom_calc row_calc(
    .clk,
    .start(row_calc_start),
    .cont(inst_inc_y),
    .ready(row_calc_ready),
    .delta(zoom_dy),
    .count(row_count),
    .valid(row_valid),
    .indices(row_index)
);

tc0200obj_zoom_calc column_calc(
    .clk,
    .start(col_calc_start),
    .cont(inst_inc_x),
    .ready(col_calc_ready),
    .delta(zoom_dx),
    .count(col_count),
    .valid(col_valid),
    .indices(col_index)
);


reg [17:0] read_pacing;
reg [4:0] busy_count;
reg test_pause = 0;
    
reg [11:0] base_x, base_y;
reg prev_seq;
reg is_seq_start;

always @(posedge clk) begin
    ddr_obj.acquire <= 0;
    code_modify_req <= 0;
    row_calc_start <= 0;
    col_calc_start <= 0;
    
    paused <= 0;

    prev_vbl_n <= VBLn;
    if (prev_vbl_n & ~VBLn) begin
        vbl_edge <= 1;
    end

    if (ce_13m) begin
        read_pacing <= read_pacing + 1;
        busy_count <= busy_count + 1;
    end

    case(obj_state)
        ST_IDLE: begin
            ddr_obj.read <= 0;
            ddr_obj.write <= 0;

            EBUSY <= 0;
            ERCSn <= 1;
            RDWEn <= 1;
            EDMAn <= 1;

            if (!RESET & vbl_edge) begin
                vbl_edge <= 0;
                if (pause)
                    obj_state <= ST_PAUSE_INIT;
                else
                    obj_state <= ST_DMA_INIT;
            end
        end

        ST_PAUSE_INIT: begin
            scanout_buffer <= ~scanout_buffer;
            obj_state <= ST_PAUSE;
        end

        ST_PAUSE: begin
            paused <= 1;
            if (vbl_edge) begin
                vbl_edge <= 0;
                if (~pause) begin
                    scanout_buffer <= ~scanout_buffer;
                    obj_state <= ST_DMA_INIT;
                end
            end
        end


        ST_DMA_INIT: if (ce_13m) begin
            EBUSY <= 1;
            dma_cycle <= 0;
            scanout_buffer <= ~scanout_buffer;
            busy_count <= 0;
            obj_state <= ST_PRE_DMA;

            // FIXME, verify that this resets
            extra_x <= 0;
            extra_y <= 0;
        end

        ST_PRE_DMA: if (ce_13m) begin
            if (busy_count == 3) begin
                obj_state <= ST_DMA;
                EDMAn <= 0;
            end
        end

        ST_DMA: if (ce_13m) begin
            dma_cycle <= dma_cycle + 1;
            ERCSn <= 0;

            if (dma_cycle == 8191) begin
                EBUSY <= 0;
                RDWEn <= 1;
                ERCSn <= 1;
                EDMAn <= 1;
                obj_state <= ST_DRAW_INIT;
            end

            unique case (dma_cycle[2:0])
                0: begin
                    obj_addr <= dma_addr + 13'd2;
                end
                1: work_buffer[1] <= Din;
                2: begin
                    obj_addr <= dma_addr + 13'd3;
                end
                3: work_buffer[2] <= Din;
                4: begin
                    obj_addr <= dma_addr + 13'd6;
                    Dout <= work_buffer[1];
                    RDWEn <= 0;
                end
                5: RDWEn <= 1;
                6: begin
                    obj_addr <= dma_addr + 13'd7;
                    Dout <= work_buffer[2];
                    RDWEn <= 0;
                end
                7: RDWEn <= 1;
            endcase

        end
        ST_DRAW_INIT: if (ce_13m) begin
            read_pacing <= 0;
            obj_addr <= 0;
            RDWEn <= 1;
            obj_state <= ST_READ_START;
        end

        ST_READ_START: if (ce_13m) begin
            if (obj_addr[12:3] == 835 || vbl_edge) begin
                obj_state <= ST_IDLE;
            end else begin
                if (read_pacing[17:8] >= obj_addr[12:3]) begin
                    EBUSY <= 1;
                    obj_state <= ST_PRE_READ;
                    busy_count <= 0;
                    inst_debug <= {3'b0, obj_addr[12:3]} == debug_idx;
                end
            end
        end

        ST_PRE_READ: if (ce_13m) begin
            if (busy_count == 13) begin
                obj_state <= ST_READ;
                ERCSn <= 0;
            end
        end

        ST_READ: if (ce_13m) begin
            obj_addr <= obj_addr + 13'd1;
            work_buffer[obj_addr[2:0]] <= Din;

            case(obj_addr[2:0])
                3'd3: begin
                    if (Din[15]) begin // is_cmd
                        zero_bank <= ~Din[0];
                        is_cmd <= 1;
                    end
                end

                3'd5: begin
                    if (is_cmd) begin
                        cmd_ctrl <= Din;
                        zero_bank <= 0;
                        is_cmd <= 0;
                    end
                    code_modify_req <= 1;
                end

                3'd7: begin
                    obj_state <= ST_EVAL0;
                    busy_count <= 0;
                    ERCSn <= 1;
                end

                default: begin
                end

            endcase
        end

        ST_EVAL0: begin
            is_seq_start <= (inst_next_seq & ~prev_seq) | (~inst_next_seq & ~prev_seq);
            prev_seq <= inst_next_seq;
            obj_state <= ST_EVAL1;
        end

        ST_EVAL1: begin
            if (is_seq_start) begin
                base_x <= inst_x_coord + (inst_use_scroll ? ( master_x + (inst_use_extra ? extra_x : 12'd0) ) : 12'd0);
                base_y <= inst_y_coord + (inst_use_scroll ? ( master_y + (inst_use_extra ? extra_y : 12'd0) ) : 12'd0);
            end

            // FIXME confirm hardware behavior when only latch bit is set
            // liquidk sometimes does this and mame ignores it
            if (inst_latch_extra & ~inst_use_extra) begin
                extra_x <= inst_x_coord;
                extra_y <= inst_y_coord;
            end

            if (inst_latch_master & ~inst_use_scroll) begin
                master_x <= inst_x_coord;
                master_y <= inst_y_coord;
            end

            obj_state <= ST_EVAL2;
        end

        ST_EVAL2: begin
            if (is_seq_start) begin
                zoom_dx <= 9'h100 - { 1'b0, inst_x_zoom };
                zoom_dy <= 9'h100 - { 1'b0, inst_y_zoom };
                row_calc_start <= 1;
                col_calc_start <= 1;
            end else begin
                row_calc_start <= 1;
                col_calc_start <= inst_inc_x;
            end

            // We are intentionally using the previous col_count and row_count
            if (inst_use_latch_y) begin
                latch_y <= latch_y + {7'd0, row_count};
            end else begin
                latch_y <= base_y;
            end
            if (inst_use_latch_x | inst_inc_x) begin
                latch_x <= latch_x + {7'd0, inst_inc_x ? col_count : 5'd0};
            end else begin
                latch_x <= base_x + {7'd0, inst_inc_x ? col_count : 5'd0};
            end

            if (~inst_reuse_color) begin
                latch_color <= inst_color;
            end

            obj_state <= ST_EVAL_WAIT;
        end

        ST_EVAL_WAIT: if (ce_13m) begin
            if (busy_count == 12) begin
                obj_state <= ST_EVAL3;
                EBUSY <= 0;
            end
        end

        ST_EVAL3: begin
            if (tile_code == 0 || ctrl_disable) begin
                obj_state <= ST_READ_START;
            end else begin
                obj_state <= ST_CHECK_BOUNDS;
            end
        end

        ST_CHECK_BOUNDS: begin
            draw_addr <= OBJ_FB_DDR_BASE + { 13'd0, draw_buffer, latch_y[7:0], latch_x[8:2], 3'b000 };
            if (latch_x > 480) begin
                obj_state <= ST_READ_START;
            end else if (latch_y > 240) begin
                obj_state <= ST_READ_START;
            end else begin
                obj_state <= ST_READ_TILE;
            end
        end

        ST_READ_TILE: begin
            ddr_obj.acquire <= 1;
            if (~ddr_obj.busy) begin
                ddr_obj.read <= 1;
                ddr_obj.burstcnt <= read_tile_burstcnt;
                if (ctrl_6bpp)
                    ddr_obj.addr <= OBJ_DATA_DDR_BASE + {5'd0, tile_code, 8'd0};
                else
                    ddr_obj.addr <= OBJ_DATA_DDR_BASE + {6'd0, tile_code, 7'd0};
                tile_burst <= 0;
                obj_state <= ST_READ_TILE_WAIT;
            end
        end

        ST_READ_TILE_WAIT: begin
            if (read_tile_complete) begin
                obj_state <= ST_DRAW_TILE1;
                draw_row <= 0;
                draw_col <= 0;
            end else begin
                ddr_obj.acquire <= 1;
                if (~ddr_obj.busy) begin
                    ddr_obj.read <= 0;
                    // shifter module handles reads
                end
            end
        end

        // TODO
        // Possible to squeeze this down to less cycles. Currently this work
        // is spread out across three cycles so that we can read from the
        // dirty buffer and write to it. The writes could be deferred which
        // would remove a cycle. The DDR writes could also be deferred and
        // batched, resulting in less time with the DDR bus acquired.
        ST_DRAW_TILE1: begin
            ddr_obj.acquire <= 1;
            if (shifter_ready) begin
                // one cycle delay waiting for fb_dirty_is_set to become valid
                obj_state <= ST_DRAW_TILE2;
            end
        end

        ST_DRAW_TILE2: begin
            ddr_obj.acquire <= 1;
            if (~ddr_obj.busy) begin
                ddr_obj.addr <= OBJ_FB_DDR_BASE + {13'd0, draw_buffer, shifter_addr, 3'd0 };
                ddr_obj.burstcnt <= 1;
                ddr_obj.wdata <= shifter_data;
                ddr_obj.write <= 1;
                ddr_obj.byteenable <= fb_dirty_is_set ? shifter_be : 8'hff;

                fb_dirty_set_addr <= fb_dirty_draw_addr;
                fb_dirty_set <= 1;
                if (shifter_done)
                  obj_state <= ST_DRAW_END;
                else begin
                  obj_state <= ST_DRAW_TILE3;
                  shifter_read <= 1;
                end
            end
        end

        ST_DRAW_TILE3: begin
            ddr_obj.acquire <= 1;
            fb_dirty_set <= 0;
            shifter_read <= 0;
            if (~ddr_obj.busy ) begin
                ddr_obj.write <= 0;
                obj_state <= ST_DRAW_TILE1;
            end
        end

        ST_DRAW_END: begin
            ddr_obj.acquire <= 1;
            fb_dirty_set <= 0;
            if (~ddr_obj.busy ) begin
                ddr_obj.write <= 0;
                obj_state <= ST_READ_START;
            end
        end

        default: begin
            obj_state <= ST_IDLE;
        end
    endcase
end


// Scan out
//

wire [9:0] H_OFS = 90;
wire [9:0] H_START = 0 + H_OFS;
wire [9:0] H_END = 424 + H_OFS - 1;
wire [9:0] HS_START = 340 + H_OFS;
wire [9:0] HS_END = sync_fix ? (372 + H_OFS - 1) : (404 + H_OFS - 1);
wire [9:0] HB_START = 320 + H_OFS;
wire [9:0] HB_END = 8 + H_OFS;

wire [7:0] VS_START = 240;
wire [7:0] VS_END = sync_fix ? (244 - 1) : (246 - 1);
wire [7:0] VB_START = 224;
wire [7:0] VB_END = 255;
wire [7:0] V_EXVBL_RESET = 250; // from signal trace


reg [9:0] hcnt;
reg [7:0] vcnt;
reg [6:0] burstidx;

reg line_buffer_write;
reg [7:0] line_buffer_write_addr;
reg [63:0] line_buffer_wdata;

dualport_ram_unreg #(.WIDTH(64), .WIDTHAD(8)) line_buffer
(
    // Port A
    .clock_a(clk),
    .wren_a(line_buffer_write),
    .address_a(line_buffer_write_addr),
    .data_a(fb_dirty_scan ? line_buffer_wdata : 64'd0),
    .q_a(),

    // Port B
    .clock_b(clk),
    .wren_b(0),
    .address_b({~vcnt[0], hcnt[8:2]}),
    .data_b(0),
    .q_b(lb_dout)
);


wire [63:0] lb_dout;

reg ex_vbl_n_prev, vbl_n_prev;
reg ex_vbl_end, vbl_start;
reg scanout_active;
reg scanout_newline;

typedef enum { SCAN_IDLE, SCAN_START_READ, SCAN_WAIT_READ } scan_state_t;

scan_state_t scan_state = SCAN_IDLE;

logic [11:0] out_color;
always_comb begin
    unique case (hcnt[1:0])
        0: out_color = lb_dout[11:0];
        1: out_color = lb_dout[27:16];
        2: out_color = lb_dout[43:32];
        3: out_color = lb_dout[59:48];
    endcase

    if (ctrl_6bpp) begin
        DOT = |out_color[5:0] ? out_color : 12'd0;
    end else begin
        DOT = |out_color[3:0] ? out_color : 12'd0;
    end
end

assign ddr_fb.write = 0;
assign ddr_fb.wdata = 0;
assign ddr_fb.byteenable = 8'hFF;

reg ex_hbl_n_prev;
always_ff @(posedge clk) begin
    if (ce_pixel) begin
        ex_vbl_n_prev <= EXVBLn;
        ex_hbl_n_prev <= EXHBLn;
        vbl_n_prev <= VBLn;

        if (EXVBLn & ~ex_vbl_n_prev) begin
            ex_vbl_end <= 1;
        end
        if (~VBLn & vbl_n_prev) begin
            //vbl_start <= 1;
            scanout_active <= 0;
        end

        if (ex_hbl_n_prev & ~EXHBLn) begin
            hcnt <= HB_START;
        end else begin
            hcnt <= hcnt + 1;
            if (hcnt == H_END) begin
                hcnt <= H_START;
                vcnt <= vcnt + 1;
                scanout_newline <= 1;

                if (ex_vbl_end) begin
                    ex_vbl_end <= 0;
                    scanout_active <= 1;
                    vcnt <= V_EXVBL_RESET;
                end
            end
        end

        HSYNCn <= ~(hcnt >= HS_START && hcnt <= HS_END);
        HBLn <= ~(hcnt >= HB_START || hcnt <= HB_END);
        VSYNCn <= ~(vcnt >= VS_START && vcnt <= VS_END);
        VBLn <= ~(vcnt >= VB_START); // && vcnt <= VB_END);
    end

    fb_dirty_scan_clear <= 0;
    line_buffer_write <= 0;

    unique case(scan_state)
        SCAN_IDLE: begin
            ddr_fb.acquire <= 0;
            ddr_fb.read <= 0;
            fb_dirty_scan_addr <= { fb_dirty_scan_addr[15:7], hcnt[6:0] };
            fb_dirty_scan_clear <= scanout_active & ~paused;

            if (scanout_newline) begin
                scan_state <= SCAN_START_READ;
                scanout_newline <= 0;
            end
        end

        SCAN_START_READ: begin
            ddr_fb.acquire <= 1;
            if (~ddr_fb.busy) begin
                ddr_fb.read <= 1;
                ddr_fb.burstcnt <= 128;
                ddr_fb.addr <= OBJ_FB_DDR_BASE + { 13'd0, scanout_buffer, vcnt + 8'd17, 10'd0 };
                fb_dirty_scan_addr <= { scanout_buffer, vcnt + 8'd17, 7'd0 };
                burstidx <= 0;
                scan_state <= SCAN_WAIT_READ;
            end
        end

        SCAN_WAIT_READ: begin
            if (~ddr_fb.busy) begin
                ddr_fb.read <= 0;
                if (ddr_fb.rdata_ready) begin
                    line_buffer_write <= 1;
                    line_buffer_wdata <= ddr_fb.rdata;
                    line_buffer_write_addr <= {vcnt[0], burstidx};
                    burstidx <= burstidx + 1;

                    fb_dirty_scan_addr <= fb_dirty_scan_addr + 1;

                    if (burstidx == 127) begin
                        scan_state <= SCAN_IDLE;
                        fb_dirty_scan_addr <= { scanout_buffer, vcnt + 8'd17, 7'd0 }; // reset
                    end
                end
            end
        end
    endcase
    if(RESET) scan_state <= SCAN_IDLE;
end

endmodule


/*
        Sprite format:
        0000: ---xxxxxxxxxxxxx tile code (0x0000 - 0x1fff)
        0002: xxxxxxxx-------- sprite y-zoom level
              --------xxxxxxxx sprite x-zoom level

              0x00 - non scaled = 100%
              0x80 - scaled to 50%
              0xc0 - scaled to 25%
              0xe0 - scaled to 12.5%
              0xff - scaled to zero pixels size (off)

        [this zoom scale may not be 100% correct, see Gunfront flame screen]

        0004: ----xxxxxxxxxxxx x-coordinate (-0x800 to 0x07ff)
              ---x------------ latch extra scroll
              --x------------- latch master scroll
              -x-------------- don't use extra scroll compensation
              x--------------- absolute screen coordinates (ignore all sprite scrolls)
              xxxx------------ the typical use of the above is therefore
                               1010 = set master scroll
                               0101 = set extra scroll
        0006: ----xxxxxxxxxxxx y-coordinate (-0x800 to 0x07ff)
              x--------------- marks special control commands (used in conjunction with 00a)
                               If the special command flag is set:
              ---------------x related to sprite ram bank
              ---x------------ unknown (deadconx, maybe others)
              --x------------- unknown, some games (growl, gunfront) set it to 1 when
                               screen is flipped
        0008: --------xxxxxxxx color (0x00 - 0xff)
              -------x-------- flipx
              ------x--------- flipy
              -----x---------- if set, use latched color, else use & latch specified one
              ----x----------- if set, next sprite entry is part of sequence
              ---x------------ if clear, use latched y coordinate, else use current y
              --x------------- if set, y += 16
              -x-------------- if clear, use latched x coordinate, else use current x
              x--------------- if set, x += 16
        000a: only valid when the special command bit in 006 is set
              ---------------x related to sprite ram bank. I think this is the one causing
                               the bank switch, implementing it this way all games seem
                               to properly bank switch except for footchmp which uses the
                               bit in byte 006 instead.
              ------------x--- unknown; some games toggle it before updating sprite ram.
              ------xx-------- unknown (finalb)
              -----x---------- unknown (mjnquest)
              ---x------------ disable the following sprites until another marker with
                               this bit clear is found
              --x------------- flip screen

        000b - 000f : unused
*/

module tc0200obj_zoom_calc(
    input         clk,

    input         start,
    input         cont,
    output reg    ready,
    input  [8:0]  delta,

    output reg [4:0]  count,
    output reg [15:0] valid,
    output reg [(16*4)-1:0] indices
);

reg [8:0] accum;
reg [3:0] index;

always @(posedge clk) begin
    bit [8:0] next_accum;
    if (start) begin
        ready <= 0;
        if (~cont) accum <= 0;
        index <= 0;
        count <= 0;
        valid <= 0;
    end else if (~ready) begin
        index <= index + 1;
        next_accum = accum + delta;
        accum <= next_accum;
        if (next_accum[8] != accum[8]) begin
            valid[count[3:0]] <= 1;
            indices[count[3:0] * 4 +: 4] <= index;
            count <= count + 1;
        end

        if (index == 15) begin
            ready <= 1;
        end
    end
end

endmodule

module tc0200obj_data_shifter(
    input clk,

    input reset,

    input bpp6,
    output [7:0] burstcnt,
    output reg load_complete,

    input [63:0] din,
    input load,

    input [11:0] x,
    input [11:0] y,
    input        flip_x,
    input        flip_y,
    input [7:0]  color,

    input [15:0] row_valid,
    input [(16*4)-1:0] row_index,

    input [15:0] col_valid,
    input [(16*4)-1:0] col_index,

    input             out_read,
    output reg [63:0] out_data,
    output reg  [7:0] out_be,
    output reg        out_ready,
    output reg [14:0] out_addr,
    output reg        out_done
);

function bit [(6 * 4)-1:0] decode_6bpp_rom(input [31:0] d);
    bit [(6 * 4)-1:0] r;
    r[5:0]   = {d[17:16], d[11:8]};
    r[11:6]  = {d[19:18], d[15:12]};
    r[17:12] = {d[21:20], d[3:0]};
    r[23:18] = {d[23:22], d[7:4]};
    return r;
endfunction

function bit [(6 * 4)-1:0] decode_4bpp_rom(input [15:0] d);
    bit [(6 * 4)-1:0] r;
    r[5:0]   = {2'b00, d[3:0]};
    r[11:6]  = {2'b00, d[7:4]};
    r[17:12] = {2'b00, d[11:8]};
    r[23:18] = {2'b00, d[15:12]};
    return r;
endfunction

assign burstcnt = bpp6 ? 8'd32 : 8'd16;
reg [7:0] burstidx;

reg [5:0] pixel[16 * 16];
reg [5:0] row_data[20];

wire [7:0] y_addr = y[7:0];
wire [6:0] x_addr = x[8:2];
wire [1:0] x_shift = x[1:0];

reg [3:0] row;
reg [2:0] col;

task prepare_row(bit [3:0] r);
    bit [4:0] i;
    bit [3:0] ri, ci;

    for( i = 0; i < 20; i = i + 1 ) begin
        row_data[i] <= 6'd0;
    end

    if (row_valid[r]) begin
        if (flip_y) begin
            ri = ~row_index[ r * 4 +: 4 ]; // FIXME - this is a mess
        end else begin
            ri = row_index[ r * 4 +: 4 ]; // FIXME - this is a mess
        end

        for( i = 0; i < 16; i = i + 1 ) begin
            if (col_valid[i[3:0]]) begin
                if (flip_x) begin
                    ci = ~col_index[ i[3:0] * 4 +: 4 ]; // FIXME - this is a mess
                end else begin
                    ci = col_index[ i[3:0] * 4 +: 4 ]; // FIXME - this is a mess
                end
                row_data[i + {3'b0, x_shift}] <= pixel[{ri, ci}];
            end
        end
    end
endtask

task prepare_draw();
    int i;
    out_addr <= { y_addr, x_addr } + { 4'd0, row, 4'd0, col };
    out_be <= 8'd0;
    out_data <= 64'd0;
    out_ready <= 1;

    if (bpp6) begin
        out_data[15:0] <=  { 4'd0, color[7:2], row_data[0] };
        out_data[31:16] <= { 4'd0, color[7:2], row_data[1] };
        out_data[47:32] <= { 4'd0, color[7:2], row_data[2] };
        out_data[63:48] <= { 4'd0, color[7:2], row_data[3] };
    end else begin
        out_data[15:0] <=  { 4'd0, color[7:0], row_data[0][3:0] };
        out_data[31:16] <= { 4'd0, color[7:0], row_data[1][3:0] };
        out_data[47:32] <= { 4'd0, color[7:0], row_data[2][3:0] };
        out_data[63:48] <= { 4'd0, color[7:0], row_data[3][3:0] };
    end

    out_be[1:0] <= {2{|row_data[0]}};
    out_be[3:2] <= {2{|row_data[1]}};
    out_be[5:4] <= {2{|row_data[2]}};
    out_be[7:6] <= {2{|row_data[3]}};

    for( i = 0; i < 16; i = i + 1 ) begin
        row_data[i] <= row_data[i+4];
    end

    col <= col + 1;
    if (col == 4) begin
        prepare_row( row + 1 );
        col <= 0;
        row <= row + 1;
        if (~row_valid[row] || row == 15) begin
            out_done <= 1;
        end
    end
endtask

reg need_first_row;
always_ff @(posedge clk) begin
    if (reset) begin
        burstidx <= 0;
        load_complete <= 0;
        out_done <= 0;
        out_ready <= 0;
        row <= 0;
        col <= 0;
    end else begin
        if (load) begin
            if (bpp6) begin
                bit [(6 * 4)-1:0] d;
                d = decode_6bpp_rom(din[31:0]);
                pixel[(burstidx * 8) + 0] <= d[(6 * 0) +: 6];
                pixel[(burstidx * 8) + 1] <= d[(6 * 1) +: 6];
                pixel[(burstidx * 8) + 2] <= d[(6 * 2) +: 6];
                pixel[(burstidx * 8) + 3] <= d[(6 * 3) +: 6];
                d = decode_6bpp_rom(din[63:32]);
                pixel[(burstidx * 8) + 4] <= d[(6 * 0) +: 6];
                pixel[(burstidx * 8) + 5] <= d[(6 * 1) +: 6];
                pixel[(burstidx * 8) + 6] <= d[(6 * 2) +: 6];
                pixel[(burstidx * 8) + 7] <= d[(6 * 3) +: 6];
            end else begin
                bit [(6 * 4)-1:0] d;
                d = decode_4bpp_rom(din[15:0]);
                pixel[(burstidx * 16) + 0] <= d[(6 * 0) +: 6];
                pixel[(burstidx * 16) + 1] <= d[(6 * 1) +: 6];
                pixel[(burstidx * 16) + 2] <= d[(6 * 2) +: 6];
                pixel[(burstidx * 16) + 3] <= d[(6 * 3) +: 6];
                d = decode_4bpp_rom(din[31:16]);
                pixel[(burstidx * 16) + 4] <= d[(6 * 0) +: 6];
                pixel[(burstidx * 16) + 5] <= d[(6 * 1) +: 6];
                pixel[(burstidx * 16) + 6] <= d[(6 * 2) +: 6];
                pixel[(burstidx * 16) + 7] <= d[(6 * 3) +: 6];
                d = decode_4bpp_rom(din[47:32]);
                pixel[(burstidx * 16) + 8] <= d[(6 * 0) +: 6];
                pixel[(burstidx * 16) + 9] <= d[(6 * 1) +: 6];
                pixel[(burstidx * 16) + 10] <= d[(6 * 2) +: 6];
                pixel[(burstidx * 16) + 11] <= d[(6 * 3) +: 6];
                d = decode_4bpp_rom(din[63:48]);
                pixel[(burstidx * 16) + 12] <= d[(6 * 0) +: 6];
                pixel[(burstidx * 16) + 13] <= d[(6 * 1) +: 6];
                pixel[(burstidx * 16) + 14] <= d[(6 * 2) +: 6];
                pixel[(burstidx * 16) + 15] <= d[(6 * 3) +: 6];
            end

            burstidx <= burstidx + 1;
            if (burstidx == (burstcnt - 1)) begin
                load_complete <= 1;
                need_first_row <= 1;
            end
        end

        if (load_complete & need_first_row) begin
            prepare_row(0);
            need_first_row <= 0;
        end else if (load_complete & ~out_ready) begin
            prepare_draw();
        end else if (out_read & ~out_done) begin
            prepare_draw();
        end
    end
end

endmodule

