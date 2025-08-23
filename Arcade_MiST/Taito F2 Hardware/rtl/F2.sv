import system_consts::*;

module F2(
    input             clk,
    input             reset,

    input  game_t     game,

    output            ce_pixel,
    output            hsync,
    output            hblank,
    output            vsync,
    output            vblank,
    output      [7:0] red,
    output      [7:0] green,
    output      [7:0] blue,

    input       [9:0] joystick_p1,
    input       [9:0] joystick_p2,
    input       [9:0] joystick_p3,
    input       [9:0] joystick_p4,
    input       [3:0] start,
    input       [3:0] coin,

    input             analog_inc,
    input             analog_abs,
    input       [7:0] analog_p1,
    input       [7:0] analog_p2,

    input       [7:0] dswa,
    input       [7:0] dswb,

    output     [23:0] cpu1_rom_addr,
    output            cpu1_rom_cs,
    input      [15:0] cpu1_rom_q,
    input             cpu1_rom_valid,

    output     [23:0] cpu2_rom_addr,
    output            cpu2_rom_cs,
    input      [15:0] cpu2_rom_q,
    input             cpu2_rom_valid,

    output reg [26:0] sdr_scn0_addr,
    input      [31:0] sdr_scn0_q,
    output reg        sdr_scn0_req,
    input             sdr_scn0_ack,

    output reg [26:0] sdr_scn_mux_addr,
    input      [63:0] sdr_scn_mux_q,
    output reg        sdr_scn_mux_req,
    input             sdr_scn_mux_ack,
    input             sdr_scn_32_ack,

    output reg [26:0] sdr_audio_addr,
    input      [15:0] sdr_audio_q,
    output reg        sdr_audio_req,
    input             sdr_audio_ack,

    // Memory stream interface
    ddr_if.to_host    ddr,

    input      [12:0] obj_debug_idx,

    output     [15:0] audio_out,

    input             ss_do_save,
    input             ss_do_restore,
    input       [1:0] ss_index,
    output      [3:0] ss_state_out,

    input             sync_fix,

    input             pause
);

wire cfg_260dar, cfg_260dar_acc, cfg_110pcr, cfg_360pri, cfg_360pri_high, cfg_io_swap, cfg_tmp82c265, cfg_190fmc, cfg_te7750;
wire cfg_280grd, cfg_430grw, cfg_480scp, cfg_100scn;
wire cfg_bpp15, cfg_bppmix;

wire [1:0] cfg_obj_extender /* verilator public_flat */;

wire [15:0] cfg_addr_rom;
wire [15:0] cfg_addr_rom1;
wire [15:0] cfg_addr_extra_rom;
wire [15:0] cfg_addr_work_ram;
wire [15:0] cfg_addr_screen0;
wire [15:0] cfg_addr_screen1;
wire [15:0] cfg_addr_obj;
wire [15:0] cfg_addr_color;
wire [15:0] cfg_addr_io0;
wire [15:0] cfg_addr_io1;
wire [15:0] cfg_addr_sound;
wire [15:0] cfg_addr_extension;
wire [15:0] cfg_addr_priority;
wire [15:0] cfg_addr_roz;
wire [15:0] cfg_addr_cchip;

wire [8:0] cfg_hofs_200obj /* verilator public_flat */,  cfg_vofs_200obj  /* verilator public_flat */;
wire [8:0] cfg_hofs_480scp /* verilator public_flat */,  cfg_vofs_480scp  /* verilator public_flat */;
wire [8:0] cfg_hofs_100scn0 /* verilator public_flat */, cfg_vofs_100scn0 /* verilator public_flat */;
wire [8:0] cfg_hofs_100scn1 /* verilator public_flat */, cfg_vofs_100scn1 /* verilator public_flat */;
wire [8:0] cfg_hofs_430grw /* verilator public_flat */,  cfg_vofs_430grw  /* verilator public_flat */;


game_board_config game_board_config(
    .clk,
    .game(game),
    .reset(reset),

    .cfg_110pcr,
    .cfg_260dar,
    .cfg_260dar_acc,
    .cfg_360pri,
    .cfg_360pri_high,
    .cfg_obj_extender,
    .cfg_190fmc,
    .cfg_io_swap,
    .cfg_tmp82c265,
    .cfg_te7750,
    .cfg_280grd,
    .cfg_430grw,
    .cfg_480scp,
    .cfg_100scn,
    .cfg_bpp15,
    .cfg_bppmix,

    .cfg_addr_rom,
    .cfg_addr_rom1,
    .cfg_addr_extra_rom,
    .cfg_addr_work_ram,
    .cfg_addr_screen0,
    .cfg_addr_screen1,
    .cfg_addr_obj,
    .cfg_addr_color,
    .cfg_addr_io0,
    .cfg_addr_io1,
    .cfg_addr_sound,
    .cfg_addr_extension,
    .cfg_addr_priority,
    .cfg_addr_roz,
    .cfg_addr_cchip,

    .cfg_hofs_200obj, .cfg_vofs_200obj,
    .cfg_hofs_480scp, .cfg_vofs_480scp,
    .cfg_hofs_100scn0, .cfg_vofs_100scn0,
    .cfg_hofs_100scn1, .cfg_vofs_100scn1,
    .cfg_hofs_430grw, .cfg_vofs_430grw
);

ddr_if ddr_ss(), ddr_obj();

ddr_mux ddr_mux(
    .clk,
    .x(ddr),
    .a(ddr_ss),
    .b(ddr_obj)
);


wire [26:0] sdr_scn1_addr, sdr_pivot_addr, sdr_scp_addr;
wire sdr_pivot_req, sdr_scn1_req, sdr_scp_req;
assign sdr_scn_mux_addr = cfg_100scn ? sdr_scn1_addr :
                          cfg_480scp ? sdr_scp_addr : sdr_pivot_addr;
assign sdr_scn_mux_req = cfg_100scn ? sdr_scn1_req :
                         cfg_480scp ? sdr_scp_req : sdr_pivot_req;

reg [31:0] ss_saved_ssp;
reg [31:0] ss_restore_ssp;
reg ss_write = 0;
reg ss_read = 0;
wire ss_busy;

ssbus_if ssbus();
ssbus_if ssb[19]();

ssbus_mux #(.COUNT(19)) ssmux(
    .clk,
    .slave(ssbus),
    .masters(ssb)
);

always_ff @(posedge clk) begin
    ssb[0].setup(SSIDX_GLOBAL, 1, 2); // 1, 32-bit value
    if (ssb[0].access(SSIDX_GLOBAL)) begin
        if (ssb[0].read) begin
            ssb[0].read_response(SSIDX_GLOBAL, { 32'd0, ss_saved_ssp });
        end else if (ssb[0].write) begin
            ss_restore_ssp <= ssb[0].data[31:0];
            ssb[0].write_ack(SSIDX_GLOBAL);
        end
    end
end

logic [15:0] ss_irq_handler[16] = '{
    16'h48e7, 16'hfffe,            // movem.l %d0-%d7/%a0-%a6,%a7@-
    16'h4e6e,                      // move.l %usp, %a6
    16'h2f0e,                      // move.l %a6, %a7@-

    // 0x8 - stop/restart pos
    16'h4df9, 16'h00ff, 16'h0000,  // lea 0xff0000, %a6

    16'h2c8f,                      // move.l %a7, %a6@

    16'h2c5f,                      // move.l %a7@+, %a6
    16'h4e66,                      // move.l %a6, %usp
    16'h4cdf, 16'h7fff,            // movem.l %a7@+, %d0-%d7/%a0-%a6
    16'h4e73,                      // rte

    16'h0000,
    16'h0000,
    16'h0000
};


typedef enum bit [3:0] {
    SST_IDLE,

    SST_SAVE_WAIT_PAUSE,
    SST_SAVE_WAIT_IRQ,
    SST_SAVE_WAIT_WRITE,
    SST_SAVE_WAIT_IRQ_EXIT,
    SST_SAVE_WAIT_SSP_SAVE,

    SST_RESTORE_WAIT_PAUSE,
    SST_RESTORE_WAIT_READ,
    SST_RESTORE_HOLD_RESET,
    SST_RESTORE_WAIT_RESET
} ss_state_t;

ss_state_t ss_state = SST_IDLE;
reg [4:0] ss_reset_counter;
reg [15:0] ss_reset_vector[4];

logic ss_pause;
logic ss_irq;
logic ss_override;
logic ss_cpu_execute;
logic ss_reset;

assign ss_state_out = ss_state;

always_comb begin
    ss_pause = 1;
    ss_cpu_execute = 0;
    ss_override = 0;
    ss_irq = 0;
    ss_reset = 0;

    case(ss_state)
        SST_IDLE: begin
            ss_pause = 0;
        end

        SST_SAVE_WAIT_PAUSE: begin
        end

        SST_SAVE_WAIT_IRQ: begin
            ss_cpu_execute = 1;
            ss_irq = 1;
        end


        SST_SAVE_WAIT_SSP_SAVE: begin
            ss_override = 1;
            ss_cpu_execute = 1;
        end

        SST_SAVE_WAIT_WRITE: begin
        end

        SST_SAVE_WAIT_IRQ_EXIT: begin
            ss_cpu_execute = 1;
            ss_override = 1;
        end

        SST_RESTORE_WAIT_PAUSE: begin
        end

        SST_RESTORE_WAIT_READ: begin
        end

        SST_RESTORE_HOLD_RESET: begin
            ss_override = 1;
            ss_cpu_execute = 1;
            ss_reset = 1;
        end

        SST_RESTORE_WAIT_RESET: begin
            ss_override = 1;
            ss_cpu_execute = 1;
        end

        default: begin
        end
    endcase
end


always_ff @(posedge clk) begin
    case(ss_state)
        SST_IDLE: begin
            if (ss_do_save) begin
                ss_state <= SST_SAVE_WAIT_PAUSE;
            end

            if (ss_do_restore) begin
                ss_state <= SST_RESTORE_WAIT_PAUSE;
            end
        end

        SST_SAVE_WAIT_PAUSE: begin
            if (obj_paused) begin
                ss_state <= SST_SAVE_WAIT_IRQ;
            end
        end

        SST_SAVE_WAIT_IRQ: begin
            // Interrupt acknowledged
            if (~IACKn & (cpu_addr[2:0] == 3'b111) & ~cpu_ds_n[0]) begin
                ss_state <= SST_SAVE_WAIT_SSP_SAVE;
            end
        end


        SST_SAVE_WAIT_SSP_SAVE: begin
            if (cpu_ds_n == 2'b00 && !cpu_rw & cpu_word_addr == 24'hff0000) begin
                ss_saved_ssp[31:16] <= cpu_data_out;
            end

            if (cpu_ds_n == 2'b00 && !cpu_rw && cpu_word_addr == 24'hff0002) begin
                ss_saved_ssp[15:0] <= cpu_data_out;
                ss_write <= 1;
                ss_state <= SST_SAVE_WAIT_WRITE;
            end
        end

        SST_SAVE_WAIT_WRITE: begin
            if (ss_busy & ss_write) begin
                ss_write <= 0;
            end else if (~ss_busy & ~ss_write) begin
                ss_state <= SST_SAVE_WAIT_IRQ_EXIT;
            end
        end

        SST_SAVE_WAIT_IRQ_EXIT: begin
            if (cpu_ds_n == 2'b00 && cpu_rw && cpu_fc == 3'b110 && SS_SAVEn) begin
                ss_state <= SST_IDLE;
            end
        end

        SST_RESTORE_WAIT_PAUSE: begin
            if (obj_paused) begin
                ss_read <= 1;
                ss_state <= SST_RESTORE_WAIT_READ;
            end
        end

        SST_RESTORE_WAIT_READ: begin
            if (ss_busy & ss_read) begin
                ss_read <= 0;
            end else if (~ss_busy & ~ss_read) begin
                ss_reset_vector[0] <= ss_restore_ssp[31:16];
                ss_reset_vector[1] <= ss_restore_ssp[15:0];
                ss_reset_vector[2] <= 16'h00ff;
                ss_reset_vector[3] <= 16'h0008;

                ss_state <= SST_RESTORE_HOLD_RESET;
                ss_reset_counter <= 0;
            end
        end


        SST_RESTORE_HOLD_RESET: begin
            if (ce_12m) begin
                ss_reset_counter <= ss_reset_counter + 1;
                if (&ss_reset_counter) begin
                    ss_state <= SST_RESTORE_WAIT_RESET;
                end
            end
        end

        SST_RESTORE_WAIT_RESET: begin
            if (cpu_ds_n == 2'b00 && cpu_rw && cpu_fc == 3'b110 && SS_SAVEn && SS_RESETn) begin
                ss_state <= SST_IDLE;
            end
        end

        default: begin
            ss_state <= SST_IDLE;
        end
    endcase
end

//////////////////////////////////
//// CHIP SELECTS

logic ROMn; // CPU ROM
logic WORKn; // CPU RAM
logic SCREEN0n;
logic SCREEN1n;
logic COLORn;
logic IO0n, IO1n;
logic OBJECTn;
logic PRIORITYn;
logic SOUNDn /* verilator public_flat */;
logic EXTENSIONn;
logic CCHIPn;
logic PIVOTn;
logic GROWL_HACKn;
logic EXTRA_ROMn; // CPU ROM "extra" region (ROMn will be asserted also)

wire SDTACK0n, SDTACK1n, VDTACKn, CDTACKn, CPUENn, dar_dtack_n, pivot_dtack_n;

//wire sdr_dtack_n = sdr_cpu_req != sdr_cpu_ack;
wire sdr_dtack_n;

wire dtack_n = sdr_dtack_n
             //| pre_sdr_dtack_n
             | SDTACK0n
             | SDTACK1n
             | VDTACKn
             | (cfg_260dar ? dar_dtack_n : CDTACKn)
             | CPUENn
             | pivot_dtack_n;

wire [2:0] IPLn;
wire DTACKn = dtack_n;

//////////////////////////////////
//// CLOCK ENABLES
wire ce_6m, ce_13m;
jtframe_frac_cen #(2) video_cen
(
    .clk(clk),
    .cen_in(1),
    .n(10'd1),
    .m(10'd4),
    .cen({ce_6m, ce_13m}),
    .cenb()
);

reg [9:0] cpu_missed_cycles = 0;

wire ce_12m, ce_dummy_6m;
jtframe_frac_cen #(2) cen_steady
(
    .clk(clk),
    .cen_in(~obj_paused | ss_cpu_execute),
    .n(10'd172),
    .m(10'd765),
    .cen({ce_dummy_6m, ce_12m}),
    .cenb()
);

reg [9:0] ce_steady_count;
reg [10:0] ce_cpu_count;
reg ce_cpu, ce_cpu_180;

always_ff @(posedge clk) begin
    if (ce_12m) begin
        ce_steady_count <= ce_steady_count + 10'd1;
    end

    ce_cpu <= 0;
    ce_cpu_180 <= 0;

    if (~sdr_dtack_n /*sdr_cpu_req == sdr_cpu_ack*/ && (~obj_paused | ss_cpu_execute)) begin
        if (ce_cpu_count[10:1] != ce_steady_count) begin
            ce_cpu <= ~ce_cpu_count[0];
            ce_cpu_180 <= ce_cpu_count[0];
            ce_cpu_count <= ce_cpu_count + 11'd1;
        end
    end
end

wire ce_8m, ce_4m;
jtframe_frac_cen #(2) audio_cen
(
    .clk(clk),
    .cen_in(~obj_paused | ss_cpu_execute),
    .n(10'd137),
    .m(10'd914),
    .cen({ce_4m, ce_8m}),
    .cenb()
);

wire global_hsync, global_hblank, global_vsync, global_vblank;
wire [8:0] global_hcnt;
wire [8:0] global_vcnt;

video_timing video_timing(
    .clk,
    .ce_13m,
    .sync_fix,

    .ce_pixel,
    .hcnt(global_hcnt),
    .vcnt(global_vcnt),
    .hsync(global_hsync),
    .vsync(global_vsync),
    .hblank(global_hblank),
    .vblank(global_vblank)
);

//////////////////////////////////
//// CPU
wire        cpu_rw, cpu_as_n;
wire [1:0]  cpu_ds_n;
wire [2:0]  cpu_fc;
wire [15:0] cpu_data_in, cpu_data_out;
wire [22:0] cpu_addr;
wire [23:0] cpu_word_addr /* verilator public_flat */ = { cpu_addr, 1'b0 };
wire IACKn = ~&cpu_fc;

fx68k m68000(
    .clk(clk),
    .HALTn(1),
    .extReset(reset | ss_reset),
    .pwrUp(reset | ss_reset),
    .enPhi1(ce_cpu),
    .enPhi2(ce_cpu_180),

    .eRWn(cpu_rw), .ASn(cpu_as_n), .LDSn(cpu_ds_n[0]), .UDSn(cpu_ds_n[1]),
    .E(), .VMAn(),

    .FC0(cpu_fc[0]), .FC1(cpu_fc[1]), .FC2(cpu_fc[2]),
    .BGn(),
    .oRESETn(), .oHALTEDn(),
    .DTACKn(DTACKn), .VPAn(IACKn),
    .BERRn(1),
    .BRn(1), .BGACKn(1),
    .IPL0n(IPLn[0]), .IPL1n(IPLn[1]), .IPL2n(IPLn[2]),
    .iEdb(cpu_data_in), .oEdb(cpu_data_out),
    .eab(cpu_addr)
);

wire [7:0] io_tc0220ioc_data_out, io_tmp82c265_data_out, io_te7750_data_out;
wire [7:0] io_data_out = cfg_tmp82c265 ? io_tmp82c265_data_out
                                       : cfg_te7750 ? io_te7750_data_out
                                       : io_tc0220ioc_data_out;

logic [7:0] IN0, IN1, IN2;

always_comb begin
    case(game)
        GAME_KOSHIEN: begin
            IN0 = { start[1], joystick_p2[6:4], start[0], joystick_p1[6:4] };
            IN1 = { 4'b0000, coin[1:0], 2'b00 };
            IN2 = { joystick_p2[0], joystick_p2[1], joystick_p2[2], joystick_p2[3], joystick_p1[0], joystick_p1[1], joystick_p1[2], joystick_p1[3] }; 
        end

        // Quiz controls
        GAME_QTORIMON,
        GAME_YUYUGOGO,
        GAME_QZQUEST,
        GAME_QZCHIKYU,
        GAME_YESNOJ,
        GAME_QJINSEI,
        GAME_QCRAYON,
        GAME_QCRAYON2: begin
            IN0 = { start[0], 1'b0, joystick_p1[9:4] };
            IN1 = { start[1], 1'b0, joystick_p2[9:4] };
            IN2 = { 4'b0000, coin[1:0], 2'b00 };
        end

        default: begin
            IN0 = { start[0], joystick_p1[6:4], joystick_p1[0], joystick_p1[1], joystick_p1[2], joystick_p1[3] };
            IN1 = { start[1], joystick_p2[6:4], joystick_p2[0], joystick_p2[1], joystick_p2[2], joystick_p2[3] };
            IN2 = { 2'b00, start[1:0], coin[1:0], 2'b00 };
        end
    endcase
end

TC0220IOC tc0220ioc(
    .clk,

    .RES_CLK_IN(0),
    .RES_INn(1),
    .RES_OUTn(),

    .A(cfg_io_swap ? { cpu_addr[3:1], ~cpu_addr[0] } : cpu_addr[3:0]),
    .WEn(cpu_rw),
    .CSn(IO0n),
    .OEn(0),

    .Din(cpu_data_out[7:0]),
    .Dout(io_tc0220ioc_data_out),

    .COIN_LOCK_A(),
    .COIN_LOCK_B(),
    .COINMETER_A(),
    .COINMETER_B(),

    .INB(~IN2),
    .IN(~{IN1, IN0, dswb, dswa}),

    .rotary_abs(analog_abs),
    .rotary_inc(analog_inc),
    .rotary_a(analog_p1),
    .rotary_b(analog_p2)
);

logic [15:0] PAin, PBin, PCin;

always_comb begin
    if (game == GAME_QUIZHQ) begin
        // DWSB, DWSA
        PAin = { dswa, dswb };
        // IN0, IN1
        PBin = { start[0], 2'b00, joystick_p1[8:4], start[1], 2'b00, joystick_p2[8:4] };
        // IN2
        PCin = { 4'd0, coin[1:0], 2'd0, 8'h00 };
    end else begin
        // IN0, DSWA
        PAin = { start[0], joystick_p1[6:4], joystick_p1[0], joystick_p1[1], joystick_p1[2], joystick_p1[3], dswa };
        // IN1, DWSB
        PBin = { start[1], joystick_p2[6:4], joystick_p2[0], joystick_p2[1], joystick_p2[2], joystick_p2[3], dswb };
        // COIN, IN2
        PCin = { 4'd0, coin[1:0], 2'd0, 8'h00};
    end
end

TMP82C265 tmp82c265(
    .clk,
    .RESET(reset),

    .A(cpu_addr[1:0]),
    .RDn(~cpu_rw | cpu_ds_n[0]),
    .WRn(cpu_rw | cpu_ds_n[0]),
    .CS0n(IO0n),
    .CS1n(IO1n),

    .DBin(cpu_data_out[7:0]),
    .DBout(io_tmp82c265_data_out),

    .PAout(),
    .PBout(),
    .PCout(),

    .PAin(~PAin),
    .PBin(~PBin),
    .PCin(~PCin)
);


logic [7:0] te7750_p[10];

always_comb begin
    te7750_p[0] = 0;
    if (game == GAME_NINJAK) begin
        te7750_p[1] = dswa;
        te7750_p[2] = dswb;
        te7750_p[3] = {start[0], joystick_p1[6:4], joystick_p1[0], joystick_p1[1], joystick_p1[2], joystick_p1[3]};
        te7750_p[4] = {start[1], joystick_p2[6:4], joystick_p2[0], joystick_p2[1], joystick_p2[2], joystick_p2[3]};
        te7750_p[5] = {start[2], joystick_p3[6:4], joystick_p3[0], joystick_p3[1], joystick_p3[2], joystick_p3[3]};
        te7750_p[6] = {start[3], joystick_p4[6:4], joystick_p4[0], joystick_p4[1], joystick_p4[2], joystick_p4[3]};
        te7750_p[7] = {coin[3:0], 4'd0};
        te7750_p[8] = 0;
        te7750_p[9] = 0;
    end else begin
        te7750_p[1] = dswa;
        te7750_p[2] = dswb;
        te7750_p[3] = {4'd0, coin[3:0]};
        te7750_p[4] = 0;
        te7750_p[5] = 0;
        te7750_p[6] = {start[0], joystick_p1[6:4], joystick_p1[0], joystick_p1[1], joystick_p1[2], joystick_p1[3]};
        te7750_p[7] = {start[1], joystick_p2[6:4], joystick_p2[0], joystick_p2[1], joystick_p2[2], joystick_p2[3]};
        te7750_p[8] = {start[2], joystick_p3[6:4], joystick_p3[0], joystick_p3[1], joystick_p3[2], joystick_p3[3]};
        te7750_p[9] = {start[3], joystick_p4[6:4], joystick_p4[0], joystick_p4[1], joystick_p4[2], joystick_p4[3]};
     end
end

TE7750 te7750(
    .clk,
    .RESETn(~reset),

    .CSn(IO0n),
    .A(cpu_addr[3:0]),
    .RWn(cfg_io_swap ? (cpu_rw | cpu_ds_n[1]) : (cpu_rw | cpu_ds_n[0])),
    .Din(cfg_io_swap ? cpu_data_out[15:8] : cpu_data_out[7:0]),
    .Dout(io_te7750_data_out),


    .P1in(~te7750_p[1]),
    .P2in(~te7750_p[2]),
    .P3in(~te7750_p[3]),
    .P4in(~te7750_p[4]),
    .P5in(~te7750_p[5]),
    .P6in(~te7750_p[6]),
    .P7in(~te7750_p[7]),
    .P8in(~te7750_p[8]),
    .P9in(~te7750_p[9]),

    .P1out(), .P2out(), .P3out(), .P4out(), .P5out(),
    .P6out(), .P7out(), .P8out(), .P9out()
);


reg [15:0] growl_hack_data;
always_ff @(posedge clk) begin
    if (cpu_word_addr[14]) begin // 0x50c000
        growl_hack_data <= ~{ 14'b0, coin[3:2] };
    end else begin // 0x508000
        growl_hack_data[7:0]  <= ~{ start[2], joystick_p3[6:4], joystick_p3[0], joystick_p3[1], joystick_p3[2], joystick_p3[3] };
        growl_hack_data[15:8] <= ~{ start[3], joystick_p4[6:4], joystick_p4[0], joystick_p4[1], joystick_p4[2], joystick_p4[3] };
    end
end

wire [14:0] obj_ram_addr;
wire [15:0] obj_dout;
wire [15:0] objram_data_out;
wire [11:0] obj_dot;

wire RCSn, BUSY, ORDWEn, DMAn;

reg obj_cpu_latch;

always @(posedge clk) if (ce_6m) obj_cpu_latch <= ~OBJECTn & (~BUSY | obj_cpu_latch);

wire OBJWEn = ~((BUSY & ~ORDWEn) | (~OBJECTn & ~cpu_rw & obj_cpu_latch));
wire UOBJRAMn = ~((BUSY & ~RCSn) | (~cpu_ds_n[1] & obj_cpu_latch));
wire LOBJRAMn = ~((BUSY & ~RCSn) | (~cpu_ds_n[0] & obj_cpu_latch));
wire [14:0] OBJ_ADD = (obj_cpu_latch & ~OBJECTn) ? cpu_addr[14:0] : obj_ram_addr;
wire [15:0] OBJ_DATA = (obj_cpu_latch & ~OBJECTn) ? cpu_data_out : obj_dout;
assign CPUENn = OBJECTn ? 0 : ~obj_cpu_latch;

wire [14:0] objram_addr;
wire [15:0] objram_data;
wire objram_lds_n, objram_uds_n;

m68k_ram #(.WIDTHAD(15)) obj_ram(
    .clock(clk),
    .address(objram_addr),
    .we_lds_n(objram_lds_n),
    .we_uds_n(objram_uds_n),
    .data(objram_data),
    .q(objram_data_out)
);

m68k_ram_ss_adaptor #(.WIDTHAD(15), .SS_IDX(SSIDX_OBJ_RAM)) objram_ss(
    .clk,
    .addr_in(OBJ_ADD),
    .lds_n_in(OBJWEn | LOBJRAMn),
    .uds_n_in(OBJWEn | UOBJRAMn),
    .data_in(OBJ_DATA),

    .q(objram_data_out),

    .addr_out(objram_addr),
    .lds_n_out(objram_lds_n),
    .uds_n_out(objram_uds_n),
    .data_out(objram_data),

    .ssbus(ssb[2])
);

wire obj_paused;
wire obj_code_modify_req;
wire [12:0] obj_code_original;
wire [18:0] obj_code_modified_ext;
wire [18:0] obj_code_modified_190fmc;

TC0200OBJ tc0200obj(
    .clk,

    .ce_13m,
    .ce_pixel,

    .pause(pause | ss_pause),
    .paused(obj_paused),

    .RA(obj_ram_addr),
    .Din(objram_data_out),
    .Dout(obj_dout),

    .RESET(reset),
    .ERCSn(RCSn), // TODO - what generates this
    .EBUSY(BUSY),
    .RDWEn(ORDWEn),

    .EDMAn(DMAn),

    .DOT(obj_dot),

    .EXHBLn(global_hcnt != cfg_hofs_200obj),
    .EXVBLn(global_vcnt != cfg_vofs_200obj),

    .HSYNCn,
    .VSYNCn,
    .HBLn,
    .VBLn,

    .sync_fix,

    .code_modify_req(obj_code_modify_req),
    .code_original(obj_code_original),
    .code_modified(cfg_190fmc ? obj_code_modified_190fmc : obj_code_modified_ext),

    .ddr(ddr_obj),

    .debug_idx(obj_debug_idx),

    .ssbus(ssb[3])
);

wire [15:0] extension_data;

TC0200OBJ_Extender tc0200obj_extender(
    .clk,

    .mode(cfg_obj_extender),

    .cs(~EXTENSIONn),
    .cpu_addr(cpu_addr[11:0]),
    .cpu_ds_n(cpu_ds_n),
    .cpu_rw(cpu_rw),
    .din(cpu_data_out),
    .dout(extension_data),

    .code_req(obj_code_modify_req),
    .code_original(obj_code_original),
    .code_modified(obj_code_modified_ext),
    .obj_addr(obj_ram_addr),

    .ssb(ssb[10])
);

TC0190FMC #(.SS_IDX(SSIDX_190FMC)) tc0190fmc(
    .clk,
    .reset,
    .cs(~EXTENSIONn),
    .cpu_rw,
    .cpu_ds_n(cpu_ds_n[0]),
    .cpu_addr(cpu_addr[2:0]),
    .cpu_din(cpu_data_out[7:0]),

    .code_req(obj_code_modify_req),
    .code_original(obj_code_original),
    .code_modified(obj_code_modified_190fmc),

    .ssbus(ssb[12])
);

wire HSYNCn;
wire VSYNCn;
wire HBLn;
wire VBLn;
wire HBLOn;
wire VBLOn;

wire [7:0] dar_red, dar_green, dar_blue;
wire dar_hblank_n, dar_vblank_n;

assign hsync = global_hsync;
assign vsync = global_vsync;
assign hblank = cfg_260dar ? ~dar_hblank_n : global_hblank;
assign vblank = cfg_260dar ? ~dar_vblank_n : global_vblank;

assign blue = cfg_260dar ? dar_blue : {color_ram_q[14:10], color_ram_q[14:12]};
assign green = cfg_260dar ? dar_green : {color_ram_q[9:5], color_ram_q[9:7]};
assign red = cfg_260dar ? dar_red : {color_ram_q[4:0], color_ram_q[4:2]};


//////////////////////////////////
//// SCREEN 0 TC0100SCN
wire [14:0] scn0_ram_addr;
wire [15:0] scn0_data_out;
wire [15:0] scn0_ram_din;
wire [15:0] scn0_ram_dout;
wire scn0_ram_we_up_n, scn0_ram_we_lo_n;
wire scn0_ram_ce_0_n, scn0_ram_ce_1_n;

wire [14:0] scn0_dot_color;

wire [14:0] scn_ram_0_addr;
wire [15:0] scn_ram_0_data;
wire scn_ram_0_lds_n, scn_ram_0_uds_n;

m68k_ram #(.WIDTHAD(15)) scn_ram_0(
    .clock(clk),
    .address(scn_ram_0_addr),
    .we_lds_n(scn_ram_0_lds_n),
    .we_uds_n(scn_ram_0_uds_n),
    .data(scn_ram_0_data),
    .q(scn0_ram_din)
);

m68k_ram_ss_adaptor #(.WIDTHAD(15), .SS_IDX(SSIDX_SCN_RAM_0)) scn_ram_0_ss(
    .clk,
    .addr_in(scn0_ram_addr),
    .lds_n_in(scn0_ram_ce_0_n | scn0_ram_we_lo_n),
    .uds_n_in(scn0_ram_ce_0_n | scn0_ram_we_up_n),
    .data_in(scn0_ram_dout),

    .q(scn0_ram_din),

    .addr_out(scn_ram_0_addr),
    .lds_n_out(scn_ram_0_lds_n),
    .uds_n_out(scn_ram_0_uds_n),
    .data_out(scn_ram_0_data),

    .ssbus(ssb[4])
);


wire [20:0] scn0_rom_address;
assign sdr_scn0_addr = SCN0_ROM_SDR_BASE[26:0] + { 6'b0, scn0_rom_address[20:0] };

TC0100SCN #(.SS_IDX(SSIDX_SCN_0)) scn0(
    .clk(clk),
    .ce_13m(ce_13m),
    .ce_pixel,

    .reset,

    // CPU interface
    .VA(cpu_word_addr[17:0]),
    .Din(cpu_data_out),
    .Dout(scn0_data_out),
    .LDSn(cpu_ds_n[0]),
    .UDSn(cpu_ds_n[1]),
    .SCCSn(SCREEN0n),
    .RW(cpu_rw),
    .DACKn(SDTACK0n),

    // RAM interface
    .SA(scn0_ram_addr),
    .SDin(scn0_ram_din),
    .SDout(scn0_ram_dout),
    .WEUPn(scn0_ram_we_up_n),
    .WELOn(scn0_ram_we_lo_n),
    .SCE0n(scn0_ram_ce_0_n),
    .SCE1n(scn0_ram_ce_1_n),

    // ROM interface
    .rom_address(scn0_rom_address),
    .rom_req(sdr_scn0_req),
    .rom_ack(sdr_scn0_ack),
    .rom_data(sdr_scn0_q),

    // Video interface
    .SC(scn0_dot_color),
    .HSYNn(),
    .HBLOn,
    .VSYNn(),
    .VBLOn,
    .OLDH(),
    .OLDV(),
    .IHLD(global_hcnt == cfg_hofs_100scn0),
    .IVLD(global_vcnt == cfg_vofs_100scn0),

    .ssbus(ssb[5])
);

//////////////////////////////////
//// SCREEN 1 TC0100SCN
wire [14:0] scn1_ram_addr;
wire [15:0] scn1_data_out;
wire [15:0] scn1_ram_data;
wire scn1_ram_we_up_n, scn1_ram_we_lo_n;
wire scn1_ram_ce_0_n, scn1_ram_ce_1_n;


wire [14:0] scn_mux_ram_addr;
wire [15:0] scn_mux_ram_data;
wire [15:0] scn_mux_ram_q;
wire scn_mux_ram_lds_n, scn_mux_ram_uds_n;

m68k_ram #(.WIDTHAD(15)) scn_mux_ram(
    .clock(clk),
    .address(scn_mux_ram_addr),
    .we_lds_n(scn_mux_ram_lds_n),
    .we_uds_n(scn_mux_ram_uds_n),
    .data(scn_mux_ram_data),
    .q(scn_mux_ram_q)
);

m68k_ram_ss_adaptor #(.WIDTHAD(15), .SS_IDX(SSIDX_SCN_MUX_RAM)) scn_mux_ram_ss(
    .clk,
    .addr_in(cfg_100scn ? scn1_ram_addr : scp_ram_addr),
    .lds_n_in(cfg_100scn ? (scn1_ram_ce_0_n | scn1_ram_we_lo_n) : (scp_ram_ce_n | scp_ram_we_lo_n)),
    .uds_n_in(cfg_100scn ? (scn1_ram_ce_0_n | scn1_ram_we_up_n) : (scp_ram_ce_n | scp_ram_we_up_n)),
    .data_in(cfg_100scn ? scn1_ram_data : scp_ram_data),

    .q(scn_mux_ram_q),

    .addr_out(scn_mux_ram_addr),
    .lds_n_out(scn_mux_ram_lds_n),
    .uds_n_out(scn_mux_ram_uds_n),
    .data_out(scn_mux_ram_data),

    .ssbus(ssb[16])
);

wire [14:0] scn1_dot_color;

wire [20:0] scn1_rom_address;
assign sdr_scn1_addr = SCN1_ROM_SDR_BASE[26:0] + { 6'b0, scn1_rom_address[20:0] };

TC0100SCN #(.SS_IDX(SSIDX_SCN_1)) scn1(
    .clk(clk),
    .ce_13m(ce_13m),
    .ce_pixel,

    .reset,

    // CPU interface
    .VA(cpu_word_addr[17:0]),
    .Din(cpu_data_out),
    .Dout(scn1_data_out),
    .LDSn(cpu_ds_n[0]),
    .UDSn(cpu_ds_n[1]),
    .SCCSn(cfg_100scn ? SCREEN1n : 1'b1),
    .RW(cpu_rw),
    .DACKn(SDTACK1n),

    // RAM interface
    .SA(scn1_ram_addr),
    .SDin(scn_mux_ram_q),
    .SDout(scn1_ram_data),
    .WEUPn(scn1_ram_we_up_n),
    .WELOn(scn1_ram_we_lo_n),
    .SCE0n(scn1_ram_ce_0_n),
    .SCE1n(scn1_ram_ce_1_n),

    // ROM interface
    .rom_address(scn1_rom_address),
    .rom_req(sdr_scn1_req),
    .rom_ack(sdr_scn_mux_ack),
    .rom_data(sdr_scn_mux_q[31:0]),

    // Video interface
    .SC(scn1_dot_color),
    .HSYNn(),
    .HBLOn(),
    .VSYNn(),
    .VBLOn(),
    .OLDH(),
    .OLDV(),
    .IHLD(global_hcnt == cfg_hofs_100scn1),
    .IVLD(global_vcnt == cfg_vofs_100scn1),

    .ssbus(ssb[17])
);

//////////////////////////////////
//// SCREEN 1 TC0480SCP
wire [14:0] scp_ram_addr;
wire [15:0] scp_data_out;
wire [15:0] scp_ram_data;
wire scp_ram_we_up_n, scp_ram_we_lo_n;
wire scp_ram_ce_n;

wire [15:0] scp_dot_color;

wire [22:0] scp_rom_address;

assign sdr_scp_addr = SCN1_ROM_SDR_BASE[26:0] + { 4'b0, scp_rom_address[22:0] };

logic [15:0] sync_xofs;
logic [15:0] sync_yofs;

always_comb begin
    case (game)
        GAME_DEADCONXJ: begin sync_xofs = -11; sync_yofs = -17; end
        GAME_DEADCONX:  begin sync_xofs = -33; sync_yofs = -30; end
        GAME_METALB:    begin sync_xofs = -11; sync_yofs = -18; end
        default: begin sync_xofs = 0; sync_yofs = 0; end
    endcase
end


TC0480SCP #(.SS_IDX(SSIDX_480SCP)) tc0480scp(
    .clk(clk),
    .ce(ce_pixel), // FIXME: scn0 should be authorative here

    .reset,

    // CPU interface
    .VA(cpu_word_addr[17:0]),
    .VDin(cpu_data_out),
    .VDout(scp_data_out),
    .LDSn(cpu_ds_n[0]),
    .UDSn(cpu_ds_n[1]),
    .CSn(cfg_480scp ? SCREEN1n : 1'b1),
    .RW(cpu_rw),
    .VDTACKn(VDTACKn),

    // RAM interface
    .RA(scp_ram_addr),
    .RADOEn(scp_ram_ce_n),
    .RADin(scn_mux_ram_q),
    .RADout(scp_ram_data),
    .RWAHn(scp_ram_we_up_n),
    .RWALn(scp_ram_we_lo_n),

    // ROM interface
    .rom_address(scp_rom_address),
    .rom_req(sdr_scp_req),
    .rom_ack(sdr_scn_mux_ack),
    .rom_data(sdr_scn_mux_q),

    .devils_bit(game == GAME_METALB),

    // Video interface
    .SD(scp_dot_color),
    .HSYNn(),
    .HBLNn(),
    .VSYNn(),
    .VBLNn(),
    .HLDn(),
    .VLDn(),
    .OUHLDn(global_hcnt != cfg_hofs_480scp),
    .OUVLDn(global_vcnt != cfg_vofs_480scp),

    .sync_xofs,
    .sync_yofs,

    .ssbus(ssb[18])
);



wire [11:0] pivot_ram_addr;
wire [15:0] pivot_ram_data;
wire [15:0] pivot_ram_q;
wire pivot_ram_we_up_n, pivot_ram_we_lo_n;

wire [11:0] pivot_ram_addr1;
wire [15:0] pivot_ram_data1;
wire pivot_ram_lds_n, pivot_ram_uds_n;

m68k_ram #(.WIDTHAD(12)) pivot_ram(
    .clock(clk),
    .address(pivot_ram_addr1),
    .we_lds_n(pivot_ram_lds_n),
    .we_uds_n(pivot_ram_uds_n),
    .data(pivot_ram_data1),
    .q(pivot_ram_q)
);

m68k_ram_ss_adaptor #(.WIDTHAD(12), .SS_IDX(SSIDX_PIVOT_RAM)) pivot_ram_ss(
    .clk,
    .addr_in(pivot_ram_addr),
    .lds_n_in(pivot_ram_we_lo_n),
    .uds_n_in(pivot_ram_we_up_n),
    .data_in(pivot_ram_data),

    .q(pivot_ram_q),

    .addr_out(pivot_ram_addr1),
    .lds_n_out(pivot_ram_lds_n),
    .uds_n_out(pivot_ram_uds_n),
    .data_out(pivot_ram_data1),

    .ssbus(ssb[14])
);


wire [15:0] pivot_dout;
wire [5:0] pivot_dot;

TC0430GRW #(.SS_IDX(SSIDX_PIVOT_CTRL)) tc0430grw(
    .clk,
    .ce_13m,
    .ce_pixel,

    .reset,

    .is_280grd(cfg_280grd),

    .VA(cpu_addr[12:0]),
    .Din(cpu_data_out),
    .Dout(pivot_dout),
    .LDSn(cpu_ds_n[0]),
    .UDSn(cpu_ds_n[1]),
    .SCCSn(PIVOTn),
    .RW(cpu_rw),
    .DACKn(pivot_dtack_n),

    .SA(pivot_ram_addr),
    .SDin(pivot_ram_q),
    .SDout(pivot_ram_data),
    .WEUPn(pivot_ram_we_up_n),
    .WELOn(pivot_ram_we_lo_n),

    .rom_address(sdr_pivot_addr),
    .rom_data(sdr_scn_mux_q[15:0]),
    .rom_req(sdr_pivot_req),
    .rom_ack(sdr_scn_32_ack),

    .SC(pivot_dot),

    .HBLANKn(global_hcnt != cfg_hofs_430grw),
    .VBLANKn(global_vcnt != cfg_vofs_430grw),

    .ssbus(ssb[15])
);

wire [15:0] color_ram_q;
wire [15:0] color_ram_data;
wire [13:0] color_ram_address;
wire color_ram_lds_n, color_ram_uds_n;

m68k_ram #(.WIDTHAD(14)) color_ram(
    .clock(clk),
    .address(color_ram_address),
    .we_lds_n(color_ram_lds_n),
    .we_uds_n(color_ram_uds_n),
    .data(color_ram_data),
    .q(color_ram_q)
);

wire [15:0] pri_data_out;
wire [12:0] pri_ram_addr;
wire [15:0] pri_ram_dout;
wire pri_ram_we_l_n, pri_ram_we_h_n;

wire [15:0] dar_data_out;
wire [13:0] dar_ram_addr;
wire [15:0] dar_ram_dout;
wire dar_ram_we_l_n, dar_ram_we_h_n;


m68k_ram_ss_adaptor #(.WIDTHAD(14), .SS_IDX(SSIDX_COLOR_RAM)) color_ram_ss(
    .clk,
    .addr_in(cfg_260dar ? dar_ram_addr : {2'b0, pri_ram_addr[12:1]}),
    .lds_n_in(cfg_260dar ? dar_ram_we_l_n : pri_ram_we_l_n),
    .uds_n_in(cfg_260dar ? dar_ram_we_h_n : pri_ram_we_h_n),
    .data_in(cfg_260dar ? dar_ram_dout : pri_ram_dout),

    .q(color_ram_q),

    .addr_out(color_ram_address),
    .lds_n_out(color_ram_lds_n),
    .uds_n_out(color_ram_uds_n),
    .data_out(color_ram_data),

    .ssbus(ssb[6])
);


TC0110PR tc0110pr(
    .clk,
    .ce_pixel,

    // CPU Interface
    .Din(cpu_data_out),
    .Dout(pri_data_out),

    .VA(cpu_addr[1:0]),
    .RWn(cpu_rw),
    .UDSn(cpu_ds_n[1]),
    .LDSn(cpu_ds_n[0]),

    .SCEn(COLORn),
    .DACKn(CDTACKn),

    // Video Input
    .HSYn(HSYNCn),
    .VSYn(VSYNCn),

    .SC(scn0_dot_color),
    .OB({3'b0, obj_dot}),

    // RAM Interface
    .CA(pri_ram_addr),
    .CDin(color_ram_q),
    .CDout(pri_ram_dout),
    .WELn(pri_ram_we_l_n),
    .WEHn(pri_ram_we_h_n)
);

wire [12:0] pri360_color;
wire [7:0] pri360_data_out;

logic [14:0] color0_pri, color1_pri, color2_pri;

always_comb begin
    color1_pri = {obj_dot[11:10], 1'b0, obj_dot[11:0]};
    if (cfg_480scp) begin
        if (game == GAME_METALB) begin
            color0_pri = {{scp_dot_color[14], scp_dot_color[13]} - 2'b01, scp_dot_color[12:0]};
            if (scp_dot_color[15:13] == 3'b101)
                color2_pri = {2'b10, scp_dot_color[12:0]};
            else
                color2_pri = {2'b00, scp_dot_color[12:0]};
        end else begin
            color0_pri = {scp_dot_color[14], scp_dot_color[13], scp_dot_color[12:0]};
            color2_pri = {scp_dot_color[15], scp_dot_color[13], scp_dot_color[12:0]};
        end
     end else begin
        color0_pri = {scn0_dot_color[14:13], scn0_dot_color[12:0]};
        if (cfg_100scn) begin
            color2_pri = {scn1_dot_color[14:13], scn1_dot_color[12:0]};
        end else if (cfg_430grw | cfg_280grd) begin
            color2_pri = { 9'd0, pivot_dot };
        end else begin
            color2_pri = 15'd0;
        end
    end
end

TC0360PRI #(.SS_IDX(SSIDX_PRIORITY)) tc0360pri(
    .clk,
    .ce_pixel,
    .reset,

    .cpu_addr(cpu_addr[3:0]),
    .cpu_din(cfg_360pri_high ? cpu_data_out[15:8] : cpu_data_out[7:0]),
    .cpu_dout(pri360_data_out),
    .cpu_ds_n(cfg_360pri_high ? cpu_ds_n[1] : cpu_ds_n[0]),
    .cpu_rw,
    .cs(~PRIORITYn),

    .fullwidth(cfg_100scn | cfg_480scp),

    .color_in0(color0_pri),
    .color_in1(color1_pri),
    .color_in2(color2_pri),
    .color_out(pri360_color),

    .ssbus(ssb[11])
);

TC0260DAR tc0260dar(
    .clk,
    .ce_pixel,
    .ce_double(ce_13m),

    .bpp15(cfg_bpp15),
    .bppmix(cfg_bppmix),

    // CPU Interface
    .MDin(cpu_data_out),
    .MDout(dar_data_out),

    .MA(cpu_addr[13:0]),
    .RWn(cpu_rw),
    .UDSn(cpu_ds_n[1]),
    .LDSn(cpu_ds_n[0]),

    .CS(~COLORn),
    .DTACKn(dar_dtack_n),

    // FIXME : some boards can control this
    .ACCMODE(~cfg_260dar_acc),

    // Video Input
    .HBLANKn(~global_hblank),
    .VBLANKn(~global_vblank),
    .OHBLANKn(dar_hblank_n),
    .OVBLANKn(dar_vblank_n),

    .IM(cfg_360pri ? { 1'b0, pri360_color[12:0] } : (|obj_dot[3:0]) ? { 2'b00, obj_dot } : { 1'b0, scn0_dot_color[12:0] } ),

    .VIDEOR(dar_red),
    .VIDEOG(dar_green),
    .VIDEOB(dar_blue),

    // RAM Interface
    .RA(dar_ram_addr),
    .RDin(color_ram_q),
    .RDout(dar_ram_dout),
    .RWELn(dar_ram_we_l_n),
    .RWEHn(dar_ram_we_h_n)
);



//////////////////////////////////
//// Interrupt Processing
wire ICLR1n = ~(~IACKn & (cpu_addr[2:0] == 3'b101) & ~cpu_ds_n[0]);
wire ICLR2n = ~(~IACKn & (cpu_addr[2:0] == 3'b110) & ~cpu_ds_n[0]);

reg int_req1, int_req2;
reg vbl_prev, dma_prev;

assign IPLn = ss_irq ? ~3'b111 :
              int_req2 ? ~3'b110 :
              int_req1 ? ~3'b101 :
              ~3'b000;

always_ff @(posedge clk) begin
    vbl_prev <= VBLn;
    dma_prev <= DMAn;

    if (reset) begin
        int_req2 <= 0;
        int_req1 <= 0;
    end else begin
        if (vbl_prev & ~VBLn) begin
            int_req1 <= 1;
        end
        if (~dma_prev & DMAn) begin
            int_req2 <= 1;
        end

        if (~ICLR1n) begin
            int_req1 <= 0;
        end

        if (~ICLR2n) begin
            int_req2 <= 0;
        end
    end
end

logic SS_SAVEn, SS_RESETn, SS_VECn;

address_translator address_translator(
    .game,
    .cpu_ds_n,
    .cpu_word_addr,

    .ss_override,

    .cfg_addr_rom,
    .cfg_addr_rom1,
    .cfg_addr_extra_rom,
    .cfg_addr_work_ram,
    .cfg_addr_screen0,
    .cfg_addr_screen1,
    .cfg_addr_obj,
    .cfg_addr_color,
    .cfg_addr_io0,
    .cfg_addr_io1,
    .cfg_addr_sound,
    .cfg_addr_extension,
    .cfg_addr_priority,
    .cfg_addr_roz,
    .cfg_addr_cchip,

    .WORKn,
    .ROMn,
    .EXTRA_ROMn,
    .SCREEN0n,
    .SCREEN1n,
    .COLORn,
    .IO0n,
    .IO1n,
    .OBJECTn,
    .PRIORITYn,
    .SOUNDn,
    .GROWL_HACKn,
    .EXTENSIONn,
    .CCHIPn,
    .PIVOTn,

    .SS_SAVEn,
    .SS_RESETn,
    .SS_VECn
);

assign cpu_data_in = ~SS_SAVEn ? ss_irq_handler[cpu_addr[3:0]] :
                     ~SS_RESETn ? ss_reset_vector[cpu_addr[1:0]] :
                     ~SS_VECn ? ( cpu_addr[0] ? 16'h0000 : 16'h00ff ) :
                     ~ROMn ? rom_q :
                     ~WORKn ? workram_q :
                     ~SCREEN0n ? scn0_data_out :
                     ~SCREEN1n ? ( cfg_100scn ? scn1_data_out : scp_data_out ) :
                     ~OBJECTn ? objram_data_out :
                     ~PRIORITYn ? { pri360_data_out, pri360_data_out } :
                     ~COLORn ? (cfg_260dar ? dar_data_out : pri_data_out) :
                     (~IO0n | ~IO1n) ? { io_data_out, io_data_out } :
                     ~SOUNDn ? { 4'd0, syt_cpu_dout, 8'd0 } :
                     ~EXTENSIONn ? extension_data :
                     ~GROWL_HACKn ? growl_hack_data :
                     ~CCHIPn ? { 8'h00, cchip_data } :
                     ~PIVOTn ? { pivot_dout } :
                     16'd0;

wire [14:0] workram_addr;
wire workram_lds_n, workram_uds_n;
wire [15:0] workram_data, workram_q;

m68k_ram #(.WIDTHAD(15)) work_ram(
    .clock(clk),
    .address(workram_addr),
    .we_lds_n(workram_lds_n),
    .we_uds_n(workram_uds_n),
    .data(workram_data),
    .q(workram_q)
);

m68k_ram_ss_adaptor #(.WIDTHAD(15), .SS_IDX(SSIDX_CPU_RAM)) workram_ss(
    .clk,
    .addr_in(cpu_addr[14:0]),
    .lds_n_in(WORKn | cpu_ds_n[0] | cpu_rw),
    .uds_n_in(WORKn | cpu_ds_n[1] | cpu_rw),
    .data_in(cpu_data_out),

    .q(workram_q),

    .addr_out(workram_addr),
    .lds_n_out(workram_lds_n),
    .uds_n_out(workram_uds_n),
    .data_out(workram_data),

    .ssbus(ssb[1])
);

reg prev_ds_n;

wire pre_sdr_dtack_n = ~ROMn & prev_ds_n;
wire [15:0] rom_q;

assign cpu1_rom_addr = (EXTRA_ROMn ? CPU_ROM_SDR_BASE[26:0] : CPU_EXTRA_ROM_SDR_BASE[26:0]) + cpu_word_addr;
assign rom_q = cpu1_rom_q;
assign cpu1_rom_cs = ~(ROMn | cpu_as_n);
assign sdr_dtack_n = cpu1_rom_cs & ~cpu1_rom_valid;

always_ff @(posedge clk) begin
    prev_ds_n <= cpu_as_n;
end

wire [7:0] cchip_data;

TC0030CMD tc0030cmd(
    .clk,
    .ce(ce_12m),

    .RESETn(~reset),
    .NMIn(1),
    .INT1n(1),
    .ASIC_MODESEL(0),
    .MODE1(0),
    .AN(0),

    // CPU interface
    .CSn(CCHIPn),
    .RW(cpu_rw),
    .Din(cpu_data_out[7:0]),
    .Dout(cchip_data),
    .A(cpu_addr[10:0]),
    .DTACKn(),

    // Ports
    .PAin(0),
    .PBin(0),
    .PCin(0),
    .PAout(),
    .PBout(),
    .PCout(),

    .ssb(ssb[13])
);


//////////////////////////////////
// AUDIO
//

wire [15:0] audio_left, audio_right;
wire [9:0] psg_snd;
wire audio_sample;

wire [15:0] SND_ADD;
wire SRAMn, SNWRn, SNRDn, RFSHn, ROMCS0n, ROMCS1n;
wire ROMA14, ROMA15;
wire SNRESn;
wire SNINTn;
wire SNMREQn;
wire OP_Tn;

wire [3:0] syt_z80_dout, syt_cpu_dout;
wire [7:0] z80_dout;
wire [7:0] ym_dout;
wire [7:0] sound_ram_q, sound_rom0_q;
wire       sound_ram_wren;
wire [7:0] sound_ram_data;
wire [12:0] sound_ram_addr;
wire [23:0] YAA, YBA;
wire [7:0] YAD, YBD;
wire AOEn, BOEn;

wire [7:0] z80_din = (~ROMCS0n | ~ROMCS1n) ? sound_rom0_q :
                        ~SRAMn ? sound_ram_q :
                        ~OP_Tn ? ym_dout :
                        { 4'd0, syt_z80_dout};


ram_ss_adaptor #(.WIDTH(8), .WIDTHAD(13), .SS_IDX(SSIDX_AUDIO_RAM)) sound_ram_ss(
    .clk,

    .wren_in(~SRAMn & ~SNWRn),
    .addr_in(SND_ADD[12:0]),
    .data_in(z80_dout),

    .wren_out(sound_ram_wren),
    .addr_out(sound_ram_addr),
    .data_out(sound_ram_data),

    .q(sound_ram_q),

    .ssbus(ssb[7])
);

singleport_ram #(.WIDTH(8), .WIDTHAD(13)) sound_ram(
    .clock(clk),
    .wren(sound_ram_wren),
    .address(sound_ram_addr),
    .data(sound_ram_data),
    .q(sound_ram_q)
);

assign cpu2_rom_addr = AUDIO_ROM_SDR_BASE[23:0] + {ROMCS0n, ROMA15, ROMA14, SND_ADD[13:0]};
assign sound_rom0_q = SND_ADD[0] ? cpu2_rom_q[15:8] : cpu2_rom_q[7:0];
assign cpu2_rom_cs = (~ROMCS0n | ~ROMCS1n) & RFSHn & ~SNMREQn;

`ifdef USE_AUTO_SS
wire [31:0] z80_ss_in, z80_ss_out;
wire z80_ss_wr, z80_ss_rd, z80_ss_ack;
wire [15:0] z80_ss_state_idx;
wire [7:0] z80_ss_device_idx;

auto_save_adaptor2 #(.SS_IDX(SSIDX_Z80)) z80_ss_adaptor(
    .clk,
    .ssbus(ssb[8]),
    .rd(z80_ss_rd),
    .wr(z80_ss_wr),
    .ack(z80_ss_ack),
    .device_idx(z80_ss_device_idx),
    .state_idx(z80_ss_state_idx),
    .wr_data(z80_ss_in),
    .rd_data(z80_ss_out)
);
`endif

t80s z80(

`ifdef USE_AUTO_SS
    .auto_ss_rd(z80_ss_rd),
    .auto_ss_wr(z80_ss_wr),
    .auto_ss_device_idx(z80_ss_device_idx),
    .auto_ss_state_idx(z80_ss_state_idx),
    .auto_ss_base_device_idx(0),
    .auto_ss_data_in(z80_ss_in),
    .auto_ss_data_out(z80_ss_out),
    .auto_ss_ack(z80_ss_ack),
`endif

    .clk(clk),
    .cen(ce_4m),
    .reset_n(SNRESn),
    .wait_n(~cpu2_rom_cs | cpu2_rom_valid),
    .int_n(SNINTn),
    .nmi_n(1),
    .busrq_n(1),
    .m1_n(),
    .mreq_n(SNMREQn),
    .iorq_n(),
    .rd_n(SNRDn),
    .wr_n(SNWRn),
    .rfsh_n(RFSHn),
    .halt_n(),
    .busak_n(),
    .A(SND_ADD),
    .DI(z80_din),
    .DO(z80_dout)
);


`ifdef USE_AUTO_SS
wire [31:0] ym_ss_in, ym_ss_out;
wire ym_ss_wr, ym_ss_rd, ym_ss_ack;
wire [15:0] ym_ss_state_idx;
wire [7:0] ym_ss_device_idx;

auto_save_adaptor2 #(.SS_IDX(SSIDX_YM)) ym_ss_adaptor(
    .clk,
    .ssbus(ssb[9]),
    .rd(ym_ss_rd),
    .wr(ym_ss_wr),
    .ack(ym_ss_ack),
    .device_idx(ym_ss_device_idx),
    .state_idx(ym_ss_state_idx),
    .wr_data(ym_ss_in),
    .rd_data(ym_ss_out)
);
`endif

jt10 jt10(
`ifdef USE_AUTO_SS
    .auto_ss_rd(ym_ss_rd),
    .auto_ss_wr(ym_ss_wr),
    .auto_ss_device_idx(ym_ss_device_idx),
    .auto_ss_state_idx(ym_ss_state_idx),
    .auto_ss_base_device_idx(0),
    .auto_ss_data_in(ym_ss_in),
    .auto_ss_data_out(ym_ss_out),
    .auto_ss_ack(ym_ss_ack),
`endif

    .rst(~SNRESn),
    .clk(clk),
    .cen(ce_8m),
    .din(z80_dout),
    .addr(SND_ADD[1:0]),
    .cs_n(OP_Tn),
    .wr_n(SNWRn),

    .dout(ym_dout),
    .irq_n(SNINTn),

    .adpcma_addr(YAA[19:0]),
    .adpcma_bank(YAA[23:20]),
    .adpcma_roe_n(AOEn),
    .adpcma_data(YAD),
    .adpcmb_addr(YBA[23:0]),
    .adpcmb_roe_n(BOEn),
    .adpcmb_data(YBD),

    .psg_A(),
    .psg_B(),
    .psg_C(),
    .fm_snd(),

    .psg_snd(psg_snd),
    .snd_right(audio_right),
    .snd_left(audio_left),
    .snd_sample(audio_sample),
    .ch_enable(6'b111111)
);

TC0140SYT tc0140syt(
    .clk,
    .ce_12m,
    .ce_4m,

    .RESn(~reset), // FIXME

    .MDin(cpu_data_out[11:8]),
    .MDout(syt_cpu_dout),
    .MA1(cpu_addr[0]),
    .MCSn(SOUNDn),
    .MRDn(~cpu_rw),
    .MWRn(cpu_rw),

    .MREQn(SNMREQn),
    .RDn(SNRDn),
    .WRn(SNWRn),
    .A(SND_ADD),
    .Din(z80_dout[3:0]),
    .Dout(syt_z80_dout),

    .ROUTn(SNRESn),
    .ROMCS0n(ROMCS0n),
    .ROMCS1n(ROMCS1n),
    .RAMCSn(SRAMn),
    .ROMA14(ROMA14),
    .ROMA15(ROMA15),

    .OPXn(OP_Tn),
    .YAOEn(AOEn),
    .YBOEn(BOEn),
    .YAA(YAA),
    .YBA(YBA),
    .YAD(YAD),
    .YBD(YBD),

    .CSAn(),
    .CSBn(),
    .IOA(),
    .IOC(), // FIXME: mute

    .sdr_address(sdr_audio_addr),
    .sdr_data(sdr_audio_q),
    .sdr_req(sdr_audio_req),
    .sdr_ack(sdr_audio_ack)
);

audio_mix audio_mix(
    .clk,
    .reset,

    .fm_sample(audio_sample),
    .fm_left(audio_left),
    .fm_right(audio_right),
    .psg(psg_snd),

    .mono_output(audio_out)
);

save_state_data save_state_data(
    .clk,
    .reset(0),

    .ddr(ddr_ss),

    .index(ss_index),
    .read_start(ss_read),
    .write_start(ss_write),
    .busy(ss_busy),

    .ssbus(ssbus)
);


endmodule
