import system_consts::*;

module game_board_config(
    input clk,
    input reset,
    input game_t game,

    output reg       cfg_360pri,
    output reg       cfg_360pri_high,
    output reg       cfg_110pcr,
    output reg       cfg_260dar,
    output reg       cfg_260dar_acc,
    output reg       cfg_190fmc,
    output reg [1:0] cfg_obj_extender,
    output reg       cfg_io_swap,
    output reg       cfg_tmp82c265,
    output reg       cfg_te7750,
    output reg       cfg_280grd,
    output reg       cfg_430grw,
    output reg       cfg_480scp,
    output reg       cfg_100scn,
    output reg       cfg_bpp15,
    output reg       cfg_bppmix,

    output reg [15:0] cfg_addr_rom,
    output reg [15:0] cfg_addr_rom1,
    output reg [15:0] cfg_addr_extra_rom,
    output reg [15:0] cfg_addr_work_ram,
    output reg [15:0] cfg_addr_screen0,
    output reg [15:0] cfg_addr_screen1,
    output reg [15:0] cfg_addr_obj,
    output reg [15:0] cfg_addr_color,
    output reg [15:0] cfg_addr_io0,
    output reg [15:0] cfg_addr_io1,
    output reg [15:0] cfg_addr_sound,
    output reg [15:0] cfg_addr_extension,
    output reg [15:0] cfg_addr_priority,
    output reg [15:0] cfg_addr_roz,
    output reg [15:0] cfg_addr_cchip,

    output reg  [8:0] cfg_hofs_200obj,
    output reg  [8:0] cfg_vofs_200obj,
    output reg  [8:0] cfg_hofs_480scp,
    output reg  [8:0] cfg_vofs_480scp,
    output reg  [8:0] cfg_hofs_100scn0,
    output reg  [8:0] cfg_vofs_100scn0,
    output reg  [8:0] cfg_hofs_100scn1,
    output reg  [8:0] cfg_vofs_100scn1,
    output reg  [8:0] cfg_hofs_430grw,
    output reg  [8:0] cfg_vofs_430grw
);

// register these values to help with timing
//
always @(posedge clk) begin
    bit [16:0] c;

    case(game)
        //                      3  2 1 1  O 8 T I 2 4 4 1 B B
        //                      6  6 1 9  B 2 E O 8 3 8 0 P P
        //                      0  0 1 0  J C 7 S 0 0 0 0 P P
        //                      P  D P F  E 2 7 W G G S S 1 M
        //                      R  A C M  X 6 5 A R R C C 5 I
        //                      I  R R C  T 5 0 P D W P N   X
        GAME_FINALB:   c = 17'b00_00_1_0_00_0_0_0_0_0_0_0_0_0;
        GAME_DONDOKOD: c = 17'b01_01_0_0_00_0_0_0_1_0_0_0_0_0;
        GAME_MEGAB:    c = 17'b01_01_0_0_00_0_0_0_0_0_0_0_1_1;
        GAME_THUNDFOX: c = 17'b11_11_0_0_00_0_0_0_0_0_0_1_0_0;
        GAME_CAMELTRY: c = 17'b01_01_0_0_00_0_0_0_1_0_0_0_0_0;
        GAME_QTORIMON: c = 17'b00_00_1_0_00_0_0_0_0_0_0_0_0_0;
        GAME_LIQUIDK:  c = 17'b01_01_0_0_00_0_0_0_0_0_0_0_1_1;
        GAME_QUIZHQ:   c = 17'b00_00_1_0_00_1_0_0_0_0_0_0_1_1;
        GAME_SSI:      c = 17'b00_01_0_0_00_0_0_0_0_0_0_0_0_0;
        GAME_GUNFRONT: c = 17'b01_01_0_0_00_0_0_1_0_0_0_0_0_0;
        GAME_GROWL:    c = 17'b01_01_0_1_00_1_0_0_0_0_0_0_1_1;
        
        GAME_FOOTCHMP: c = 17'b01_11_0_1_00_0_1_0_0_0_1_0_0_0;
        GAME_KOSHIEN:  c = 17'b11_01_0_0_11_0_0_0_0_0_0_0_1_1;
        GAME_YUYUGOGO: c = 17'b00_01_0_0_01_0_0_0_0_0_0_0_0_0;
        GAME_NINJAK:   c = 17'b01_01_0_1_00_0_1_1_0_0_0_0_0_0;
        GAME_SOLFIGTR: c = 17'b01_01_0_1_00_1_0_0_0_0_0_0_1_1;
        GAME_QZQUEST:  c = 17'b00_01_0_0_00_0_0_0_0_0_0_0_1_0;
        GAME_PULIRULA: c = 17'b11_01_0_0_10_0_0_0_0_1_0_0_1_0;
        GAME_METALB:   c = 17'b01_11_0_0_00_0_0_1_0_0_1_0_1_1;
        GAME_QZCHIKYU: c = 17'b00_01_0_0_00_0_0_0_0_0_0_0_1_0;
        
        GAME_DEADCONX: c = 17'b01_01_0_1_00_0_1_0_0_0_1_0_1_1;
        GAME_DINOREX:  c = 17'b01_01_0_0_01_0_0_0_0_0_0_0_1_1;
        GAME_QJINSEI:  c = 17'b01_01_0_0_01_0_0_0_0_0_0_0_1_1;
        GAME_QCRAYON:  c = 17'b01_01_0_0_01_0_0_0_0_0_0_0_1_1;
        GAME_QCRAYON2: c = 17'b01_01_0_0_01_0_0_0_0_0_0_0_1_1;
        GAME_DRIFTOUT: c = 17'b11_01_0_0_00_0_0_0_0_1_0_0_1_0;
        GAME_DEADCONXJ:c = 17'b01_01_0_1_00_0_1_0_0_0_1_0_1_1;
        GAME_METALBA:  c = 17'b01_11_0_0_00_0_0_1_0_0_1_0_1_1;
        GAME_HTHERO:   c = 17'b01_11_0_1_00_0_1_0_0_0_1_0_0_0;
        default:       c = 17'b00_00_1_0_00_0_0_0_0_0_0_0_0_0;
    endcase

    { cfg_360pri_high, cfg_360pri, cfg_260dar_acc, cfg_260dar, cfg_110pcr, cfg_190fmc, cfg_obj_extender,
        cfg_tmp82c265, cfg_te7750, cfg_io_swap,
        cfg_280grd, cfg_430grw, cfg_480scp, cfg_100scn,
        cfg_bpp15, cfg_bppmix } <= c;
end

always_ff @(posedge clk) begin
    cfg_addr_rom       <= 16'hff00;
    cfg_addr_rom1      <= 16'hff00;
    cfg_addr_extra_rom <= 16'hff00;
    cfg_addr_work_ram  <= 16'hff00;
    cfg_addr_color     <= 16'hff00;
    cfg_addr_io0       <= 16'hff00;
    cfg_addr_io1       <= 16'hff00;
    cfg_addr_sound     <= 16'hff00;
    cfg_addr_screen0   <= 16'hff00;
    cfg_addr_screen1   <= 16'hff00;
    cfg_addr_obj       <= 16'hff00;
    cfg_addr_priority  <= 16'hff00;
    cfg_addr_extension <= 16'hff00;
    cfg_addr_roz       <= 16'hff00;
    cfg_addr_cchip     <= 16'hff00;

    //cfg_addr_cchip     <= 16'b0;
    //cfg_addr_screen02  <= 16'b0;
    //cfg_addr_paddle_input  <= 16'b0;
    //cfg_addr_watchdog      <= 16'b0;
    //cfg_addr_dsw_coin_read <= 16'b0;
    //cfg_addr_mahjong_input <= 16'b0;
    //cfg_addr_gfxbank_sel   <= 16'b0;
    //cfg_addr_spritebank_sel<= 16'b0;
    //cfg_addr_rtc           <= 16'b0;
    //cfg_addr_extra_rom     <= 16'b0;

    case (game)
      GAME_FINALB: begin
        cfg_addr_rom      <= {8'h00, 8'hFC}; // 0x000000 - 0x03FFFF
        cfg_addr_work_ram      <= {8'h10, 8'hFF}; // 0x100000 - 0x10FFFF
        cfg_addr_color  <= {8'h20, 8'hFF}; // 0x200000 - 0x200007 (TC0110PCR)
        cfg_addr_io0       <= {8'h30, 8'hFF}; // 0x300000 - 0x30000F (TC0220IOC)
        cfg_addr_sound    <= {8'h32, 8'hFF}; // 0x320001, 0x320003 (TC0140SYT)
        cfg_addr_screen0  <= {8'h80, 8'hF0}; // 0x800000 - 0x80FFFF (TC0100SCN RAM)
        cfg_addr_obj    <= {8'h90, 8'hFF}; // 0x900000 - 0x90FFFF
      end

      GAME_DONDOKOD: begin
        cfg_addr_rom      <= {8'h00, 8'hF8}; // 0x000000 - 0x07FFFF
        cfg_addr_work_ram      <= {8'h10, 8'hFF}; // 0x100000 - 0x10FFFF
        cfg_addr_color       <= {8'h20, 8'hFF}; // 0x200000 - 0x201FFF (Palette RAM)
        cfg_addr_io0       <= {8'h30, 8'hFF}; // 0x300000 - 0x30000F (TC0220IOC)
        cfg_addr_sound    <= {8'h32, 8'hFF}; // 0x320000, 0x320002 (TC0140SYT)
        cfg_addr_screen0  <= {8'h80, 8'hF0}; // 0x800000 - 0x80FFFF (TC0100SCN RAM)
        cfg_addr_obj    <= {8'h90, 8'hFF}; // 0x900000 - 0x90FFFF
        cfg_addr_roz       <= {8'hA0, 8'hFE}; // 0xA00000 - 0xA01FFF (TC0280GRD RAM)
        cfg_addr_priority <= {8'hB0, 8'hFF}; // 0xB00000 - 0xB0001F (TC0360PRI)
      end

      GAME_MEGAB: begin
        cfg_addr_rom      <= {8'h00, 8'hF8}; // 0x000000 - 0x07FFFF
        cfg_addr_sound    <= {8'h10, 8'hFF}; // 0x100000, 0x100002 (TC0140SYT)
        cfg_addr_io0       <= {8'h12, 8'hFF}; // 0x120000 - 0x12000F (TC0220IOC)
        cfg_addr_cchip     <= {8'h18, 8'hFF}; // 0x180000 - 0x1807FF (C-Chip RAM)
        cfg_addr_work_ram      <= {8'h20, 8'hFF}; // 0x200000 - 0x20FFFF
        cfg_addr_color       <= {8'h30, 8'hFF}; // 0x300000 - 0x301FFF (Palette RAM)
        cfg_addr_priority <= {8'h40, 8'hFF}; // 0x400000 - 0x40001F (TC0360PRI)
        cfg_addr_screen0  <= {8'h60, 8'hF1}; // 0x600000 - 0x60FFFF (TC0100SCN RAM), 0x61xxxx RAM (unused?)
        cfg_addr_obj    <= {8'h80, 8'hFF}; // 0x800000 - 0x80FFFF
      end

      GAME_THUNDFOX: begin
        cfg_addr_rom      <= {8'h00, 8'hF8}; // 0x000000 - 0x07FFFF
        cfg_addr_color       <= {8'h10, 8'hFE}; // 0x100000 - 0x101FFF (Palette RAM)
        cfg_addr_io0       <= {8'h20, 8'hFF}; // 0x200000 - 0x20000F (TC0220IOC)
        cfg_addr_sound    <= {8'h22, 8'hFF}; // 0x220000, 0x220002 (TC0140SYT)
        cfg_addr_work_ram      <= {8'h30, 8'hFF}; // 0x300000 - 0x30FFFF
        cfg_addr_screen0  <= {8'h40, 8'hF0}; // 0x400000 - 0x40FFFF (TC0100SCN[0] RAM)
        cfg_addr_screen1  <= {8'h50, 8'hF0}; // 0x500000 - 0x50FFFF (TC0100SCN[1] RAM)
        cfg_addr_obj    <= {8'h60, 8'hFF}; // 0x600000 - 0x60FFFF
        cfg_addr_priority <= {8'h80, 8'hFF}; // 0x800000 - 0x80001F (TC0360PRI)
      end

      GAME_CAMELTRY: begin // Base map for cameltry, cameltrya, driftoutct
        cfg_addr_rom      <= {8'h00, 8'hFC}; // 0x000000 - 0x03FFFF
        cfg_addr_work_ram      <= {8'h10, 8'hFF}; // 0x100000 - 0x10FFFF
        cfg_addr_color       <= {8'h20, 8'hFF}; // 0x200000 - 0x201FFF (Palette RAM)
        cfg_addr_io0       <= {8'h30, 8'hFF}; // 0x300000 - 0x30000F (TC0220IOC)
        //cfg_addr_paddle_input  <= {8'h30, 8'hFF}; // 0x300018 - 0x30001F - Note: Shares base addr 30 with IO
        cfg_addr_sound    <= {8'h32, 8'hFF}; // 0x320000, 0x320002 (TC0140SYT)
        cfg_addr_screen0  <= {8'h80, 8'hF0}; // 0x800000 - 0x813FFF (TC0100SCN RAM) - Spans 0x80, 0x81
        cfg_addr_obj    <= {8'h90, 8'hFF}; // 0x900000 - 0x90FFFF
        cfg_addr_roz       <= {8'hA0, 8'hFF}; // 0xA00000 - 0xA01FFF (TC0280GRD RAM)
        cfg_addr_priority <= {8'hD0, 8'hFF}; // 0xD00000 - 0xD0001F (TC0360PRI)
      end

      GAME_QTORIMON: begin
        cfg_addr_rom      <= {8'h00, 8'hF8}; // 0x000000 - 0x07FFFF
        cfg_addr_work_ram      <= {8'h10, 8'hFF}; // 0x100000 - 0x10FFFF
        cfg_addr_color  <= {8'h20, 8'hFF}; // 0x200000 - 0x200007 (TC0110PCR)
        cfg_addr_io0       <= {8'h50, 8'hFF}; // 0x500000 - 0x50000F (TC0220IOC)
        cfg_addr_sound    <= {8'h60, 8'hFF}; // 0x600000, 0x600002 (TC0140SYT)
        cfg_addr_screen0  <= {8'h80, 8'hF0}; // 0x800000 - 0x80FFFF (TC0100SCN RAM)
        cfg_addr_obj    <= {8'h90, 8'hFF}; // 0x900000 - 0x90FFFF
        // 0x910000 - 0x9120FF : NOP Write (error in game init code?)
      end

      GAME_LIQUIDK: begin
        cfg_addr_rom      <= {8'h00, 8'hF8}; // 0x000000 - 0x07FFFF
        cfg_addr_work_ram      <= {8'h10, 8'hFF}; // 0x100000 - 0x10FFFF
        cfg_addr_color       <= {8'h20, 8'hFF}; // 0x200000 - 0x201FFF (Palette RAM)
        cfg_addr_io0       <= {8'h30, 8'hFF}; // 0x300000 - 0x30000F (TC0220IOC)
        cfg_addr_sound    <= {8'h32, 8'hFF}; // 0x320001, 0x320003 (TC0140SYT)
        cfg_addr_screen0  <= {8'h80, 8'hF0}; // 0x800000 - 0x80FFFF (TC0100SCN RAM)
        cfg_addr_obj    <= {8'h90, 8'hFF}; // 0x900000 - 0x90FFFF
        cfg_addr_priority <= {8'hB0, 8'hFF}; // 0xB00000 - 0xB0001F (TC0360PRI)
      end

      GAME_QUIZHQ: begin
        cfg_addr_rom      <= {8'h00, 8'hF0}; // 0x000000 - 0x0BFFFF
        cfg_addr_work_ram      <= {8'h10, 8'hFF}; // 0x100000 - 0x10FFFF
        cfg_addr_color  <= {8'h20, 8'hFF}; // 0x200000 - 0x200007 (TC0110PCR)
        cfg_addr_io0       <= {8'h50, 8'hFF}; // 0x50xxxx DSW/Coin/Input, 0x58xxxx DSW/Input/Watchdog
        cfg_addr_io1       <= {8'h58, 8'hFF}; // 0x50xxxx DSW/Coin/Input, 0x58xxxx DSW/Input/Watchdog
        cfg_addr_sound    <= {8'h60, 8'hFF}; // 0x600001, 0x600003 (TC0140SYT)
        // 0x680000 - 0x680001 : NOP Write (unknown?)
        cfg_addr_screen0  <= {8'h80, 8'hF0}; // 0x800000 - 0x80FFFF (TC0100SCN RAM)
        // 0x810000 - 0x81FFFF : NOP Write (error in game init code?)
        cfg_addr_obj    <= {8'h90, 8'hFF}; // 0x900000 - 0x90FFFF
      end

      GAME_SSI: begin // Also MAJEST12
        cfg_addr_rom      <= {8'h00, 8'hF8}; // 0x000000 - 0x07FFFF
        cfg_addr_io0       <= {8'h10, 8'hFF}; // 0x100000 - 0x10000F (TC0510NIO)
        cfg_addr_work_ram      <= {8'h20, 8'hFF}; // 0x200000 - 0x20FFFF
        cfg_addr_color       <= {8'h30, 8'hFF}; // 0x300000 - 0x301FFF (Palette RAM)
        cfg_addr_sound    <= {8'h40, 8'hFF}; // 0x400000, 0x400002 (TC0140SYT)
        cfg_addr_screen0  <= {8'h60, 8'hF0}; // 0x600000 - 0x60FFFF (TC0100SCN RAM, not used)
        cfg_addr_obj    <= {8'h80, 8'hFF}; // 0x800000 - 0x80FFFF
      end

      GAME_GUNFRONT: begin
        cfg_addr_rom      <= {8'h00, 8'hF0}; // 0x000000 - 0x0BFFFF
        cfg_addr_work_ram      <= {8'h10, 8'hFF}; // 0x100000 - 0x10FFFF
        cfg_addr_color       <= {8'h20, 8'hFF}; // 0x200000 - 0x201FFF (Palette RAM)
        cfg_addr_io0       <= {8'h30, 8'hFF}; // 0x300000 - 0x30000F (TC0510NIO)
        cfg_addr_sound    <= {8'h32, 8'hFF}; // 0x320000, 0x320002 (TC0140SYT)
        cfg_addr_screen0  <= {8'h80, 8'hF0}; // 0x800000 - 0x80FFFF (TC0100SCN RAM)
        cfg_addr_obj    <= {8'h90, 8'hFF}; // 0x900000 - 0x90FFFF
        cfg_addr_priority <= {8'hB0, 8'hFF}; // 0xB00000 - 0xB0001F (TC0360PRI)
      end

      GAME_GROWL: begin // Also RUNARK
        cfg_addr_rom      <= {8'h00, 8'hF0}; // 0x000000 - 0x0FFFFF
        cfg_addr_work_ram      <= {8'h10, 8'hFF}; // 0x100000 - 0x10FFFF
        cfg_addr_color       <= {8'h20, 8'hFF}; // 0x200000 - 0x201FFF (Palette RAM)
        cfg_addr_io0       <= {8'h30, 8'hFF}; // 0x30xxxx DSW/Coin, 0x32xxxx Input, 0x34xxxx Watchdog
        cfg_addr_io1       <= {8'h32, 8'hFF}; // 0x30xxxx DSW/Coin, 0x32xxxx Input, 0x34xxxx Watchdog
        cfg_addr_sound    <= {8'h40, 8'hFF}; // 0x400000, 0x400002 (TC0140SYT)
        cfg_addr_extension <= {8'h50, 8'hFF}; // 0x500xxx Spritebank, 0x504xxx NOP, 0x508xxx Input3, 0x50Cxxx Input4
        // Note: This single assignment for 0x50xxxx might be too broad if Input3/4 need separate decoding logic.
        //       Alternatively, treat 50, 58, 5C as separate blocks if HW decodes that way.
        // cfg_addr_spritebank_sel <= {8'h50, 8'hFF}; // 0x500000 - 0x50000F
        // cfg_addr_input3        <= {8'h58, 8'hFF}; // 0x508000 - 0x50800F
        // cfg_addr_input4        <= {8'h5C, 8'hFF}; // 0x50C000 - 0x50C00F
        cfg_addr_screen0  <= {8'h80, 8'hF0}; // 0x800000 - 0x80FFFF (TC0100SCN RAM)
        cfg_addr_obj    <= {8'h90, 8'hFF}; // 0x900000 - 0x90FFFF
        cfg_addr_priority <= {8'hB0, 8'hFF}; // 0xB00000 - 0xB0001F (TC0360PRI)
      end

      GAME_MJNQUEST: begin
        cfg_addr_rom      <= {8'h00, 8'hF0}; // 0x000000 - 0x0FFFFF
        cfg_addr_work_ram      <= {8'h11, 8'hFE}; // 0x11xxxx SRAM, 0x12xxxx RAM
        cfg_addr_color  <= {8'h20, 8'hFF}; // 0x200000 - 0x200007 (TC0110PCR)
        //cfg_addr_dsw_coin_read <= {8'h30, 8'hFF}; // 0x300000 - 0x30000F
        //cfg_addr_mahjong_input <= {8'h31, 8'hFF}; // 0x310000 - 0x310001 (Input Read), 0x320000 - 0x320001 (Input Sel)
        //cfg_addr_watchdog      <= {8'h33, 8'hFD}; // 0x33xxxx NOP (Watchdog?), 0x35xxxx NOP (Watchdog?)
        cfg_addr_sound    <= {8'h36, 8'hFF}; // 0x360000, 0x360002 (TC0140SYT)
        //cfg_addr_gfxbank_sel   <= {8'h38, 8'hFF}; // 0x380001
        cfg_addr_screen0  <= {8'h40, 8'hF0}; // 0x400000 - 0x40FFFF (TC0100SCN RAM)
        cfg_addr_obj    <= {8'h50, 8'hFF}; // 0x500000 - 0x50FFFF
      end

      GAME_HTHERO,
      GAME_FOOTCHMP: begin // Also HTHERO, EUROCH92
        cfg_addr_rom      <= {8'h00, 8'hF8}; // 0x000000 - 0x07FFFF
        cfg_addr_work_ram      <= {8'h10, 8'hFF}; // 0x100000 - 0x10FFFF
        cfg_addr_obj    <= {8'h20, 8'hFF}; // 0x200000 - 0x20FFFF
        cfg_addr_extension <= {8'h30, 8'hFF}; // 0x300000 - 0x30000F
        cfg_addr_screen1  <= {8'h40, 8'hF0}; // 0x40xxxx TC0480SCP RAM, 0x43xxxx TC0480SCP CTRL
        cfg_addr_priority <= {8'h50, 8'hFF}; // 0x500000 - 0x50001F (TC0360PRI)
        cfg_addr_color       <= {8'h60, 8'hFE}; // 0x600000 - 0x601FFF (Palette RAM)
        cfg_addr_io0       <= {8'h70, 8'hFF}; // 0x700000 - 0x70001F (TE7750)
        cfg_addr_sound    <= {8'hA0, 8'hFF}; // 0xA00001, 0xA00003 (TC0140SYT)
      end

      GAME_KOSHIEN: begin
        cfg_addr_rom      <= {8'h00, 8'hF0}; // 0x000000 - 0x0FFFFF
        cfg_addr_work_ram      <= {8'h10, 8'hFF}; // 0x100000 - 0x10FFFF
        cfg_addr_color       <= {8'h20, 8'hFF}; // 0x200000 - 0x201FFF (Palette RAM)
        cfg_addr_io0       <= {8'h30, 8'hFF}; // 0x300000 - 0x30000F (TC0510NIO)
        cfg_addr_sound    <= {8'h32, 8'hFF}; // 0x320000, 0x320002 (TC0140SYT)
        cfg_addr_screen0  <= {8'h80, 8'hF0}; // 0x800000 - 0x80FFFF (TC0100SCN RAM)
        cfg_addr_obj    <= {8'h90, 8'hFF}; // 0x900000 - 0x90FFFF
        cfg_addr_extension<= {8'hA2, 8'hFF}; // 0xA20000 - 0xA20001
        cfg_addr_priority <= {8'hB0, 8'hFF}; // 0xB00000 - 0xB0001F (TC0360PRI)
      end

      GAME_YUYUGOGO: begin
        cfg_addr_rom      <= {8'h00, 8'hFC}; // 0x000000 - 0x03FFFF
        cfg_addr_io0       <= {8'h20, 8'hFF}; // 0x200000 - 0x20000F (TC0510NIO)
        cfg_addr_sound    <= {8'h40, 8'hFF}; // 0x400000, 0x400002 (TC0140SYT)
        cfg_addr_screen0  <= {8'h80, 8'hF0}; // 0x800000 - 0x80FFFF (TC0100SCN RAM)
        cfg_addr_obj    <= {8'h90, 8'hFF}; // 0x900000 - 0x90FFFF
        cfg_addr_color       <= {8'hA0, 8'hFE}; // 0xA00000 - 0xA01FFF (Palette RAM)
        cfg_addr_work_ram      <= {8'hB0, 8'hFE}; // 0xB00000 - 0xB10FFF
        cfg_addr_extension<= {8'hC0, 8'hF0}; // 0xC00000 - 0xC01FFF
        cfg_addr_extra_rom     <= {8'hD0, 8'hF0}; // 0xD00000 - 0xDFFFFF
      end

      GAME_NINJAK: begin
        cfg_addr_rom      <= {8'h00, 8'hF8}; // 0x000000 - 0x07FFFF
        cfg_addr_work_ram      <= {8'h10, 8'hFF}; // 0x100000 - 0x10FFFF
        cfg_addr_color       <= {8'h20, 8'hFF}; // 0x200000 - 0x201FFF (Palette RAM)
        cfg_addr_io0       <= {8'h30, 8'hF7}; // 0x30xxxx TE7750, 0x38xxxx Watchdog
        //cfg_addr_watchdog      <= {8'h38, 8'hFF}; // 0x380000 - 0x380001 (Watchdog) - Note: Overlaps IO chip general range
        cfg_addr_sound    <= {8'h40, 8'hFF}; // 0x400000, 0x400002 (TC0140SYT)
        cfg_addr_extension <= {8'h60, 8'hFF}; // 0x600000 - 0x60000F
        cfg_addr_screen0  <= {8'h80, 8'hF0}; // 0x800000 - 0x80FFFF (TC0100SCN RAM)
        cfg_addr_obj    <= {8'h90, 8'hFF}; // 0x900000 - 0x90FFFF
        cfg_addr_priority <= {8'hB0, 8'hFF}; // 0xB00000 - 0xB0001F (TC0360PRI)
      end

      GAME_SOLFIGTR: begin
        cfg_addr_rom      <= {8'h00, 8'hF8}; // 0x000000 - 0x07FFFF
        cfg_addr_work_ram      <= {8'h10, 8'hFF}; // 0x100000 - 0x10FFFF
        cfg_addr_color       <= {8'h20, 8'hFF}; // 0x200000 - 0x201FFF (Palette RAM)
        cfg_addr_io0       <= {8'h30, 8'hFF}; // 0x30xxxx DSW/Coin, 0x32xxxx Input, 0x34xxxx Watchdog
        cfg_addr_io1       <= {8'h32, 8'hFF}; // 0x30xxxx DSW/Coin, 0x32xxxx Input, 0x34xxxx Watchdog
        //cfg_addr_watchdog      <= {8'h34, 8'hFF}; // 0x340000 - 0x340001 (Watchdog) - Note: Overlaps IO chip general range
        cfg_addr_sound    <= {8'h40, 8'hFF}; // 0x400000, 0x400002 (TC0140SYT)
        cfg_addr_extension<= {8'h50, 8'hFF}; // 0x500xxx Spritebank, 0x504xxx NOP
        cfg_addr_screen0  <= {8'h80, 8'hF0}; // 0x800000 - 0x80FFFF (TC0100SCN RAM)
        cfg_addr_obj    <= {8'h90, 8'hFF}; // 0x900000 - 0x90FFFF
        cfg_addr_priority <= {8'hB0, 8'hFF}; // 0xB00000 - 0xB0001F (TC0360PRI)
      end

      GAME_QZQUEST: begin
        cfg_addr_rom      <= {8'h00, 8'hE0}; // 0x000000 - 0x17FFFF
        cfg_addr_io0       <= {8'h20, 8'hFF}; // 0x200000 - 0x20000F (TC0510NIO)
        cfg_addr_sound    <= {8'h30, 8'hFF}; // 0x300001, 0x300003 (TC0140SYT)
        cfg_addr_color       <= {8'h40, 8'hFF}; // 0x400000 - 0x401FFF (Palette RAM)
        cfg_addr_work_ram      <= {8'h50, 8'hFF}; // 0x500000 - 0x50FFFF
        cfg_addr_obj    <= {8'h60, 8'hFF}; // 0x600000 - 0x60FFFF
        cfg_addr_screen0  <= {8'h70, 8'hF0}; // 0x700000 - 0x70FFFF (TC0100SCN RAM)
      end

      GAME_PULIRULA: begin
        cfg_addr_rom      <= {8'h00, 8'hF0}; // 0x000000 - 0x0BFFFF
        cfg_addr_sound    <= {8'h20, 8'hFF}; // 0x200000, 0x200002 (TC0140SYT)
        cfg_addr_work_ram      <= {8'h30, 8'hFF}; // 0x300000 - 0x30FFFF
        cfg_addr_roz       <= {8'h40, 8'hF0}; // 0x400000 - 0x401FFF (TC0430GRW RAM)
        cfg_addr_extension<= {8'h60, 8'hFF}; // 0x600000 - 0x603FFF
        cfg_addr_color       <= {8'h70, 8'hF0}; // 0x700000 - 0x701FFF (Palette RAM)
        cfg_addr_screen0  <= {8'h80, 8'hF0}; // 0x800000 - 0x80FFFF (TC0100SCN RAM)
        cfg_addr_obj    <= {8'h90, 8'hFF}; // 0x900000 - 0x90FFFF
        cfg_addr_priority <= {8'hA0, 8'hFF}; // 0xA00000 - 0xA0001F (TC0360PRI)
        cfg_addr_io0       <= {8'hB0, 8'hFF}; // 0xB00000 - 0xB0000F (TC0510NIO)
      end

      GAME_METALBA,
      GAME_METALB: begin
        cfg_addr_rom      <= {8'h00, 8'hF0}; // 0x000000 - 0x0BFFFF
        cfg_addr_work_ram      <= {8'h10, 8'hFF}; // 0x100000 - 0x10FFFF
        cfg_addr_obj    <= {8'h30, 8'hFF}; // 0x300000 - 0x30FFFF
        cfg_addr_screen1  <= {8'h50, 8'hF0}; // 0x50xxxx TC0480SCP RAM, 0x53xxxx TC0480SCP CTRL
        cfg_addr_priority <= {8'h60, 8'hFF}; // 0x600000 - 0x60001F (TC0360PRI)
        cfg_addr_color       <= {8'h70, 8'hFF}; // 0x700000 - 0x703FFF (Palette RAM)
        cfg_addr_io0       <= {8'h80, 8'hFF}; // 0x800000 - 0x80000F (TC0510NIO)
        cfg_addr_sound    <= {8'h90, 8'hFF}; // 0x900000, 0x900002 (TC0140SYT)
      end

      GAME_QZCHIKYU: begin
        cfg_addr_rom      <= {8'h00, 8'hE0}; // 0x000000 - 0x17FFFF
        cfg_addr_io0       <= {8'h20, 8'hFF}; // 0x200000 - 0x20000F (TC0510NIO)
        cfg_addr_sound    <= {8'h30, 8'hFF}; // 0x300001, 0x300003 (TC0140SYT)
        cfg_addr_color       <= {8'h40, 8'hFE}; // 0x400000 - 0x401FFF (Palette RAM)
        cfg_addr_work_ram      <= {8'h50, 8'hFF}; // 0x500000 - 0x50FFFF
        cfg_addr_obj    <= {8'h60, 8'hFF}; // 0x600000 - 0x60FFFF
        cfg_addr_screen0  <= {8'h70, 8'hF0}; // 0x700000 - 0x70FFFF (TC0100SCN RAM)
      end

      GAME_YESNOJ: begin
        cfg_addr_rom      <= {8'h00, 8'hF8}; // 0x000000 - 0x07FFFF
        cfg_addr_work_ram      <= {8'h20, 8'hFF}; // 0x200000 - 0x20FFFF
        cfg_addr_obj    <= {8'h40, 8'hFF}; // 0x400000 - 0x40FFFF
        cfg_addr_screen0  <= {8'h50, 8'hF0}; // 0x500000 - 0x50FFFF (TC0100SCN RAM)
        cfg_addr_color       <= {8'h60, 8'hFF}; // 0x600000 - 0x601FFF (Palette RAM)
        //cfg_addr_rtc           <= {8'h70, 8'hFF}; // 0x700000 - 0x70001F (TC8521 RTC)
        cfg_addr_sound    <= {8'h80, 8'hFF}; // 0x800000, 0x800002 (TC0140SYT)
        // 0x900002 - 0x900003 : NOP Write (unknown?)
        cfg_addr_io0       <= {8'hA0, 8'hF0}; // 0xA0xxxx Input, 0xB0xxxx DSW, 0xC0xxxx Watchdog?, 0xD0xxxx NOP?
        //cfg_addr_watchdog      <= {8'hC0, 8'hFF}; // 0xC00000 - 0xC00001 (Watchdog?) - Note: Overlaps IO chip general range
      end

      GAME_DEADCONX,
      GAME_DEADCONXJ: begin
        cfg_addr_rom      <= {8'h00, 8'hF0}; // 0x000000 - 0x0FFFFF
        cfg_addr_work_ram      <= {8'h10, 8'hFF}; // 0x100000 - 0x10FFFF
        cfg_addr_obj    <= {8'h20, 8'hFF}; // 0x200000 - 0x20FFFF
        cfg_addr_extension <= {8'h30, 8'hFF}; // 0x300000 - 0x30000F
        cfg_addr_screen1  <= {8'h40, 8'hF0}; // 0x40xxxx TC0480SCP RAM, 0x43xxxx TC0480SCP CTRL
        cfg_addr_priority <= {8'h50, 8'hFF}; // 0x500000 - 0x50001F (TC0360PRI)
        cfg_addr_color       <= {8'h60, 8'hFF}; // 0x600000 - 0x601FFF (Palette RAM)
        cfg_addr_io0       <= {8'h70, 8'hFF}; // 0x700000 - 0x70001F (TE7750)
        //cfg_addr_watchdog      <= {8'h80, 8'hFF}; // 0x800000 - 0x800001
        cfg_addr_sound    <= {8'hA0, 8'hFF}; // 0xA00000, 0xA00002 (TC0140SYT)
      end

      GAME_DINOREX: begin
        cfg_addr_rom      <= {8'h00, 8'hE0}; // 0x000000 - 0x1FFFFF
        cfg_addr_rom1     <= {8'h20, 8'hF0}; // 0x200000 - 0x2FFFFF
        cfg_addr_io0       <= {8'h30, 8'hFF}; // 0x300000 - 0x30000F (TC0510NIO)
        cfg_addr_extension<= {8'h40, 8'hFF}; // 0x400000 - 0x400FFF
        cfg_addr_color       <= {8'h50, 8'hFF}; // 0x500000 - 0x501FFF (Palette RAM)
        cfg_addr_work_ram      <= {8'h60, 8'hF0}; // 0x600000 - 0x60FFFF
        cfg_addr_priority <= {8'h70, 8'hFF}; // 0x700000 - 0x70001F (TC0360PRI)
        cfg_addr_obj    <= {8'h80, 8'hFF}; // 0x800000 - 0x80FFFF
        cfg_addr_screen0  <= {8'h90, 8'hF0}; // 0x900000 - 0x90FFFF (TC0100SCN RAM)
        cfg_addr_sound    <= {8'hA0, 8'hFF}; // 0xA00000, 0xA00002 (TC0140SYT)
        //cfg_addr_watchdog      <= {8'hB0, 8'hFF}; // 0xB00000 - 0xB00001 (Watchdog?)
      end

      GAME_QJINSEI: begin
        cfg_addr_rom      <= {8'h00, 8'hE0}; // 0x000000 - 0x1FFFFF
        cfg_addr_sound    <= {8'h20, 8'hFF}; // 0x200000, 0x200002 (TC0140SYT)
        cfg_addr_work_ram      <= {8'h30, 8'hFF}; // 0x300000 - 0x30FFFF
        //cfg_addr_watchdog      <= {8'h50, 8'hFF}; // 0x500000 - 0x500001 (Watchdog?)
        cfg_addr_extension<= {8'h60, 8'hFC}; // 0x600000 - 0x603FFF
        cfg_addr_color       <= {8'h70, 8'hFF}; // 0x700000 - 0x701FFF (Palette RAM)
        cfg_addr_screen0  <= {8'h80, 8'hF0}; // 0x800000 - 0x80FFFF (TC0100SCN RAM)
        cfg_addr_obj    <= {8'h90, 8'hFF}; // 0x900000 - 0x90FFFF
        cfg_addr_priority <= {8'hA0, 8'hFF}; // 0xA00000 - 0xA0001F (TC0360PRI)
        cfg_addr_io0       <= {8'hB0, 8'hFF}; // 0xB00000 - 0xB0000F (TC0510NIO)
      end

      GAME_QCRAYON: begin
        cfg_addr_rom      <= {8'h00, 8'hF8}; // 0x000000 - 0x07FFFF
        cfg_addr_work_ram      <= {8'h10, 8'hFF}; // 0x100000 - 0x10FFFF
        cfg_addr_extra_rom     <= {8'h30, 8'hF0}; // 0x300000 - 0x3FFFFF
        cfg_addr_sound    <= {8'h50, 8'hFF}; // 0x500000, 0x500002 (TC0140SYT)
        cfg_addr_extension<= {8'h60, 8'hFC}; // 0x600000 - 0x603FFF
        cfg_addr_color       <= {8'h70, 8'hFF}; // 0x700000 - 0x701FFF (Palette RAM)
        cfg_addr_obj    <= {8'h80, 8'hFF}; // 0x800000 - 0x80FFFF
        cfg_addr_screen0  <= {8'h90, 8'hF0}; // 0x900000 - 0x90FFFF (TC0100SCN RAM)
        cfg_addr_io0       <= {8'hA0, 8'hFF}; // 0xA00000 - 0xA0000F (TC0510NIO)
        cfg_addr_priority <= {8'hB0, 8'hFF}; // 0xB00000 - 0xB0001F (TC0360PRI)
      end

      GAME_QCRAYON2: begin
        cfg_addr_rom      <= {8'h00, 8'hF8}; // 0x000000 - 0x07FFFF
        cfg_addr_work_ram      <= {8'h20, 8'hFF}; // 0x200000 - 0x20FFFF
        cfg_addr_color       <= {8'h30, 8'hFF}; // 0x300000 - 0x301FFF (Palette RAM)
        cfg_addr_obj    <= {8'h40, 8'hFF}; // 0x400000 - 0x40FFFF
        cfg_addr_screen0  <= {8'h50, 8'hF0}; // 0x500000 - 0x50FFFF (TC0100SCN RAM)
        cfg_addr_extra_rom     <= {8'h60, 8'hF8}; // 0x600000 - 0x67FFFF
        cfg_addr_io0       <= {8'h70, 8'hFF}; // 0x700000 - 0x70000F (TC0510NIO)
        cfg_addr_priority <= {8'h90, 8'hFF}; // 0x900000 - 0x90001F (TC0360PRI)
        cfg_addr_sound    <= {8'hA0, 8'hFF}; // 0xA00000, 0xA00002 (TC0140SYT)
        cfg_addr_extension<= {8'hB0, 8'hFF}; // 0xB00000 - 0xB017FF
      end

      GAME_DRIFTOUT: begin
        cfg_addr_rom      <= {8'h00, 8'hF0}; // 0x000000 - 0x0FFFFF
        cfg_addr_sound    <= {8'h20, 8'hFF}; // 0x200000, 0x200002 (TC0140SYT)
        cfg_addr_work_ram      <= {8'h30, 8'hFF}; // 0x300000 - 0x30FFFF
        cfg_addr_roz       <= {8'h40, 8'hF0}; // 0x400000 - 0x401FFF (TC0430GRW RAM)
        cfg_addr_color       <= {8'h70, 8'hFF}; // 0x700000 - 0x701FFF (Palette RAM)
        cfg_addr_screen0  <= {8'h80, 8'hF0}; // 0x800000 - 0x80FFFF (TC0100SCN RAM)
        cfg_addr_obj    <= {8'h90, 8'hFF}; // 0x900000 - 0x90FFFF
        cfg_addr_priority <= {8'hA0, 8'hFF}; // 0xA00000 - 0xA0001F (TC0360PRI)
        cfg_addr_io0       <= {8'hB0, 8'hFF}; // 0xB00000 - 0xB0000F (TC0510NIO)
        //cfg_addr_paddle_input  <= {8'hB0, 8'hFF}; // 0xB00018 - 0xB0001B - Note: Shares base addr B0 with IO
      end

      default: begin
      end

    endcase
end

always_ff @(posedge clk) begin
    if (reset) begin
        cfg_hofs_200obj  <= 312; cfg_vofs_200obj  <= 237;
        cfg_hofs_100scn0 <= 397; cfg_vofs_100scn0 <= 253;
        cfg_hofs_100scn1 <= 397; cfg_vofs_100scn1 <= 253;
        cfg_hofs_430grw  <= 323; cfg_vofs_430grw  <= 224;

        case (game)
            GAME_DEADCONXJ: begin cfg_hofs_480scp <= 322 + 11; cfg_vofs_480scp <= 224 + 17; end
            GAME_DEADCONX:  begin cfg_hofs_480scp <= 322 + 33; cfg_vofs_480scp <= 224 + 30; end
            GAME_METALB:    begin cfg_hofs_480scp <= 322 + 11; cfg_vofs_480scp <= 224 + 18; end
            GAME_METALBA:   begin cfg_hofs_480scp <= 322 + 33; cfg_vofs_480scp <= 224 + 30; end
            GAME_FOOTCHMP:  begin cfg_hofs_480scp <= 322 + 34; cfg_vofs_480scp <= 224 + 30; end
            GAME_HTHERO:    begin cfg_hofs_480scp <= 322 + 12; cfg_vofs_480scp <= 224 + 18; end
            default:        begin cfg_hofs_480scp <= 322;      cfg_vofs_480scp <= 224;      end
        endcase
    end
end

endmodule

