module F2_MiST(
	input         CLOCK_27,
`ifdef USE_CLOCK_50
	input         CLOCK_50,
`endif

	output        LED,
	output [VGA_BITS-1:0] VGA_R,
	output [VGA_BITS-1:0] VGA_G,
	output [VGA_BITS-1:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,

`ifdef USE_HDMI
	output        HDMI_RST,
	output  [7:0] HDMI_R,
	output  [7:0] HDMI_G,
	output  [7:0] HDMI_B,
	output        HDMI_HS,
	output        HDMI_VS,
	output        HDMI_PCLK,
	output        HDMI_DE,
	inout         HDMI_SDA,
	inout         HDMI_SCL,
	input         HDMI_INT,
`endif

	input         SPI_SCK,
	inout         SPI_DO,
	input         SPI_DI,
	input         SPI_SS2,    // data_io
	input         SPI_SS3,    // OSD
	input         CONF_DATA0, // SPI_SS for user_io

`ifdef USE_QSPI
	input         QSCK,
	input         QCSn,
	inout   [3:0] QDAT,
`endif
`ifndef NO_DIRECT_UPLOAD
	input         SPI_SS4,
`endif

	output [12:0] SDRAM_A,
	inout  [15:0] SDRAM_DQ,
	output        SDRAM_DQML,
	output        SDRAM_DQMH,
	output        SDRAM_nWE,
	output        SDRAM_nCAS,
	output        SDRAM_nRAS,
	output        SDRAM_nCS,
	output  [1:0] SDRAM_BA,
	output        SDRAM_CLK,
	output        SDRAM_CKE,

`ifdef DUAL_SDRAM
	output [12:0] SDRAM2_A,
	inout  [15:0] SDRAM2_DQ,
	output        SDRAM2_DQML,
	output        SDRAM2_DQMH,
	output        SDRAM2_nWE,
	output        SDRAM2_nCAS,
	output        SDRAM2_nRAS,
	output        SDRAM2_nCS,
	output  [1:0] SDRAM2_BA,
	output        SDRAM2_CLK,
	output        SDRAM2_CKE,
`endif

	output        AUDIO_L,
	output        AUDIO_R,
`ifdef I2S_AUDIO
	output        I2S_BCK,
	output        I2S_LRCK,
	output        I2S_DATA,
`endif
`ifdef I2S_AUDIO_HDMI
	output        HDMI_MCLK,
	output        HDMI_BCK,
	output        HDMI_LRCK,
	output        HDMI_SDATA,
`endif
`ifdef SPDIF_AUDIO
	output        SPDIF,
`endif
`ifdef USE_AUDIO_IN
	input         AUDIO_IN,
`endif
	input         UART_RX,
	output        UART_TX

);

`ifdef NO_DIRECT_UPLOAD
localparam bit DIRECT_UPLOAD = 0;
wire SPI_SS4 = 1;
`else
localparam bit DIRECT_UPLOAD = 1;
`endif

`ifdef USE_QSPI
localparam bit QSPI = 1;
assign QDAT = 4'hZ;
`else
localparam bit QSPI = 0;
`endif

`ifdef VGA_8BIT
localparam VGA_BITS = 8;
`else
localparam VGA_BITS = 6;
`endif

`ifdef USE_HDMI
localparam bit HDMI = 1;
assign HDMI_RST = 1'b1;
`else
localparam bit HDMI = 0;
`endif

`ifdef BIG_OSD
localparam bit BIG_OSD = 1;
`define SEP "-;",
`else
localparam bit BIG_OSD = 0;
`define SEP
`endif

// remove this if the 2nd chip is actually used
/*
`ifdef DUAL_SDRAM
assign SDRAM2_A = 13'hZZZZ;
assign SDRAM2_BA = 0;
assign SDRAM2_DQML = 0;
assign SDRAM2_DQMH = 0;
assign SDRAM2_CKE = 0;
assign SDRAM2_CLK = 0;
assign SDRAM2_nCS = 1;
assign SDRAM2_DQ = 16'hZZZZ;
assign SDRAM2_nCAS = 1;
assign SDRAM2_nRAS = 1;
assign SDRAM2_nWE = 1;
`endif
*/
`include "build_id.v"
//`define DEBUG 1
`define CORE_NAME "MEGABLST"

wire [6:0] core_mod;

localparam CONF_STR = {
	`CORE_NAME,";;",
	"O3,Rotate Controls,Off,On;",
	"O45,Scanlines,Off,25%,50%,75%;",
	"O6,Swap Joystick,Off,On;",
	"O7,Blending,Off,On;",
	"O8,Pause,Off,On;",
	"OF,Audio Filters,On,Off;",
	`SEP
	"DIP;",
	`SEP
	"T0,Reset;",
	"V,v1.0.",`BUILD_DATE
};

wire        rotate    = status[3];
wire  [1:0] scanlines = status[5:4];
wire        joyswap   = status[6];
wire        system_pause = status[8];
wire  [1:0] orientation = {flipped, core_mod[0]};
reg         oneplayer = 0;
wire  [7:0] dswa = ~status[23:16];
wire  [7:0] dswb = ~status[31:24];
wire        blend   = status[7];
wire        filters = ~status[15];

assign LED = ~ioctl_downl;
assign SDRAM_CKE = 1; 

wire clk_sdr, clk_sys;
wire pll_locked;
pll_mist pll(
	.inclk0(CLOCK_27),
	.c0(SDRAM_CLK),
	.c1(clk_sdr),
	.c2(clk_sys),
	.locked(pll_locked)
	);

wire pll2_locked, clk_sdr2;
pll_mist pll_rot(
	.inclk0(CLOCK_27),
	.c0(SDRAM2_CLK),
	.c1(clk_sdr2),
	.locked(pll2_locked)
	);
assign SDRAM2_CKE = 1;

wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire [15:0] joystick_0;
wire [15:0] joystick_1;
wire [15:0] joystick_2;
wire [15:0] joystick_3;
wire        scandoublerD;
wire        ypbpr;
wire        no_csync;
wire        key_pressed;
wire  [7:0] key_code;
wire        key_strobe;

wire  [9:0] conf_str_addr;
wire  [7:0] conf_str_char;

always @(posedge clk_sys) 
	conf_str_char <= CONF_STR[(($size(CONF_STR)>>3) - conf_str_addr - 1)<<3 +:8];

`ifdef USE_HDMI
wire        i2c_start;
wire        i2c_read;
wire  [6:0] i2c_addr;
wire  [7:0] i2c_subaddr;
wire  [7:0] i2c_dout;
wire  [7:0] i2c_din;
wire        i2c_ack;
wire        i2c_end;

`endif
user_io #(
	//.STRLEN(($size(CONF_STR)>>3)),
	.ROM_DIRECT_UPLOAD(DIRECT_UPLOAD),
	.FEATURES(32'h0 | (BIG_OSD << 13) | (HDMI << 14)))
user_io(
	.clk_sys        (clk_sys        ),
	.conf_str       (CONF_STR       ),
	.SPI_CLK        (SPI_SCK        ),
	.SPI_SS_IO      (CONF_DATA0     ),
	.SPI_MISO       (SPI_DO         ),
	.SPI_MOSI       (SPI_DI         ),
	.conf_addr      (conf_str_addr  ),
	.conf_chr       (conf_str_char  ),
	.buttons        (buttons        ),
	.switches       (switches       ),
	.core_mod       (core_mod       ),
	.key_strobe     (key_strobe     ),
	.key_pressed    (key_pressed    ),
	.key_code       (key_code       ),
	.joystick_0     (joystick_0     ),
	.joystick_1     (joystick_1     ),
	.joystick_2     (joystick_2     ),
	.joystick_3     (joystick_3     ),
	.status         (status         ),
`ifdef USE_HDMI
	.i2c_start      (i2c_start      ),
	.i2c_read       (i2c_read       ),
	.i2c_addr       (i2c_addr       ),
	.i2c_subaddr    (i2c_subaddr    ),
	.i2c_dout       (i2c_dout       ),
	.i2c_din        (i2c_din        ),
	.i2c_ack        (i2c_ack        ),
	.i2c_end        (i2c_end        ),
`endif
	.scandoubler_disable (scandoublerD	  ),
	.ypbpr          (ypbpr          ),
	.no_csync       (no_csync       )
	);

wire        ioctl_downl;
wire        ioctl_upl;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;
wire  [7:0] ioctl_din;

data_io #(.ROM_DIRECT_UPLOAD(DIRECT_UPLOAD)) data_io(
	.clk_sys       ( clk_sys      ),
	.SPI_SCK       ( SPI_SCK      ),
	.SPI_SS2       ( SPI_SS2      ),
	.SPI_SS4       ( SPI_SS4      ),
	.SPI_DI        ( SPI_DI       ),
	.SPI_DO        ( SPI_DO       ),
	.clkref_n      ( 1'b0         ),
	.ioctl_download( ioctl_downl  ),
	.ioctl_upload  ( ioctl_upl    ),
	.ioctl_index   ( ioctl_index  ),
	.ioctl_wr      ( ioctl_wr     ),
	.ioctl_addr    ( ioctl_addr   ),
	.ioctl_dout    ( ioctl_dout   ),
	.ioctl_din     ( ioctl_din    )
);

// reset signal generation
reg reset = 1;
reg rom_loaded = 0;
always @(posedge clk_sys) begin
	reg ioctl_downlD;
	ioctl_downlD <= ioctl_downl;

	reset <= 0;
	if (ioctl_downl | status[0] | buttons[1] | ~rom_loaded) reset <= 1;

	if (ioctl_downlD & ~ioctl_downl) rom_loaded <= 1;
end

wire [23:0] cpu1_rom_addr;
wire        cpu1_rom_cs;
wire [15:0] cpu1_rom_q;
wire        cpu1_rom_valid;

wire [23:0] cpu2_rom_addr;
wire        cpu2_rom_cs;
wire [15:0] cpu2_rom_q;
wire        cpu2_rom_valid;

wire [23:0] sdr_audio_addr;
wire [15:0] sdr_audio_q;
wire        sdr_audio_req;
wire        sdr_audio_ack;

wire [63:0] sdr_sprite1_dout;
wire [23:0] sdr_sprite1_addr;
wire sdr_sprite1_req, sdr_sprite1_ack;

wire [63:0] sdr_scn_dout;
wire [23:0] sdr_scn_addr;
wire sdr_scn_req, sdr_scn_ack, sdr_scn_32_ack;
    
wire [31:0] sdr_bg_data_a;
wire [23:0] sdr_bg_addr_a;
wire sdr_bg_req_a, sdr_bg_ack_a;

wire [31:0] sdr_bg_data_b;
wire [23:0] sdr_bg_addr_b;
wire sdr_bg_req_b, sdr_bg_ack_b;

wire [31:0] sdr_bg_data_c;
wire [23:0] sdr_bg_addr_c;
wire sdr_bg_req_c, sdr_bg_ack_c;

wire [31:0] sdr_bg_data_d;
wire [23:0] sdr_bg_addr_d;
wire sdr_bg_req_d, sdr_bg_ack_d;

wire [24:0] sdr_rom_addr;
wire [15:0] sdr_rom_data;
wire  [1:0] sdr_rom_be;
wire        sdr_rom_ch1_req;
wire        sdr_rom_ch1_ack;
wire        sdr_rom_ch2_req;
wire        sdr_rom_ch2_ack;

wire [24:0] sample_rom_addr;
wire [63:0] sample_rom_dout;
wire        sample_rom_req;
wire        sample_rom_ack;

wire sdr_rom_write = ioctl_downl && (ioctl_index == 0);

board_cfg_t board_cfg;
sdram_4w_cl3 #(106) sdram
(
  .*,
  .init_n        ( pll_locked    ),
  .clk           ( clk_sdr       ),
  .refresh_en    ( HSync | VBlank ),

  // Bank 0-1 ops
  .port1_a       ( sdr_rom_addr[23:1] ),
  .port1_req     ( sdr_rom_ch1_req ),
  .port1_ack     ( sdr_rom_ch1_ack ),
  .port1_we      ( sdr_rom_write ),
  .port1_ds      ( sdr_rom_be    ),
  .port1_d       ( sdr_rom_data  ),
  .port1_q       (               ),

  // Main CPU
  .cpu1_rom_addr ( cpu1_rom_addr[23:1] ),
  .cpu1_rom_cs   ( cpu1_rom_cs ),
  .cpu1_rom_q    ( cpu1_rom_q ),
  .cpu1_rom_valid( cpu1_rom_valid ),

  // Audio CPU
  .cpu2_rom_addr ( cpu2_rom_addr[23:1] ),
  .cpu2_rom_cs   ( cpu2_rom_cs ),
  .cpu2_rom_q    ( cpu2_rom_q ),
  .cpu2_rom_valid( cpu2_rom_valid ),

  // ADPCM
  .audio_addr    ( sdr_audio_addr[23:1]),
  .audio_q       ( sdr_audio_q         ),
  .audio_req     ( sdr_audio_req       ),
  .audio_ack     ( sdr_audio_ack       ),

  // GFX1
  .gfx1_addr     ( sdr_bg_addr_a[23:1] ),
  .gfx1_req      ( sdr_bg_req_a    ),
  .gfx1_ack      ( sdr_bg_ack_a    ),
  .gfx1_q        ( sdr_bg_data_a   ),

  // Bank 2-3 ops
  .port2_a       ( sdr_rom_addr[23:1] ),
  .port2_req     ( sdr_rom_ch2_req    ),
  .port2_ack     ( sdr_rom_ch2_ack    ),
  .port2_we      ( sdr_rom_write   ),
  .port2_ds      ( sdr_rom_be      ),
  .port2_d       ( sdr_rom_data    ),
  .port2_q       (                 ),
  
  .sp1_addr      ( sdr_scn_addr[23:1] ),
  .sp1_req       ( sdr_scn_req  ),
  .sp1_ack       ( sdr_scn_ack  ),
  .sp1_32_ack    ( sdr_scn_32_ack ),
  .sp1_q         ( sdr_scn_dout )
);

ddr_if ddr_host(), ddr_romload(), ddr_f2();

ddr_mux ddr_mux(
    .clk(clk_sys),
    .x(ddr_host),
    .a(ddr_f2),
    .b(ddr_romload)
);

sdram_ddremu #(106) sdram2
(
	.clk            ( clk_sys          ),
	.sdr_clk        ( clk_sdr2         ),
	.init_n         ( pll2_locked      ),
	.SDRAM_A        ( SDRAM2_A         ),
	.SDRAM_DQ       ( SDRAM2_DQ        ),
	.SDRAM_DQML     ( SDRAM2_DQML      ),
	.SDRAM_DQMH     ( SDRAM2_DQMH      ),
	.SDRAM_nWE      ( SDRAM2_nWE       ),
	.SDRAM_nCAS     ( SDRAM2_nCAS      ),
	.SDRAM_nRAS     ( SDRAM2_nRAS      ),
	.SDRAM_nCS      ( SDRAM2_nCS       ),
	.SDRAM_BA       ( SDRAM2_BA        ),

	.addr           ( ddr_host.addr    ),
	.wdata          ( ddr_host.wdata   ),
	.rdata          ( ddr_host.rdata   ),
	.read           ( ddr_host.read    ),
	.write          ( ddr_host.write   ),
	.burstcnt       ( ddr_host.burstcnt),
	.byteenable     ( ddr_host.byteenable),
	.busy           ( ddr_host.busy    ),
	.rdata_ready    ( ddr_host.rdata_ready)
);

rom_loader rom_loader(
    .sys_clk(clk_sys),
    .ram_clk(clk_sdr),

    .ioctl_downl(ioctl_downl),
    .ioctl_wr(ioctl_wr && !ioctl_index),
    .ioctl_data(ioctl_dout[7:0]),

    .ioctl_wait(),

    .sdr_addr(sdr_rom_addr),
    .sdr_data(sdr_rom_data),
    .sdr_be(sdr_rom_be),
    .sdr_ch1_req(sdr_rom_ch1_req),
    .sdr_ch1_ack(sdr_rom_ch1_ack),
    .sdr_ch2_req(sdr_rom_ch2_req),
    .sdr_ch2_ack(sdr_rom_ch2_ack),

    .ddr(ddr_romload),

    .board_cfg(board_cfg)
);

wire [15:0] audio;
wire [7:0] R, G, B;
wire HBlank, VBlank, HSync, VSync;
wire ce_pix;
wire flipped;

wire [3:0] coin;
coin_pulse cp0(.clk(clk_sys), .vblank(VBlank), .button(m_coin1), .pulse(coin[0]));
coin_pulse cp1(.clk(clk_sys), .vblank(VBlank), .button(m_coin2), .pulse(coin[1]));
coin_pulse cp2(.clk(clk_sys), .vblank(VBlank), .button(m_coin3), .pulse(coin[2]));
coin_pulse cp3(.clk(clk_sys), .vblank(VBlank), .button(m_coin4), .pulse(coin[3]));

F2 F2(
    .clk(clk_sys),
    .ce_pixel(ce_pix),
//    .flipped(flipped),
    .reset(reset),
    .hblank(HBlank),
    .vblank(VBlank),
    .hsync(HSync),
    .vsync(VSync),
    .red(R),
    .green(G),
    .blue(B),
    .audio_out(audio),

    .game(board_cfg.game),

    .coin(coin),

    .start({m_four_players, m_three_players, m_two_players, m_one_player}),

    .joystick_p1({m_fire1[5:0], m_up1, m_down1, m_left1, m_right1}),
    .joystick_p2({m_fire2[5:0], m_up2, m_down2, m_left2, m_right2}),
    .joystick_p3({m_fire3[5:0], m_up3, m_down3, m_left3, m_right3}),
    .joystick_p4({m_fire4[5:0], m_up4, m_down4, m_left4, m_right4}),

    .analog_abs(1'b1),
    .analog_p1(8'h80),
    .analog_p2(8'h80),

    .dswa(dswa),
    .dswb(dswb),

    .cpu1_rom_addr(cpu1_rom_addr),
    .cpu1_rom_cs(cpu1_rom_cs),
    .cpu1_rom_q(cpu1_rom_q),
    .cpu1_rom_valid(cpu1_rom_valid),

    .cpu2_rom_addr(cpu2_rom_addr),
    .cpu2_rom_cs(cpu2_rom_cs),
    .cpu2_rom_q(cpu2_rom_q),
    .cpu2_rom_valid(cpu2_rom_valid),

    .sdr_scn0_addr(sdr_bg_addr_a),
    .sdr_scn0_q(sdr_bg_data_a),
    .sdr_scn0_req(sdr_bg_req_a),
    .sdr_scn0_ack(sdr_bg_ack_a),

    .sdr_scn_mux_addr(sdr_scn_addr),
    .sdr_scn_mux_q(sdr_scn_dout),
    .sdr_scn_mux_req(sdr_scn_req),
    .sdr_scn_mux_ack(sdr_scn_ack),
    .sdr_scn_32_ack(sdr_scn_32_ack),

    .sdr_audio_addr(sdr_audio_addr),
    .sdr_audio_q(sdr_audio_q),
    .sdr_audio_req(sdr_audio_req),
    .sdr_audio_ack(sdr_audio_ack),

    .ddr(ddr_f2),
    .sync_fix(1'b1),
    .pause(system_pause),
    .audio_filter_en(filters)
);

mist_dual_video #(.COLOR_DEPTH(8), .SD_HCNT_WIDTH(10), .USE_BLANKS(1), .OUT_COLOR_DEPTH(VGA_BITS), .BIG_OSD(BIG_OSD)) mist_video(
	.clk_sys        ( clk_sys          ),
	.SPI_SCK        ( SPI_SCK          ),
	.SPI_SS3        ( SPI_SS3          ),
	.SPI_DI         ( SPI_DI           ),
	.R              ( R                ),
	.G              ( G                ),
	.B              ( B                ),
	.HBlank         ( HBlank           ),
	.VBlank         ( VBlank           ),
	.HSync          ( HSync            ),
	.VSync          ( VSync            ),
	.VGA_R          ( VGA_R            ),
	.VGA_G          ( VGA_G            ),
	.VGA_B          ( VGA_B            ),
	.VGA_VS         ( VGA_VS           ),
	.VGA_HS         ( VGA_HS           ),
`ifdef USE_HDMI
	.HDMI_R         ( HDMI_R           ),
	.HDMI_G         ( HDMI_G           ),
	.HDMI_B         ( HDMI_B           ),
	.HDMI_VS        ( HDMI_VS          ),
	.HDMI_HS        ( HDMI_HS          ),
	.HDMI_DE        ( HDMI_DE          ),
`endif
	.rotate         ( { orientation[1], rotate } ),
	.ce_divider     ( 4'd7             ),
	.scandoubler_disable( scandoublerD ),
	.scanlines      ( scanlines        ),
	.blend          ( blend            ),
	.ypbpr          ( ypbpr            ),
	.no_csync       ( no_csync         )
	);

dac #(
	.C_bits(16))
dacl(
	.clk_i(clk_sys),
	.res_n_i(1),
	.dac_i({~audio[15], audio[14:0]}),
	.dac_o(AUDIO_L)
	);

dac #(
	.C_bits(16))
dacr(
	.clk_i(clk_sys),
	.res_n_i(1),
	.dac_i({~audio[15], audio[14:0]}),
	.dac_o(AUDIO_R)
	);
	
`ifdef I2S_AUDIO
i2s i2s (
	.reset(1'b0),
	.clk(clk_sys),
	.clk_rate(32'd53_370_000),
	.sclk(I2S_BCK),
	.lrclk(I2S_LRCK),
	.sdata(I2S_DATA),
	.left_chan(audio),
	.right_chan(audio)
);
`ifdef I2S_AUDIO_HDMI
assign HDMI_MCLK = 0;
always @(posedge clk_sys) begin
	HDMI_BCK <= I2S_BCK;
	HDMI_LRCK <= I2S_LRCK;
	HDMI_SDATA <= I2S_DATA;
end
`endif
`endif

`ifdef SPDIF_AUDIO
spdif spdif (
	.rst_i(1'b0),
	.clk_i(clk_sys),
	.clk_rate_i(32'd53_370_000),
	.spdif_o(SPDIF),
	.sample_i({2{audio}})
);
`endif

`ifdef USE_HDMI
i2c_master #(53_370_000) i2c_master (
	.CLK         (clk_sys),
	.I2C_START   (i2c_start),
	.I2C_READ    (i2c_read),
	.I2C_ADDR    (i2c_addr),
	.I2C_SUBADDR (i2c_subaddr),
	.I2C_WDATA   (i2c_dout),
	.I2C_RDATA   (i2c_din),
	.I2C_END     (i2c_end),
	.I2C_ACK     (i2c_ack),

	//I2C bus
	.I2C_SCL     (HDMI_SCL),
	.I2C_SDA     (HDMI_SDA)
);

assign HDMI_PCLK = clk_sys;

`endif

wire m_up1, m_down1, m_left1, m_right1, m_up1B, m_down1B, m_left1B, m_right1B;
wire m_up2, m_down2, m_left2, m_right2, m_up2B, m_down2B, m_left2B, m_right2B;
wire m_up3, m_down3, m_left3, m_right3, m_up3B, m_down3B, m_left3B, m_right3B;
wire m_up4, m_down4, m_left4, m_right4, m_up4B, m_down4B, m_left4B, m_right4B;
wire m_tilt, m_coin1, m_coin2, m_coin3, m_coin4, m_one_player, m_two_players, m_three_players, m_four_players;
wire [11:0] m_fire1, m_fire2, m_fire3, m_fire4;

arcade_inputs #(.START1(10), .START2(12), .COIN1(11)) inputs (
	.clk         ( clk_sys     ),
	.key_strobe  ( key_strobe  ),
	.key_pressed ( key_pressed ),
	.key_code    ( key_code    ),
	.joystick_0  ( joystick_0  ),
	.joystick_1  ( joystick_1  ),
	.joystick_2  ( joystick_2  ),
	.joystick_3  ( joystick_3  ),
	.rotate      ( rotate      ),
	.orientation ( orientation ),
	.joyswap     ( joyswap     ),
	.oneplayer   ( oneplayer   ),
	.controls    ( {m_tilt, m_coin4, m_coin3, m_coin2, m_coin1, m_four_players, m_three_players, m_two_players, m_one_player} ),
	.player1     ( {m_up1B, m_down1B, m_left1B, m_right1B, m_fire1, m_up1, m_down1, m_left1, m_right1} ),
	.player2     ( {m_up2B, m_down2B, m_left2B, m_right2B, m_fire2, m_up2, m_down2, m_left2, m_right2} ),
	.player3     ( {m_up3B, m_down3B, m_left3B, m_right3B, m_fire3, m_up3, m_down3, m_left3, m_right3} ),
	.player4     ( {m_up4B, m_down4B, m_left4B, m_right4B, m_fire4, m_up4, m_down4, m_left4, m_right4} )
);

endmodule 
